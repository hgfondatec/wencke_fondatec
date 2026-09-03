{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel_lieferant AS (

    SELECT distinct
        mandant                                             AS mandant,
        art_artikelnummer                                   AS art_artikelnummer,
        art_herstellernummer                                AS art_herstellernummer,
        art_lieferant                                       AS art_lieferant,
        art_lieferantbezeichnung                            AS art_lieferantbezeichnung,
        CONCAT(
            COALESCE(art_artikelnummer::text, ''),
            '_',
            COALESCE(mandant::text, '')
        ) AS artikel_key

    FROM {{ ref('silver_wencke_artikel') }}

)

SELECT
    *
FROM artikel_lieferant