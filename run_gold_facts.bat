@echo off
REM venv aktivieren
call "C:\dbt\.venv\Scripts\activate.bat"

REM Python-Skript ausführen
cd /d "C:\dbt\wencke_fondatec\tests"
python dbt_runner.py