{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel AS (

    SELECT
        wencke_id,
        mandant,
        artikel_nr,
        art_herstellernummer,
        adr_lieferant_1
    FROM {{ ref('bronze_wencke_artikel_attribute') }}

),

lieferant AS (

    SELECT
        wencke_id,
        adr_nr,
        adr_text,
        topserv_lieferanten_nr,
        adr_zentral_kunden_nr
    FROM {{ ref('silver_wencke_adressen') }}

)

SELECT
    artikel.wencke_id,
    artikel.mandant,
    artikel.artikel_nr AS art_artikelnummer,
    artikel.art_herstellernummer,
    artikel.adr_lieferant_1,
    lieferant.adr_nr AS art_lieferant,
    lieferant.adr_text AS art_lieferantbezeichnung,
    lieferant.topserv_lieferanten_nr,
    lieferant.adr_zentral_kunden_nr
FROM artikel

LEFT JOIN lieferant
    ON artikel.adr_lieferant_1 = lieferant.wencke_id