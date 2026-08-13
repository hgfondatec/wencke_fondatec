{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}


SELECT

        *

FROM {{ ref('gold_wencke_facts_belege_positionen_master') }} b

WHERE b.bel_art IN ('R', 'G')