{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel_lieferant AS (

    SELECT DISTINCT
        mandant,
        art_artikelnummer,
        art_herstellernummer,
        art_lieferant,
        art_lieferantbezeichnung,
        topserv_lieferanten_nr,
        adr_zentral_kunden_nr,

        CONCAT(
            COALESCE(art_artikelnummer::text, ''),
            '_',
            COALESCE(mandant::text, '')
        ) AS artikel_key

    FROM {{ ref('silver_wencke_artikel_lieferant') }}

)

SELECT *
FROM artikel_lieferant