{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT DISTINCT
    b.wencke_id,
    b.mandant,
    b.bel_nr,
    b.bel_date,
    b.bel_liefer_versand_date

FROM {{ ref('bronze_wencke_belege') }} b

WHERE b.bel_art = 'b'
  AND b.bel_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '2 years'
  AND b.bel_date < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'