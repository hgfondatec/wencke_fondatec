import ctypes
import datetime
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine, text


DBT_PROJECT_PATH = Path(r"C:\dbt\wencke_fondatec")
LOG_FILE = DBT_PROJECT_PATH / "dbt_logs.log"

# Verhindert mehrere gleichzeitig laufende Skriptinstanzen.
MUTEX_NAME = r"Global\wencke_fondatec_dbt_scheduler"
ERROR_ALREADY_EXISTS = 183


# ---------------------------------------------------------
# PostgreSQL-Verbindung
# ---------------------------------------------------------

PG_USER = "sbs"
PG_PASSWORD = "qaqpav-xyxhi9-jeGmyv"
PG_HOST = "172.30.30.5"
PG_PORT = 5432
PG_DATABASE = "wenke"


# Wichtig, falls das Passwort Sonderzeichen wie @, :, / oder # enthält.
PG_PASSWORD_ENCODED = quote_plus(PG_PASSWORD)

DATABASE_URI = (
    f"postgresql+psycopg2://{PG_USER}:{PG_PASSWORD_ENCODED}"
    f"@{PG_HOST}:{PG_PORT}/{PG_DATABASE}"
)

REPORT_TABLE = "dbt_run_log"


# ---------------------------------------------------------
# JOB-DEFINITIONEN
# ---------------------------------------------------------

JOBS = {
    "checks": {
        "stop_on_error": False,
        "commands": [
            ("run", "+wencke_gold_nebenwarengruppe_check"),
            ("run", "+wencke_gold_hauptwarengruppe_check"),
            ("snapshot", "snapshot_hw_check"),
            ("snapshot", "snapshot_nw_check"),  
        ],
    },

    "artikel": {
        "stop_on_error": True,
        "commands": [
            ("run", "+wencke_gold_artikel"),
            ("run", "+gold_wencke_artikel"),
            ("run", "+gold_wencke_artikel_lieferant"),
            ("run", "+gold_wencke_artikel_check"),
            ("snapshot", "snapshot_artikel_check"),
        ],
    },

    "facts": {
        "stop_on_error": True,
        "commands": [
            ("run", "+gold_wencke_facts_belege_positionen"),
            ("run", "+gold_wencke_facts_belege_positionen_reklamation"),
        ],
    },

    "adressen": {
        "stop_on_error": True,
        "commands": [
            ("run", "+gold_wencke_adressen"),
            ("snapshot", "snapshot_gold_adressen"),
            ("run", "+gold_wencke_adressen_changes"),
            ("run", "+gold_wencke_vertreter"),
            ("run", "+gold_wencke_bediener"),
        ],
    },

    "artikel_bestand": {
            "stop_on_error": True,
            "commands": [
                ("run", "+wencke_gold_facts_artikel_bestand"),
        ],
    },



    
}


# ---------------------------------------------------------
# SINGLE INSTANCE MUTEX
# ---------------------------------------------------------

def acquire_single_instance_mutex():
    """
    Verhindert, dass das Skript gleichzeitig mehrfach ausgeführt wird.

    Der Mutex bleibt so lange aktiv,
    wie der aktuelle Python-Prozess läuft.
    """

    mutex_handle = ctypes.windll.kernel32.CreateMutexW(
        None,
        False,
        MUTEX_NAME,
    )

    if not mutex_handle:
        raise ctypes.WinError()

    if (
        ctypes.windll.kernel32.GetLastError()
        == ERROR_ALREADY_EXISTS
    ):
        ctypes.windll.kernel32.CloseHandle(mutex_handle)
        return None

    return mutex_handle


# ---------------------------------------------------------
# LOKALES LOG
# ---------------------------------------------------------

def write_local_log(message):
    """
    Schreibt eine Nachricht in die eigene Scheduler-Logdatei.
    """

    try:
        LOG_FILE.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        with LOG_FILE.open(
            "a",
            encoding="utf-8",
        ) as log_file:
            log_file.write(message)

    except Exception as exc:
        print(
            f"Fehler beim Schreiben "
            f"der lokalen Logdatei: {exc}"
        )


