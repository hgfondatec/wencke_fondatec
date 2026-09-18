{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH bediener AS (

    SELECT
        *
    FROM {{ ref('bronze_wencke_bediener') }}
    WHERE bed_id IS NOT NULL
      AND bed_id <> ''

),

bediener_aktuell AS (

    SELECT DISTINCT ON (bed_id, mandant)
        *
    FROM bediener

    ORDER BY
        bed_id,
        mandant,
        geaendert_am DESC NULLS LAST,
        geaendert_um DESC NULLS LAST

)

SELECT

    *,

    CONCAT(
        COALESCE(bed_id::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS bed_key,

    CONCAT(
        COALESCE(bed_id::text, ''),
        '_',
        COALESCE(bed_name::text, '')
    ) AS bed_bezeichnung,

    CONCAT(
        COALESCE(mandant::text, ''),
        '_',
        COALESCE(v51_filialnummer::text, '')
    ) AS bed_filiale_key

FROM bediener_aktuell