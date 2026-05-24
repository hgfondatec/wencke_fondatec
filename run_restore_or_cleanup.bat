@echo off
REM venv aktivieren
call "C:\dbt\.venv\Scripts\activate.bat"

REM Python-Skript ausführen
cd /d "C:\dbt\wencke_fondatec\tests"
python restore_or_cleanup_gold.py