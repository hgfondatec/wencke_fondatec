{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel_lieferant AS (

    SELECT 
        *,
        CONCAT(
            COALESCE(art_artikelnummer::text, ''),
            '_',
            COALESCE(mandant::text, '')
        ) AS artikel_key

    FROM {{ ref('bronze_wencke_artikel_lieferant') }}

)

SELECT
    *
FROM artikel_lieferant