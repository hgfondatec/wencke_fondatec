import datetime
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine


PG_USER = "sbs"
PG_PASSWORD = "qaqpav-xyxhi9-jeGmyv"
PG_HOST = "172.30.30.5"
PG_PORT = 5432
PG_DATABASE = "wenke"

DATABASE_URI = f"postgresql+psycopg2://{PG_USER}:{PG_PASSWORD}@{PG_HOST}:{PG_PORT}/{PG_DATABASE}"

REPORT_SCHEMA = "quality"
REPORT_TABLE = "dbt_run_log"

TEXT_FOLDER = Path(r"Z:")
SEARCH_TEXT = b"ERROR"

FILE_MAPPING = {
    "11": "M36ART - Artikeltabelle",
    "14": "M36ADR - Adresstabelle",
    "16": "M36BEL - Belege",
    "18": "M36ID0203 - Organisationseinheiten",
    "19": "M36ID0222 - OE-Einheiten Stammdaten",
    "20": "M36ID0234 - Reklamationsgründe",
    "21": "M36ID0236 - Reklamationstool Maßnahmen",
    "22": "M36ID0380 - Träger",
    "25": "M36POS - Positionen",
    "26": "M36FAF - WAWI Firmenstamm",
    "28": "M00ID0624 - Adresse Auswahl E-Commerce",
    "29": "M36ADRGRP - Adressgruppen",
    "30": "M36ADRART - Adressart",
    "31": "M36ADRZIEL - Zielgruppen",
    "32": "M36ADRVERTG - Vertriebsgebiet",
    "33": "M36BRA - Branchen",
    "34": "M36FILIALEN - Standorte",
    "35": "M36BG - Beleggruppe",
    "36": "M36BEL - Belege",
    "38": "M38POS - Positionen",
    "39": "M38BEL - Belege",
    "40": "M36CHAR - Chargen",
    "41": "M00ID0202 - TOPSERV Partner",
    "42": "M36ANP - Ansprechpartner",
    "43": "M36ID0208 - Lieferadressen",
    "44": "M3035_HCSR_NC - Positionen",
    "48": "M3035_HCSR_KE - Belege",
    "49": "M3035_HCSR_KE - Positionen",
    "50": "M3038_HCSR_KE - Belege",
    "51": "M3035_EKV - Einkaufsgemeinschaft",
    "52": "M3035_EKV_KD - Einkaufsverbund Kunden",
    "53": "M36ID0625 - OE-Einheit / Objekttyp",
    "54": "PBI36WGR - Warengruppenstamm",
    "55": "M36NK - Artikelsuchkategorien",
    "56": "M36ID0240 - Hauptkat PIM",
    "57": "M36ID0241 - Nebenkat PIM",
    "58": "M36ID0335 - Artikelkategorie TOPSERV PIM",
    "59": "M36ID0337 - TOPSERV Warengruppe",
    "61": "M365FTA_VA - FVE",
    "62": "M36ID0603 - Besuchsgründe",
    "63": "M36IDBSE0043 - Besuchberichte",
    "65": "M36VTR - Vertreter",
    "66": "M36SORTIMENT - Kundensortimente",
    "67": "M36STUEPREIS - Stückpreis",
    "68": "M36ART_LGR - Artikel-Lager ",
    "69": "M36POS_SHORT - POS_TEST"
}


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
            schema=REPORT_SCHEMA,
            if_exists="append",
            index=False
        )

        print(f"Log geschrieben: {model} - {status}")

    except Exception as e:
        print(f"Fehler beim Schreiben ins Log: {e}")


def get_mapping_from_filename(file_path):
    parts = file_path.stem.split("_")

    file_id = "UNBEKANNT"
    mapping_name = "UNBEKANNT"

    if len(parts) >= 2:
        file_id = parts[1]
        mapping_name = FILE_MAPPING.get(file_id, "UNBEKANNT")

    return file_id, mapping_name


def file_contains_error(file_path):
    with open(file_path, "rb") as file:
        while True:
            block = file.read(1024 * 1024)

            if not block:
                return False

            if SEARCH_TEXT in block:
                return True


def check_today_text_files():

    today = datetime.date.today()
    checked_files = 0
    has_error = False

    for file_path in TEXT_FOLDER.glob("*.TXT"):

        file_date = datetime.datetime.fromtimestamp(
            file_path.stat().st_mtime
        ).date()

        if file_date != today:
            continue

        checked_files += 1

        timestamp = datetime.datetime.now()
        start_time = datetime.datetime.now()

        file_id, mapping_name = get_mapping_from_filename(file_path)

        model = f"CHECK_TXT_ERROR_{mapping_name}"

        status = "ERFOLGREICH"
        message = (
            f"Kein ERROR gefunden | "
            f"ID={file_id} | "
            f"Mapping={mapping_name} | "
            f"Datei={file_path.name}"
        )

        try:
            error_found = file_contains_error(file_path)

            if error_found:
                status = "FEHLER"
                has_error = True
                message = (
                    f"ERROR gefunden | "
                    f"ID={file_id} | "
                    f"Mapping={mapping_name} | "
                    f"Datei={file_path.name}"
                )

        except Exception as e:
            status = "FEHLER"
            has_error = True
            message = (
                f"Fehler beim Prüfen der Datei | "
                f"ID={file_id} | "
                f"Mapping={mapping_name} | "
                f"Datei={file_path.name} | "
                f"Fehler={str(e)}"
            )

        end_time = datetime.datetime.now()
        duration = (end_time - start_time).total_seconds()

        write_to_postgres(
            timestamp,
            model,
            status,
            duration,
            message
        )

    if checked_files == 0:
        timestamp = datetime.datetime.now()

        write_to_postgres(
            timestamp,
            "CHECK_TXT_ERROR",
            "FEHLER",
            0,
            "Keine heutigen TXT-Dateien gefunden"
        )

        exit(1)

    if has_error:
        exit(1)

    exit(0)


if __name__ == "__main__":
    check_today_text_files()