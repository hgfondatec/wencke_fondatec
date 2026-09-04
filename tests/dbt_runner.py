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

# PostgreSQL-Verbindung
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


def acquire_single_instance_mutex():
    """
    Verhindert, dass das Skript gleichzeitig mehrfach ausgeführt wird.

    Der Mutex bleibt so lange aktiv, wie der aktuelle Python-Prozess läuft.
    """
    mutex_handle = ctypes.windll.kernel32.CreateMutexW(
        None,
        False,
        MUTEX_NAME
    )

    if not mutex_handle:
        raise ctypes.WinError()

    if ctypes.windll.kernel32.GetLastError() == ERROR_ALREADY_EXISTS:
        ctypes.windll.kernel32.CloseHandle(mutex_handle)
        return None

    return mutex_handle


def write_local_log(message):
    """
    Schreibt eine Nachricht in die eigene Scheduler-Logdatei.
    """
    try:
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

        with LOG_FILE.open("a", encoding="utf-8") as log_file:
            log_file.write(message)

    except Exception as exc:
        print(f"Fehler beim Schreiben der lokalen Logdatei: {exc}")


def cleanup_postgres_sessions():
    engine = None

    try:
        engine = create_engine(
            DATABASE_URI,
            pool_pre_ping=True
        )

        with engine.begin() as conn:
            conn.execute(text("""
                SELECT pg_terminate_backend(pid)
                FROM pg_stat_activity
                WHERE datname = current_database()
                  AND pid <> pg_backend_pid()
                  AND usename = current_user
                  AND state IN ('idle', 'idle in transaction');
            """))

        print("Alte PostgreSQL-Sessions bereinigt.")

    except Exception as exc:
        print(f"Fehler beim Bereinigen der Sessions: {exc}")

        write_local_log(
            f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} "
            f"FEHLER beim Bereinigen der Sessions: {exc}\n"
        )

    finally:
        if engine is not None:
            engine.dispose()


def write_to_postgres(
    timestamp,
    model,
    status,
    duration,
    message
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
            }
        )

        df = pd.DataFrame([{
            "run_timestamp": timestamp,
            "model_name": model,
            "status": status,
            "duration_seconds": duration,
            "message": message[:5000]
        }])

        df.to_sql(
            REPORT_TABLE,
            engine,
            schema="quality",
            if_exists="append",
            index=False
        )

        print(f"Run in PostgreSQL eingetragen: {model} - {status}")

    except Exception as exc:
        print(f"Fehler beim Schreiben in PostgreSQL: {exc}")

        write_local_log(
            f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} "
            f"FEHLER beim Schreiben in PostgreSQL: {exc}\n"
        )

    finally:
        if engine is not None:
            engine.dispose()


def run_dbt_command(command_type, selector):
    cleanup_postgres_sessions()

    timestamp = datetime.datetime.now()
    status = "FEHLER"
    duration = 0
    message = ""

    command = [
        "uv",
        "run",
        "dbt",

        # Muss vor dem dbt-Unterbefehl run/snapshot stehen.
        # Verhindert den Zugriff auf logs\dbt.log.
        "--log-level-file",
        "none",

        command_type,
        "--select",
        selector
    ]

    print(f"Starte: {' '.join(command)}")

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
            timeout=3600
        )

        duration = (
            datetime.datetime.now() - start_time
        ).total_seconds()

        status = (
            "ERFOLGREICH"
            if result.returncode == 0
            else "FEHLER"
        )

        message = result.stdout or ""
        message = message.replace("\n", " | ")

    except subprocess.TimeoutExpired as exc:
        status = "FEHLER"
        duration = 3600
        message = f"DBT Timeout nach 60 Minuten: {exc}"

    except Exception as exc:
        status = "FEHLER"
        message = str(exc)

    write_local_log(
        f"\n--- DBT {command_type.upper()} "
        f"{selector} {timestamp} ---\n"
        f"{message}\n"
        f"Status: {status}, Dauer: {duration} Sekunden\n"
    )

    write_to_postgres(
        timestamp=timestamp,
        model=f"{command_type}:{selector}",
        status=status,
        duration=duration,
        message=message
    )

    return status == "ERFOLGREICH"


def main():
    commands = [
        #("run", "tag:gold_facts"),
        #("snapshot", "snapshot_gold_facts"),
        #("run", "tag:gold_adress"),
        #("run", "tag:gold_artikel"),
        ("run", "+wencke_gold_nebenwarengruppe_check"),
        ("run", "+wencke_gold_hauptwarengruppe_check"),
        ("run", "+wencke_gold_artikel_check"),
        ("snapshot", "snapshot_hw_check"),
        ("snapshot", "snapshot_nw_check"),
        ("snapshot", "snapshot_artikel_check"),
        #("run", "+wencke_gold_rekla_facts"),
        ("run", "+wencke_gold_artikel"),
        ("run", "easymap_customer"),
        ("run", "+gold_wencke_facts_belege_positionen"),
        ("run", "+gold_wencke_facts_belege_positionen_reklamation"),
        ("run", "+gold_wencke_adressen"),
        ("run", "+gold_wencke_artikel_lieferant"),
        ("snapshot", "snapshot_gold_adressen"),
        ("run", "+gold_wencke_artikel"),
        ("run", "+gold_wencke_artikel_check"),
        ("run", "+gold_wencke_adressen_changes")
    ]

    has_errors = False

    for command_type, selector in commands:
        successful = run_dbt_command(
            command_type,
            selector
        )

        if not successful:
            has_errors = True

    return 1 if has_errors else 0


if __name__ == "__main__":
    mutex_handle = acquire_single_instance_mutex()

    if mutex_handle is None:
        message = (
            f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} "
            "Skript nicht gestartet: "
            "Eine andere Instanz läuft bereits.\n"
        )

        print(message.strip())
        write_local_log(message)
        sys.exit(0)

    try:
        sys.exit(main())

    finally:
        ctypes.windll.kernel32.CloseHandle(mutex_handle)