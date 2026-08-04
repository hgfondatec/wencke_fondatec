{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    nk_nr,
    nk_betrag
FROM {{ source('raw', 'wencke_lv_belege_nebenkosten') }}