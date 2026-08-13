{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    tour,
    fahrer,
    lkw,
    gewicht,
    gesamtgewicht_netto,
    gesamtgewicht_brutto
FROM {{ source('raw', 'wencke_lv_belege_versand') }}