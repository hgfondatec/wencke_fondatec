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
    "nonne_gold_facts",
    "nonne_gold_artikel",
    "nonne_gold_adress"
]

# Wenn leer: kein Restore, nur Cleanup
RESTORE_DATE = ""

# Beispiel für Restore:
# RESTORE_DATE = "20260524_0600"

RETENTION_DAYS = 10

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
            schema="quality",
            if_exists="append",
            index=False
        )

        print(f"Log geschrieben: {model} - {status}")

    except Exception as e:
        print(f"Fehler beim Schreiben ins Log: {e}")


def restore_tables():
    if not RESTORE_DATE:
        print("Kein Restore-Date gesetzt. Restore wird übersprungen.")
        return

    engine = create_engine(DATABASE_URI)

    with engine.begin() as conn:
        for table in TABLES:
            timestamp = datetime.datetime.now()
            start_time = datetime.datetime.now()
            status = "ERFOLGREICH"
            message = ""

            try:
                backup_table = f"{table}_{RESTORE_DATE}"

                conn.execute(text(f"""
                    drop table if exists {SOURCE_SCHEMA}.{table}
                """))

                conn.execute(text(f"""
                    create table {SOURCE_SCHEMA}.{table} as
                    select *
                    from {BACKUP_SCHEMA}.{backup_table}
                """))

                message = f"Restore durchgeführt: {BACKUP_SCHEMA}.{backup_table} -> {SOURCE_SCHEMA}.{table}"
                print(message)

            except Exception as e:
                status = "FEHLER"
                message = str(e)

            end_time = datetime.datetime.now()
            duration = (end_time - start_time).total_seconds()

            write_to_postgres(
                timestamp,
                f"RESTORE_{table}",
                status,
                duration,
                message
            )


def cleanup_old_backups():
    engine = create_engine(DATABASE_URI)

    cutoff_date = datetime.datetime.now() - datetime.timedelta(days=RETENTION_DAYS)

    with engine.begin() as conn:
        for table in TABLES:
            timestamp = datetime.datetime.now()
            start_time = datetime.datetime.now()
            status = "ERFOLGREICH"
            message = ""

            try:
                result = conn.execute(text("""
                    select tablename
                    from pg_tables
                    where schemaname = :backup_schema
                      and tablename like :table_pattern
                """), {
                    "backup_schema": BACKUP_SCHEMA,
                    "table_pattern": f"{table}_%"
                })

                deleted_tables = []

                for row in result:
                    backup_table = row[0]

                    date_part = backup_table.replace(f"{table}_", "")

                    try:
                        backup_datetime = datetime.datetime.strptime(date_part, "%Y%m%d_%H%M")
                    except ValueError:
                        continue

                    if backup_datetime < cutoff_date:
                        conn.execute(text(f"""
                            drop table if exists {BACKUP_SCHEMA}.{backup_table}
                        """))
                        deleted_tables.append(backup_table)

                if deleted_tables:
                    message = "Gelöschte Backups: " + ", ".join(deleted_tables)
                else:
                    message = f"Keine alten Backups für {table} gefunden."

                print(message)

            except Exception as e:
                status = "FEHLER"
                message = str(e)

            end_time = datetime.datetime.now()
            duration = (end_time - start_time).total_seconds()

            write_to_postgres(
                timestamp,
                f"CLEANUP_BACKUP_{table}",
                status,
                duration,
                message
            )


if __name__ == "__main__":
    restore_tables()
    cleanup_old_backups()