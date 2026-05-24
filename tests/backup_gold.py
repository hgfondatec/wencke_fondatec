import datetime
import pandas as pd
from sqlalchemy import create_engine, text

# ------------------ KONFIGURATION ------------------

PG_USER = "sbs"
PG_PASSWORD = "qaqpav-xyxhi9-jeGmyv"
PG_HOST = "172.30.30.5"
PG_PORT = 5432
PG_DATABASE = "wenke"

DATABASE_URI = f"postgresql+psycopg2://{PG_USER}:{PG_PASSWORD}@{PG_HOST}:{PG_PORT}/{PG_DATABASE}"

REPORT_TABLE = "dbt_run_log"

SOURCE_SCHEMA = "reporting"
BACKUP_SCHEMA = "backup"

TABLES = [
    "gold_facts",
    "gold_artikel",
    "gold_adress"
]

# ---------------------------------------------------

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

        print(f"Log geschrieben: {model} - {status}")

    except Exception as e:
        print(f"Fehler beim Schreiben ins Log: {e}")

def backup_tables():

    engine = create_engine(DATABASE_URI)

    backup_date = datetime.datetime.now().strftime("%Y%m%d_%H%M")

    with engine.begin() as conn:

        conn.execute(text(f"""
            create schema if not exists {BACKUP_SCHEMA}
        """))

        for table in TABLES:

            timestamp = datetime.datetime.now()

            status = "ERFOLGREICH"
            duration = 0
            message = ""

            try:
                start_time = datetime.datetime.now()

                backup_table = f"{table}_{backup_date}"

                sql = f"""
                create table {BACKUP_SCHEMA}.{backup_table} as
                select *
                from {SOURCE_SCHEMA}.{table}
                """

                conn.execute(text(sql))

                end_time = datetime.datetime.now()

                duration = (end_time - start_time).total_seconds()

                message = f"Backup erstellt: {BACKUP_SCHEMA}.{backup_table}"

                print(message)

            except Exception as e:

                status = "FEHLER"
                message = str(e)

            write_to_postgres(
                timestamp,
                f"BACKUP_{table}",
                status,
                duration,
                message
            )

if __name__ == "__main__":
    backup_tables()