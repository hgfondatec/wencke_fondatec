{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH artikel_ids AS (

    SELECT DISTINCT
        art_artikelnummer
    FROM {{ ref('silver_wencke_artikel') }}

),

tos AS (

    SELECT DISTINCT
        ar_text AS art_artikelnummer
    FROM {{ ref('wencke_bronze_tos_artikel_attribut') }}
    WHERE ar_art = 1389

)

SELECT

    base.art_artikelnummer,

    {{ golden_value_wencke('art_artikelname') }}
        AS art_artikelname,

    {{ golden_value_wencke('art_warengruppe') }}
        AS art_warengruppe,

    {{ golden_value_wencke('art_hauptwarengruppe_nummer') }}
        AS art_hauptwarengruppe_nummer,

    {{ golden_value_wencke('art_hauptwarengruppe') }}
        AS art_hauptwarengruppe,

    {{ golden_value_wencke('art_hauptwarenbezeichnung') }}
        AS art_hauptwarenbezeichnung,

    {{ golden_value_wencke('art_nebenwarengruppe_nummer') }}
        AS art_nebenwarengruppe_nummer,

    {{ golden_value_wencke('art_nebenwarengruppe') }}
        AS art_nebenwarengruppe,

    {{ golden_value_wencke('art_nebenwarengruppebezeichnung') }}
        AS art_nebenwarengruppebezeichnung,

    {{ golden_value_wencke('art_herstellernummer') }}
        AS art_herstellernummer,

    {{ golden_value_wencke('art_lieferant') }}
        AS art_lieferant,

    {{ golden_value_wencke('art_lieferantbezeichnung') }}
        AS art_lieferantbezeichnung,

    {{ golden_value_wencke('art_divers_flag') }}
        AS art_divers_flag,

    {{ golden_value_wencke('art_ek_netto') }}::numeric
        AS art_ek_netto,

    {{ golden_value_wencke('art_lagereinheit') }}
        AS art_lagereinheit,

    {{ golden_value_wencke('art_bezeichnung_2') }}
        AS art_bezeichnung_2,

    {{ golden_value_wencke('art_bezeichnung_3') }}
        AS art_bezeichnung_3,

    {{ golden_value_wencke('art_bezeichnung_4') }}
        AS art_bezeichnung_4,

    {{ golden_value_wencke('art_artikel_ohne_temperaturgrenze') }}
        AS art_artikel_ohne_temperaturgrenze,

    {{ golden_value_wencke('art_temperaturgrenze_vorhanden') }}
        AS art_temperaturgrenze_vorhanden,

    {{ golden_value_wencke('art_lagertemperatur_von') }}
        AS art_lagertemperatur_von,

    {{ golden_value_wencke('art_lagertemperatur_bis') }}
        AS art_lagertemperatur_bis,

    {{ golden_value_wencke('art_transporttemperatur_von') }}
        AS art_transporttemperatur_von,

    {{ golden_value_wencke('art_transporttemperatur_bis') }}
        AS art_transporttemperatur_bis,

    {{ golden_value_wencke('art_sort_kz') }}
        AS art_sort_kz,

    {{ golden_value_wencke('art_pauschalartikel') }}
        AS art_pauschalartikel,

    {{ golden_value_wencke('art_pflege_divisor') }}
        AS art_pflege_divisor,

    {{ golden_value_wencke('art_abc_kategorie') }}
        AS art_abc_kategorie,

    {{ golden_value_wencke('art_gesperrter_artikel') }}
        AS art_gesperrter_artikel,

    {{ golden_value_wencke('art_auswahl_gesperrt') }}
        AS art_auswahl_gesperrt,

    {{ golden_value_wencke('art_gefahrstoff') }}
        AS art_gefahrstoff,

    CASE
        WHEN tos.art_artikelnummer IS NOT NULL THEN 'J'
        ELSE 'N'
    END AS art_tos_verfuegbar

FROM artikel_ids base

LEFT JOIN tos
    ON base.art_artikelnummer = tos.art_artikelnummer