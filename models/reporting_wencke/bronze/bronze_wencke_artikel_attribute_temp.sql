{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id,
    art_artikel_ohne_temperaturgrenze,
    art_temperaturgrenze_vorhanden,
    art_lagertemperatur_von,
    art_lagertemperatur_bis,
    art_transporttemperatur_von,
    art_transporttemperatur_bis,
    art_abweichungszeitraum,
    art_temperaturueberwachung,
    art_mhd

FROM {{ source('raw', 'wencke_lv_artikel_attribute_temp') }}