
{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH current_date_berlin AS (

    -- Aktuelles Datum nach deutscher Zeit
    -- Berücksichtigt automatisch Sommer- und Winterzeit

    SELECT
        (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Berlin')::date
            AS berlin_today

),

date_range AS (

    SELECT
        generate_series(
            DATE '2024-01-01',
            MAKE_DATE(
                EXTRACT(YEAR FROM berlin_today)::int + 2,
                12,
                31
            ),
            INTERVAL '1 day'
        )::date AS date_value,

        berlin_today

    FROM current_date_berlin

),

date_base AS (

    SELECT
        date_value,
        berlin_today,

        EXTRACT(YEAR FROM date_value)::int AS year_number,
        EXTRACT(MONTH FROM date_value)::int AS month_number,
        EXTRACT(QUARTER FROM date_value)::int AS quarter_number,
        EXTRACT(DAY FROM date_value)::int AS day_of_month,
        EXTRACT(DOY FROM date_value)::int AS day_of_year,
        EXTRACT(ISODOW FROM date_value)::int AS day_of_week_number,
        EXTRACT(WEEK FROM date_value)::int AS week_number,
        EXTRACT(ISOYEAR FROM date_value)::int AS iso_year,

        DATE_TRUNC('week', date_value)::date AS week_start_date,

        (
            DATE_TRUNC('week', date_value)
            + INTERVAL '6 days'
        )::date AS week_end_date,

        DATE_TRUNC('month', date_value)::date AS month_start_date,

        (
            DATE_TRUNC('month', date_value)
            + INTERVAL '1 month - 1 day'
        )::date AS month_end_date,

        DATE_TRUNC('quarter', date_value)::date AS quarter_start_date,

        (
            DATE_TRUNC('quarter', date_value)
            + INTERVAL '3 months - 1 day'
        )::date AS quarter_end_date,

        DATE_TRUNC('year', date_value)::date AS year_start_date,

        (
            DATE_TRUNC('year', date_value)
            + INTERVAL '1 year - 1 day'
        )::date AS year_end_date

    FROM date_range

),

date_relative AS (

    SELECT
        *,

        -- ==================================================
        -- RELATIVER TAG (BERLIN)
        -- ==================================================

        (
            date_value - berlin_today
        ) AS relative_day,

        -- ==================================================
        -- RELATIVE WOCHE (BERLIN)
        -- ==================================================

        (
            (
                week_start_date
                - DATE_TRUNC('week', berlin_today::timestamp)::date
            ) / 7
        )::int AS relative_week,

        -- ==================================================
        -- RELATIVER MONAT (BERLIN)
        -- ==================================================

        (
            (
                year_number
                - EXTRACT(YEAR FROM berlin_today)::int
            ) * 12

            + month_number

            - EXTRACT(MONTH FROM berlin_today)::int
        ) AS relative_month,

        -- ==================================================
        -- RELATIVES QUARTAL (BERLIN)
        -- ==================================================

        (
            (
                year_number
                - EXTRACT(YEAR FROM berlin_today)::int
            ) * 4

            + quarter_number

            - EXTRACT(QUARTER FROM berlin_today)::int
        ) AS relative_quarter,

        -- ==================================================
        -- RELATIVES JAHR (BERLIN)
        -- ==================================================

        (
            year_number
            - EXTRACT(YEAR FROM berlin_today)::int
        ) AS relative_year

    FROM date_base

),

date_calendar AS (

    SELECT

        -- ==================================================
        -- BESTEHENDE POWER QUERY SPALTEN
        -- ==================================================

        date_value AS "Date",

        year_number::text AS "Year",

        month_number AS "MonthNumber",

        (ARRAY[
            'Januar', 'Februar', 'März', 'April',
            'Mai', 'Juni', 'Juli', 'August',
            'September', 'Oktober', 'November', 'Dezember'
        ])[month_number] AS "MonthName",

        (ARRAY[
            'Jan', 'Feb', 'Mär', 'Apr',
            'Mai', 'Jun', 'Jul', 'Aug',
            'Sep', 'Okt', 'Nov', 'Dez'
        ])[month_number] AS "MonthNameAbbr",

        TO_CHAR(date_value, 'YYYY-MM') AS "YearMonth",

        'Q' || quarter_number AS "Quarter",

        (ARRAY[
            'Montag', 'Dienstag', 'Mittwoch',
            'Donnerstag', 'Freitag',
            'Samstag', 'Sonntag'
        ])[day_of_week_number] AS "DayOfWeek",

        (ARRAY[
            'Jan', 'Feb', 'Mär', 'Apr',
            'Mai', 'Jun', 'Jul', 'Aug',
            'Sep', 'Okt', 'Nov', 'Dez'
        ])[month_number]
            || '-' || year_number AS "MonatJahr",

        year_number * 100
            + month_number AS "MonatJahrSort",

        relative_month AS "RelativeMonth",

        -- ==================================================
        -- ZUSÄTZLICHE DATUMSINFORMATIONEN
        -- ==================================================

        TO_CHAR(date_value, 'YYYYMMDD')::int AS date_key,

        day_of_month,
        day_of_year,
        day_of_week_number,

        quarter_number,

        TO_CHAR(date_value, 'YYYY')
            || '-Q'
            || quarter_number AS year_quarter,

        -- ==================================================
        -- KALENDERWOCHEN
        -- ==================================================

        iso_year,
        week_number,

        iso_year
            || '-KW'
            || LPAD(week_number::text, 2, '0')
            AS year_week,

        week_start_date,
        week_end_date,

        -- ==================================================
        -- MONATS-, QUARTALS- UND JAHRESGRENZEN
        -- ==================================================

        month_start_date,
        month_end_date,

        quarter_start_date,
        quarter_end_date,

        year_start_date,
        year_end_date,

        EXTRACT(DAY FROM month_end_date)::int
            AS days_in_month,

        -- ==================================================
        -- RELATIVE ZEITRÄUME (BERLIN)
        -- ==================================================

        relative_day,
        relative_week,
        relative_month,
        relative_quarter,
        relative_year,

        -- ==================================================
        -- DEUTSCHE RELATIVE BEZEICHNUNGEN (BERLIN)
        -- ==================================================

        CASE
            WHEN relative_day = -2 THEN 'Vorgestern'
            WHEN relative_day = -1 THEN 'Gestern'
            WHEN relative_day = 0 THEN 'Heute'
            WHEN relative_day = 1 THEN 'Morgen'
            WHEN relative_day = 2 THEN 'Übermorgen'
            ELSE TO_CHAR(date_value, 'DD.MM.YYYY')
        END AS relative_day_label,

        CASE
            WHEN relative_week = -2 THEN 'Vorletzte Woche'
            WHEN relative_week = -1 THEN 'Letzte Woche'
            WHEN relative_week = 0 THEN 'Aktuelle Woche'
            WHEN relative_week = 1 THEN 'Nächste Woche'
            WHEN relative_week = 2 THEN 'Übernächste Woche'
            ELSE
                'KW '
                || LPAD(week_number::text, 2, '0')
                || ' / '
                || iso_year
        END AS relative_week_label,

        CASE
            WHEN relative_month = -2 THEN 'Vorletzter Monat'
            WHEN relative_month = -1 THEN 'Letzter Monat'
            WHEN relative_month = 0 THEN 'Aktueller Monat'
            WHEN relative_month = 1 THEN 'Nächster Monat'
            WHEN relative_month = 2 THEN 'Übernächster Monat'
            ELSE TO_CHAR(date_value, 'YYYY-MM')
        END AS relative_month_label,

        CASE
            WHEN relative_quarter = -2 THEN 'Vorletztes Quartal'
            WHEN relative_quarter = -1 THEN 'Letztes Quartal'
            WHEN relative_quarter = 0 THEN 'Aktuelles Quartal'
            WHEN relative_quarter = 1 THEN 'Nächstes Quartal'
            WHEN relative_quarter = 2 THEN 'Übernächstes Quartal'
            ELSE
                year_number || '-Q' || quarter_number
        END AS relative_quarter_label,

        CASE
            WHEN relative_year = -2 THEN 'Vorletztes Jahr'
            WHEN relative_year = -1 THEN 'Letztes Jahr'
            WHEN relative_year = 0 THEN 'Aktuelles Jahr'
            WHEN relative_year = 1 THEN 'Nächstes Jahr'
            WHEN relative_year = 2 THEN 'Übernächstes Jahr'
            ELSE year_number::text
        END AS relative_year_label,

        -- ==================================================
        -- AKTUELLE ZEITRÄUME (BERLIN)
        -- ==================================================

        (relative_day = 0) AS is_today,

        (relative_day = -1) AS is_yesterday,

        (relative_week = 0) AS is_current_week,

        (relative_week = -1) AS is_last_week,

        (relative_month = 0) AS is_current_month,

        (relative_month = -1) AS is_last_month,

        (relative_quarter = 0) AS is_current_quarter,

        (relative_quarter = -1) AS is_last_quarter,

        (relative_year = 0) AS is_current_year,

        (relative_year = -1) AS is_last_year,

        (relative_year = -2) AS is_previous_two_years,

        -- ==================================================
        -- ROLLIERENDE ZEITRÄUME (BERLIN)
        -- ==================================================

        (
            relative_day BETWEEN -6 AND 0
        ) AS is_last_7_days,

        (
            relative_day BETWEEN -29 AND 0
        ) AS is_last_30_days,

        (
            relative_month BETWEEN -11 AND 0
        ) AS is_last_12_months,

        -- ==================================================
        -- ABGESCHLOSSENE ZEITRÄUME (BERLIN)
        -- ==================================================

        (
            relative_week = -1
        ) AS is_last_completed_week,

        (
            relative_month = -1
        ) AS is_last_completed_month,

        (
            relative_month < 0
        ) AS is_completed_month,

        -- Neue Spalte aus Power Query
        (
            relative_month < 0
        ) AS "MonatAbgeschlossen",

        (
            date_value = month_end_date
        ) AS is_month_end,

        -- ==================================================
        -- MTD / QTD / YTD (BERLIN)
        -- ==================================================

        (
            relative_month = 0
            AND date_value <= berlin_today
        ) AS is_mtd,

        (
            relative_quarter = 0
            AND date_value <= berlin_today
        ) AS is_qtd,

        (
            relative_year = 0
            AND date_value <= berlin_today
        ) AS is_ytd,

        (
            relative_year = -1
            AND date_value <= (
                berlin_today - INTERVAL '1 year'
            )::date
        ) AS is_previous_ytd,

        -- ==================================================
        -- WOCHENENDE / WERKTAGE
        -- ==================================================

        (
            day_of_week_number IN (6, 7)
        ) AS is_weekend,

        (
            day_of_week_number BETWEEN 1 AND 5
        ) AS is_weekday,

        (
            SELECT COUNT(*)::int
            FROM generate_series(
                month_start_date,
                date_value,
                INTERVAL '1 day'
            ) AS d(work_date)

            WHERE
                EXTRACT(ISODOW FROM d.work_date)
                BETWEEN 1 AND 5

        ) AS working_day_of_month,

        -- ==================================================
        -- VORJAHRESVERGLEICH
        -- ==================================================

        (
            date_value - INTERVAL '1 year'
        )::date AS same_day_last_year

    FROM date_relative

)

SELECT *
FROM date_calendar
ORDER BY "Date"