# ---------------------------------------------------------
# POSTGRES SESSION CLEANUP
# ---------------------------------------------------------

def cleanup_postgres_sessions():
    engine = None

    try:
        engine = create_engine(
            DATABASE_URI,
            pool_pre_ping=True,
        )

        with engine.begin() as conn:
            conn.execute(
                text(
                    """
                    SELECT pg_terminate_backend(pid)
                    FROM pg_stat_activity
                    WHERE datname = current_database()
                      AND pid <> pg_backend_pid()
                      AND usename = current_user
                      AND state IN (
                          'idle',
                          'idle in transaction'
                      );
                    """
                )
            )

        print(
            "Alte PostgreSQL-Sessions bereinigt."
        )

    except Exception as exc:
        print(
            f"Fehler beim Bereinigen "
            f"der Sessions: {exc}"
        )

        write_local_log(
            f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} "
            f"FEHLER beim Bereinigen "
            f"der Sessions: {exc}\n"
        )

    finally:
        if engine is not None:
            engine.dispose()


# ---------------------------------------------------------
# DBT RUN IN POSTGRES LOGGEN
# ---------------------------------------------------------

def write_to_postgres(
    timestamp,
    model,
    status,
    duration,
    message,
):
    engine = None

    try:
        engine = create_engine(
            DATABASE_URI,
            pool_pre_ping=True,
            connect_args={
                "options": (
                    "-c statement_timeout=30000 "
                    "-c lock_timeout=10000"
                )
            },
        )

        df = pd.DataFrame(
            [
                {
                    "run_timestamp": timestamp,
                    "model_name": model,
                    "status": status,
                    "duration_seconds": duration,
                    "message": message[:5000],
                }
            ]
        )

        df.to_sql(
            REPORT_TABLE,
            engine,
            schema="quality",
            if_exists="append",
            index=False,
        )

        print(
            f"Run in PostgreSQL eingetragen: "
            f"{model} - {status}"
        )

    except Exception as exc:
        print(
            f"Fehler beim Schreiben "
            f"in PostgreSQL: {exc}"
        )

        write_local_log(
            f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} "
            f"FEHLER beim Schreiben "
            f"in PostgreSQL: {exc}\n"
        )

    finally:
        if engine is not None:
            engine.dispose()


# ---------------------------------------------------------
# EINEN DBT COMMAND AUSFÜHREN
# ---------------------------------------------------------

def run_dbt_command(
    command_type,
    selector,
):
    cleanup_postgres_sessions()

    timestamp = datetime.datetime.now()

    status = "FEHLER"
    duration = 0
    message = ""

    command = [
        "uv",
        "run",
        "dbt",

        # Verhindert Zugriff auf logs\dbt.log
        "--log-level-file",
        "none",

        command_type,
        "--select",
        selector,
    ]

    print()
    print("=" * 80)
    print(
        f"Starte: {' '.join(command)}"
    )
    print("=" * 80)

    try:
        start_time = datetime.datetime.now()

        result = subprocess.run(
            command,
            cwd=str(DBT_PROJECT_PATH),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            errors="replace",
            shell=False,
            timeout=3600,
        )

        duration = (
            datetime.datetime.now()
            - start_time
        ).total_seconds()

        if result.returncode == 0:
            status = "ERFOLGREICH"
        else:
            status = "FEHLER"

        message = result.stdout or ""

        # Ausgabe zusätzlich im Terminal anzeigen
        print(message)

        # Für PostgreSQL / Logdatei kompakter machen
        message = message.replace(
            "\n",
            " | ",
        )

    except subprocess.TimeoutExpired as exc:
        status = "FEHLER"
        duration = 3600

        message = (
            f"DBT Timeout nach 60 Minuten: {exc}"
        )

        print(message)

    except Exception as exc:
        status = "FEHLER"
        message = str(exc)

        print(
            f"DBT Fehler: {message}"
        )

    write_local_log(
        f"\n"
        f"--- DBT {command_type.upper()} "
        f"{selector} {timestamp} ---\n"
        f"{message}\n"
        f"Status: {status}, "
        f"Dauer: {duration:.2f} Sekunden\n"
    )

    write_to_postgres(
        timestamp=timestamp,
        model=f"{command_type}:{selector}",
        status=status,
        duration=duration,
        message=message,
    )

    return status == "ERFOLGREICH"


