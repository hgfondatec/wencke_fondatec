{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH bediener AS (

    SELECT
        *
    FROM {{ ref('bronze_wencke_bediener') }}

),

bediener_aktuell AS (

    SELECT DISTINCT ON (bed_nr, mandant)
        *
    FROM bediener

    ORDER BY
        bed_nr,
        mandant,
        bed_created_at DESC NULLS LAST
)

SELECT

    *,

    CONCAT(
        LPAD(COALESCE(bed_nr::text, ''), 3, '0'),
        '_',
        COALESCE(mandant::text, '')
    ) AS bed_key,

    CONCAT(
        LPAD(COALESCE(bed_nr::text, ''), 3, '0'),
        '_',
        COALESCE(bed_username::text, '')
    ) AS bed_bezeichnung

FROM bediener_aktuell