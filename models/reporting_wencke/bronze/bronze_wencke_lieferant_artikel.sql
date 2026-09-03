{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH lieferant AS (

    SELECT DISTINCT
        mandant                                             AS mandant,
        artikel_nr                                          AS art_artikelnummer,
        art_herstellernummer                                AS art_herstellernummer,
        adr_lieferant_1                                     AS art_lieferant
    FROM {{ source('raw', 'wencke_lv_artikel_attribute') }}
)

SELECT *
FROM lieferant