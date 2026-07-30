{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_lv_belege_positionen_id,
    roh_vor_bonus

FROM {{ source('raw', 'wencke_lv_belege_positionen_bonus') }}