import subprocess
import datetime
import pandas as pd
from sqlalchemy import create_engine

DBT_PROJECT_PATH = r"C:\dbt\wencke_fondatec"
LOG_FILE = r"C:\dbt\wencke_fondatec\dbt_logs.log"

# PostgreSQL-Verbindung
PG_USER = "sbs"
PG_PASSWORD = "qaqpav-xyxhi9-jeGmyv"
PG_HOST = "172.30.30.5"
PG_PORT = 5432
PG_DATABASE = "wenke"

DATABASE_URI = (
    f"postgresql+psycopg2://{PG_USER}:{PG_PASSWORD}"
    f"@{PG_HOST}:{PG_PORT}/{PG_DATABASE}"
)

REPORT_TABLE = "dbt_run_log"


def write_to_postgres(timestamp, model, status, duration, message):
    try:
        engine = create_engine(DATABASE_URI)

        df = pd.DataFrame([{
            "run_timestamp": timestamp,
            "model_name": model,
            "status": status,
            "duration_seconds": duration,
            "message": message
        }])

        df.to_sql(
            REPORT_TABLE,
            engine,
            schema='quality',
            if_exists='append',
            index=False
        )

        print(f"Run in PostgreSQL eingetragen: {model} - {status}")

    except Exception as e:

        print(f"Fehler beim Schreiben in PostgreSQL: {e}")

        with open(LOG_FILE, "a", encoding="utf-8") as log_file:
            log_file.write(
                f"FEHLER beim Schreiben in PostgreSQL: {e}\n"
            )


def run_dbt_command(command_type, selector):

    timestamp = datetime.datetime.now()

    status = "FEHLER"
    duration = 0
    message = ""

    try:

        start_time = datetime.datetime.now()

        result = subprocess.run(
            [
                "uv",
                "run",
                "dbt",
                command_type,
                "--select",
                selector
            ],
            cwd=DBT_PROJECT_PATH,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            shell=True
        )

        end_time = datetime.datetime.now()

        duration = (
            end_time - start_time
        ).total_seconds()

        status = (
            "ERFOLGREICH"
            if result.returncode == 0
            else "FEHLER"
        )

        message = result.stdout.replace("\n", " | ")

    except Exception as e:

        message = str(e)

    # Lokales Logfile

    with open(LOG_FILE, "a", encoding="utf-8") as log_file:

        log_file.write(
            f"\n--- DBT {command_type.upper()} "
            f"{selector} {timestamp} ---\n"
        )

        log_file.write(message + "\n")

        log_file.write(
            f"Status: {status}, "
            f"Dauer: {duration} Sekunden\n"
        )

    # PostgreSQL Logging

    write_to_postgres(
        timestamp=timestamp,
        model=f"{command_type}:{selector}",
        status=status,
        duration=duration,
        message=message
    )


if __name__ == "__main__":

    # GOLD FACTS bauen
    run_dbt_command(
        "run",
        "tag:gold_facts"
    )

    # FACT SNAPSHOT erstellen
    run_dbt_command(
        "snapshot",
        "snapshot_gold_facts"
    )

    # GOLD ADRESS bauen
    run_dbt_command(
        "run",
        "tag:gold_adress"
    )

    # GOLD ARTIKEL bauen
    run_dbt_command(
        "run",
        "tag:gold_artikel"
    )