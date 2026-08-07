{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH lieferant AS (

    SELECT DISTINCT
        32                                                  AS mandant,
        art_artikelnummer                                   AS art_artikelnummer,
        TRIM(art_herstellernummer)                          AS art_herstellernummer,
        art_lieferant                                       AS art_lieferant,
        art_lieferantbezeichnung                            AS art_lieferantbezeichnung
    FROM {{ ref('lloyd_gold_artikel') }}

    UNION ALL

    SELECT DISTINCT
        36                                                  AS mandant,
        art_artikelnummer                                   AS art_artikelnummer,
        TRIM(art_herstellernummer)                          AS art_herstellernummer,
        art_lieferant                                       AS art_lieferant,
        art_lieferantbezeichnung                            AS art_lieferantbezeichnung
    FROM {{ ref('nonne_gold_artikel_v2') }}

    UNION ALL

    SELECT DISTINCT
        38                                                  AS mandant,
        art_artikelnummer                                   AS art_artikelnummer,
        TRIM(art_herstellernummer)                          AS art_herstellernummer,
        art_lieferant                                       AS art_lieferant,
        art_lieferantbezeichnung                            AS art_lieferantbezeichnung
    FROM {{ ref('kernreich_gold_artikel_v2') }}

    UNION ALL

    SELECT DISTINCT
        39                                                  AS mandant,
        art_artikelnummer                                   AS art_artikelnummer,
        TRIM(art_herstellernummer)                          AS art_herstellernummer,
        art_lieferant                                       AS art_lieferant,
        art_lieferantbezeichnung                            AS art_lieferantbezeichnung
    FROM {{ ref('glasofix_gold_artikel') }}

    UNION ALL

    SELECT DISTINCT
        42                                                  AS mandant,
        art_artikelnummer                                   AS art_artikelnummer,
        TRIM(art_herstellernummer)                          AS art_herstellernummer,
        art_lieferant                                       AS art_lieferant,
        art_lieferantbezeichnung                            AS art_lieferantbezeichnung
    FROM {{ ref('vms_gold_artikel') }}

)

SELECT *
FROM lieferant