{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH adr_gruppe AS (

    SELECT DISTINCT
        CASE
            WHEN TRIM(agp_1_2::text) ~ '^-?[0-9]+([.,][0-9]+)?$'
            THEN TRUNC(REPLACE(TRIM(agp_1_2::text), ',', '.')::numeric)
            ELSE NULL
        END AS adrgruppe_id,
        agp_3_30 AS adrgruppe_name,
        '32' AS adrgruppe_mandant
    FROM {{ source('raw', 'm32adrgrp') }}

    UNION ALL

    SELECT DISTINCT
        CASE
            WHEN TRIM(agp_1_2::text) ~ '^-?[0-9]+([.,][0-9]+)?$'
            THEN TRUNC(REPLACE(TRIM(agp_1_2::text), ',', '.')::numeric)
            ELSE NULL
        END AS adrgruppe_id,
        agp_3_30 AS adrgruppe_name,
        '36' AS adrgruppe_mandant
    FROM {{ source('raw', 'm36adrgrp') }}

    UNION ALL

    SELECT DISTINCT
        CASE
            WHEN TRIM(agp_1_2::text) ~ '^-?[0-9]+([.,][0-9]+)?$'
            THEN TRUNC(REPLACE(TRIM(agp_1_2::text), ',', '.')::numeric)
            ELSE NULL
        END AS adrgruppe_id,
        agp_3_30 AS adrgruppe_name,
        '38' AS adrgruppe_mandant
    FROM {{ source('raw', 'm38adrgrp') }}

    UNION ALL

    SELECT DISTINCT
        CASE
            WHEN TRIM(agp_1_2::text) ~ '^-?[0-9]+([.,][0-9]+)?$'
            THEN TRUNC(REPLACE(TRIM(agp_1_2::text), ',', '.')::numeric)
            ELSE NULL
        END AS adrgruppe_id,
        agp_3_30 AS adrgruppe_name,
        '39' AS adrgruppe_mandant
    FROM {{ source('raw', 'm39adrgrp') }}

    UNION ALL

    SELECT DISTINCT
        CASE
            WHEN TRIM(agp_1_2::text) ~ '^-?[0-9]+([.,][0-9]+)?$'
            THEN TRUNC(REPLACE(TRIM(agp_1_2::text), ',', '.')::numeric)
            ELSE NULL
        END AS adrgruppe_id,
        agp_3_30 AS adrgruppe_name,
        '42' AS adrgruppe_mandant
    FROM {{ source('raw', 'm42adrgrp') }}

)

SELECT *
FROM adr_gruppe
WHERE adrgruppe_id IS NOT NULL