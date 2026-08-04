{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    ur_reklamation_index
FROM {{ source('raw', 'wencke_lv_belege_reklamation') }}