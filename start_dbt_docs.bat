@echo off
uv run dbt docs generate
uv run dbt docs serve --port 8085
pause