# ---------------------------------------------------------
# JOB AUSFÜHREN
# ---------------------------------------------------------

def run_job(job_name):
    if job_name not in JOBS:
        print()
        print(
            f"Unbekannter Job: {job_name}"
        )
        print()
        print(
            "Verfügbare Jobs:"
        )

        for available_job in JOBS:
            print(
                f" - {available_job}"
            )

        return 1

    job = JOBS[job_name]

    commands = job["commands"]
    stop_on_error = job["stop_on_error"]

    job_start = datetime.datetime.now()

    print()
    print("#" * 80)
    print(
        f"STARTE JOB: {job_name.upper()}"
    )
    print(
        f"Startzeit: "
        f"{job_start:%Y-%m-%d %H:%M:%S}"
    )
    print(
        f"Anzahl Commands: {len(commands)}"
    )
    print(
        f"Stop on Error: {stop_on_error}"
    )
    print("#" * 80)

    write_local_log(
        f"\n"
        f"{'#' * 80}\n"
        f"START JOB: {job_name.upper()}\n"
        f"Startzeit: "
        f"{job_start:%Y-%m-%d %H:%M:%S}\n"
        f"{'#' * 80}\n"
    )

    has_errors = False

    for command_type, selector in commands:

        successful = run_dbt_command(
            command_type,
            selector,
        )

        if not successful:
            has_errors = True

            print()
            print(
                f"FEHLER bei: "
                f"{command_type} {selector}"
            )

            if stop_on_error:
                print(
                    "Job wird wegen "
                    "stop_on_error beendet."
                )

                write_local_log(
                    f"JOB {job_name.upper()} "
                    f"ABGEBROCHEN bei "
                    f"{command_type}:{selector}\n"
                )

                break

    job_end = datetime.datetime.now()

    job_duration = (
        job_end - job_start
    ).total_seconds()

    if has_errors:
        final_status = "FEHLER"
    else:
        final_status = "ERFOLGREICH"

    print()
    print("#" * 80)
    print(
        f"JOB BEENDET: "
        f"{job_name.upper()}"
    )
    print(
        f"Status: {final_status}"
    )
    print(
        f"Dauer: {job_duration:.2f} Sekunden"
    )
    print("#" * 80)

    write_local_log(
        f"\n"
        f"{'#' * 80}\n"
        f"ENDE JOB: {job_name.upper()}\n"
        f"Status: {final_status}\n"
        f"Dauer: {job_duration:.2f} Sekunden\n"
        f"{'#' * 80}\n"
    )

    return 1 if has_errors else 0


# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print()
        print(
            "Kein Job angegeben."
        )
        print()
        print(
            "Beispiel:"
        )
        print(
            "uv run python scheduler.py checks"
        )
        print()
        print(
            "Verfügbare Jobs:"
        )

        for job_name in JOBS:
            print(
                f" - {job_name}"
            )

        return 1

    job_name = (
        sys.argv[1]
        .strip()
        .lower()
    )

    return run_job(job_name)


# ---------------------------------------------------------
# PROGRAMMSTART
# ---------------------------------------------------------

if __name__ == "__main__":

    mutex_handle = (
        acquire_single_instance_mutex()
    )

    if mutex_handle is None:

        job_name = (
            sys.argv[1]
            if len(sys.argv) >= 2
            else "unbekannt"
        )

        message = (
            f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} "
            f"Job '{job_name}' nicht gestartet: "
            f"Eine andere Instanz läuft bereits.\n"
        )

        print(
            message.strip()
        )

        write_local_log(
            message
        )

        sys.exit(0)

    try:
        sys.exit(
            main()
        )

    finally:
        ctypes.windll.kernel32.CloseHandle(
            mutex_handle
        )