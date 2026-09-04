{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['bestand']
    )
}}

SELECT
    wencke_id,
    lager,
    art_bestand,
    art_beauftragt,
    art_verfuegbar,
    art_bestellt,
    art_bestelltzum,
    art_naechster_bestelltermin,
    art_naechste_bestellmenge,
    art_ueberbestand,
    art_mindestbestand,
    art_reichweite
FROM {{ source('raw', 'wencke_lv_artikel_attribute_lager') }}