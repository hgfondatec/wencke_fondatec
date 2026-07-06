import subprocess
import datetime
import pandas as pd
from sqlalchemy import create_engine, text


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


def cleanup_postgres_sessions():
    engine = None

    try:
        engine = create_engine(DATABASE_URI, pool_pre_ping=True)

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

    except Exception as e:
        print(f"Fehler beim Bereinigen der Sessions: {e}")

        with open(LOG_FILE, "a", encoding="utf-8") as log_file:
            log_file.write(f"FEHLER beim Bereinigen der Sessions: {e}\n")

    finally:
        if engine is not None:
            engine.dispose()


def write_to_postgres(timestamp, model, status, duration, message):
    engine = None

    try:
        engine = create_engine(
            DATABASE_URI,
            pool_pre_ping=True,
            connect_args={
                "options": "-c statement_timeout=30000 -c lock_timeout=10000"
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

    except Exception as e:
        print(f"Fehler beim Schreiben in PostgreSQL: {e}")

        with open(LOG_FILE, "a", encoding="utf-8") as log_file:
            log_file.write(f"FEHLER beim Schreiben in PostgreSQL: {e}\n")

    finally:
        if engine is not None:
            engine.dispose()


def run_dbt_command(command_type, selector):
    cleanup_postgres_sessions()

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
            shell=False,
            timeout=3600
        )

        end_time = datetime.datetime.now()
        duration = (end_time - start_time).total_seconds()

        status = "ERFOLGREICH" if result.returncode == 0 else "FEHLER"
        message = result.stdout.replace("\n", " | ")

    except subprocess.TimeoutExpired as e:
        status = "FEHLER"
        duration = 3600
        message = f"DBT Timeout nach 60 Minuten: {e}"

    except Exception as e:
        status = "FEHLER"
        message = str(e)

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

    write_to_postgres(
        timestamp=timestamp,
        model=f"{command_type}:{selector}",
        status=status,
        duration=duration,
        message=message
    )


if __name__ == "__main__":

    run_dbt_command(
        "run",
        "+wencke_gold_facts_artikel_bestand"
    )