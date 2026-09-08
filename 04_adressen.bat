@echo off

REM venv aktivieren
call "C:\dbt\.venv\Scripts\activate.bat"

REM Zum Python-Skript wechseln
cd /d "C:\dbt\wencke_fondatec\tests"

REM Adressen ausführen
python dbt_runner.py adressen

exit /b %ERRORLEVEL%