{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH sortimentpreise AS (

    SELECT
        *
    FROM {{ ref('bronze_wencke_artikel_sortimentpreise') }}

),

markiert AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY adr_nr, artikel
            ORDER BY
                gueltig_bis DESC,
                gueltig_ab DESC
        ) AS aktuell_rang

    FROM sortimentpreise

)

SELECT

    *,

    aktuell_rang = 1 AS ist_aktuell,

    CONCAT(
        COALESCE(artikel::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS artikel_key,

    CONCAT(
        COALESCE(adr_nr::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS adress_key

FROM markiert