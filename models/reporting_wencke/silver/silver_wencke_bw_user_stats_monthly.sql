{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    mandant,
    LPAD(user_id::VARCHAR, 3, '0') AS user_id,
    stat_type,
    stat_value,
    
    stat_date,
    CONCAT(
        LPAD(user_id::VARCHAR, 3, '0'),
        '_',
        mandant::VARCHAR
    ) AS bediener_key
FROM {{ ref('bronze_wencke_bw_user_stats') }}
WHERE granularity = 'month'
  AND stat_type IN (
      'POSCOUNTWA',
      'POSCOUNTWE',
      'LOGINCOUNT'
  )