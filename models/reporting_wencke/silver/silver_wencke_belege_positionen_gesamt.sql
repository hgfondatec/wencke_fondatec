{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT *
FROM {{ ref('silver_wencke_belege_positionen') }}

UNION ALL

SELECT *
FROM {{ ref('silver_wencke_belege_nebenkosten_positionen') }}