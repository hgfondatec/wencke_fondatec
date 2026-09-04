{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['bestand']
    )
}}

SELECT
    artikelnummer,
    art_ek_netto,
    art_lagereinheit,
    lieferantenbezeichnung,
    gesperrter_artikel,
    auswahl_gesperrt,
    gefahrstoff,
    lager_id,
    lagerbestand,
    beauftragt,
    verfuegbar,
    bestellt,
    bestelltzum,
    naechster_bestelltermin,
    naechste_bestellmenge,
    ueberbestand,
    mindestbestand,
    reichweite,
    mandant_id,
    mandant_lager_key
FROM {{ ref('silver_wencke_artikel_bestand') }}