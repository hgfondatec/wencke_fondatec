{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    rezept_variante
FROM {{ source('raw', 'wencke_lv_belege_rezept') }}