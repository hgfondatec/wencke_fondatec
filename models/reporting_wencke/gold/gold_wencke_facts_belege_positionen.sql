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
  AND b.pos_artikel_nr NOT IN ('ZZ', '09990016', '$KASSE0020')