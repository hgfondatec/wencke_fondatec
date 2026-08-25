{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT 
    TRIM(adr_18_8) AS adr_nr,
    TRIM(adr_46_20) AS adr_ekv_nr,
    TO_DATE(NULLIF(TRIM(adr_36_10), ''), 'DD.MM.YYYY') AS ekv_datum,
    32 AS ekv_mandant
FROM {{ source('raw', 'm32adr_ekv') }}

UNION ALL

SELECT 
    TRIM(adr_18_8) AS adr_nr,
    TRIM(adr_46_20) AS adr_ekv_nr,
    TO_DATE(NULLIF(TRIM(adr_36_10), ''), 'DD.MM.YYYY') AS ekv_datum,
    36 AS ekv_mandant
FROM {{ source('raw', 'm36adr_ekv') }}

UNION ALL

SELECT 
    TRIM(adr_18_8) AS adr_nr,
    TRIM(adr_46_20) AS adr_ekv_nr,
    TO_DATE(NULLIF(TRIM(adr_36_10), ''), 'DD.MM.YYYY') AS ekv_datum,
    38 AS ekv_mandant
FROM {{ source('raw', 'm38adr_ekv') }}

UNION ALL

SELECT 
    TRIM(adr_18_8) AS adr_nr,
    TRIM(adr_46_20) AS adr_ekv_nr,
    TO_DATE(NULLIF(TRIM(adr_36_10), ''), 'DD.MM.YYYY') AS ekv_datum,
    39 AS ekv_mandant
FROM {{ source('raw', 'm39adr_ekv') }}

UNION ALL

SELECT 
    TRIM(adr_18_8) AS adr_nr,
    TRIM(adr_46_20) AS adr_ekv_nr,
    TO_DATE(NULLIF(TRIM(adr_36_10), ''), 'DD.MM.YYYY') AS ekv_datum,
    42 AS ekv_mandant
FROM {{ source('raw', 'm42adr_ekv') }}