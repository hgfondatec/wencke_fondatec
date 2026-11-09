{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT
    *
FROM {{ ref('gold_wencke_facts_belege_positionen_master') }} AS b

WHERE b.bel_art IN ('R', 'G')
  AND b.bel_beleg_bonus IS NOT TRUE
  AND b.pos_artikel_nr NOT IN ('ZZ', '09990016', '$KASSE0020') AND adress_key not in ('108579_36')
  AND b.bel_status = 'N'

UNION ALL

SELECT
    *
FROM {{ ref('gold_wencke_facts_belege_positionen_master') }} AS b

WHERE b.bel_art IN ('R', 'G')
  AND b.bel_beleg_bonus IS NOT TRUE
  AND b.pos_artikel_nr NOT IN ('ZZ', '$KASSE0020') AND adress_key in ('108579_36')
  AND b.bel_status = 'N'