{{ config(
    materialized = 'table',
    schema = 'tourenplanung'
) }}

SELECT
    beleg_adress_key,
    adr_nr,
    adr_text,
    adr_strasse,
    adr_plz,
    adr_ort,
    adr_land,
    vertreter_key,
    vertreter,
    latitude,
    longitude,
    umsatz_dieses_jahr,
    umsatz_vorjahr_ytd,
    rohertrag_dieses_jahr,
    rohertragsquote_prozent,
    umsatzentwicklung_prozent,
    adr_abc_kunde,
    besuchsberichte_soll,
    besuch_ist,
    letzter_besuch,
    score_umsatz,
    score_rohertrag,
    score_entwicklung,
    score_besuch,
    score_letzter_besuch,
    score_abc,
    score_gesamt,
    ROW_NUMBER() OVER (
        PARTITION BY vertreter_key
        ORDER BY score_gesamt DESC, beleg_adress_key
    ) AS prioritaet_rang
FROM {{ ref('tourenplanung_scoring') }}
WHERE latitude BETWEEN -90 AND 90
  AND longitude BETWEEN -180 AND 180
  AND NOT (latitude = 0 AND longitude = 0)