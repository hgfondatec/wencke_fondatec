{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    mandant,
    user_id,
    "type" AS stat_type,
    value AS stat_value,
    "date" AS stat_date,
    granularity
FROM {{ source('raw', 'wencke_lv_bw_user_stats') }}