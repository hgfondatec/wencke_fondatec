{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['artikel_check']
    )
}}

WITH artikel AS (

    SELECT *
    FROM {{ ref('silver_wencke_artikel') }}
    WHERE mandant IN (39, 32, 42, 36)

),

artikel_ids AS (

    SELECT DISTINCT
        art_artikelnummer
    FROM artikel

),

t39 AS (

    SELECT *
    FROM artikel
    WHERE mandant = 39

),

t32 AS (

    SELECT *
    FROM artikel
    WHERE mandant = 32

),

t42 AS (

    SELECT *
    FROM artikel
    WHERE mandant = 42

),

t36 AS (

    SELECT *
    FROM artikel
    WHERE mandant = 36

),

tos AS (

    SELECT DISTINCT
        ar_text AS art_artikelnummer

    FROM {{ ref('wencke_bronze_tos_artikel_attribut') }}

    WHERE ar_art = 1389

)

SELECT

    base.art_artikelnummer,


    /* =========================================================
       VERFÜGBARKEIT
    ========================================================= */

    CASE WHEN t39.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_39,
    CASE WHEN t32.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_32,
    CASE WHEN t42.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_42,
    CASE WHEN t36.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END AS verfuegbar_36,


    /* =========================================================
       REPORTING
    ========================================================= */

    {{ match_value_unique('art_artikelname') }}
        AS art_artikelname_reporting,

    {{ match_value_unique('art_bezeichnung') }}
        AS art_bezeichnung_reporting,


    /* =========================================================
       VERFÜGBAR SCORE
    ========================================================= */

    (
        CASE WHEN t39.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t32.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t42.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN t36.art_artikelnummer IS NOT NULL THEN 1 ELSE 0 END
    ) AS verfuegbar_score,


    /* =========================================================
       TOS
    ========================================================= */

    CASE
        WHEN tos.art_artikelnummer IS NOT NULL THEN 'J'
        ELSE 'N'
    END AS art_tos_verfuegbar,


    /* =========================================================
       ARTIKELNAME
    ========================================================= */

    t39.art_artikelname AS art_artikelname_39,
    t32.art_artikelname AS art_artikelname_32,
    t42.art_artikelname AS art_artikelname_42,
    t36.art_artikelname AS art_artikelname_36,

    {{ match_score('art_artikelname') }}
        AS art_artikelname_matchscore,

    {{ match_value('art_artikelname') }}
        AS art_artikelname_match,


    /* =========================================================
       ARTIKELBEZEICHNUNG
    ========================================================= */

    t39.art_bezeichnung AS art_bezeichnung_39,
    t32.art_bezeichnung AS art_bezeichnung_32,
    t42.art_bezeichnung AS art_bezeichnung_42,
    t36.art_bezeichnung AS art_bezeichnung_36,

    {{ match_score('art_bezeichnung') }}
        AS art_bezeichnung_matchscore,

    {{ match_value('art_bezeichnung') }}
        AS art_bezeichnung_match,


    /* =========================================================
       BEZEICHNUNG 2
    ========================================================= */

    t39.art_bezeichnung_2 AS art_bezeichnung_2_39,
    t32.art_bezeichnung_2 AS art_bezeichnung_2_32,
    t42.art_bezeichnung_2 AS art_bezeichnung_2_42,
    t36.art_bezeichnung_2 AS art_bezeichnung_2_36,

    {{ match_score('art_bezeichnung_2') }}
        AS art_bezeichnung_2_matchscore,

    {{ match_value('art_bezeichnung_2') }}
        AS art_bezeichnung_2_match,


    /* =========================================================
       BEZEICHNUNG 3
    ========================================================= */

    t39.art_bezeichnung_3 AS art_bezeichnung_3_39,
    t32.art_bezeichnung_3 AS art_bezeichnung_3_32,
    t42.art_bezeichnung_3 AS art_bezeichnung_3_42,
    t36.art_bezeichnung_3 AS art_bezeichnung_3_36,

    {{ match_score('art_bezeichnung_3') }}
        AS art_bezeichnung_3_matchscore,

    {{ match_value('art_bezeichnung_3') }}
        AS art_bezeichnung_3_match,


    /* =========================================================
       BEZEICHNUNG 4
    ========================================================= */

    t39.art_bezeichnung_4 AS art_bezeichnung_4_39,
    t32.art_bezeichnung_4 AS art_bezeichnung_4_32,
    t42.art_bezeichnung_4 AS art_bezeichnung_4_42,
    t36.art_bezeichnung_4 AS art_bezeichnung_4_36,

    {{ match_score('art_bezeichnung_4') }}
        AS art_bezeichnung_4_matchscore,

    {{ match_value('art_bezeichnung_4') }}
        AS art_bezeichnung_4_match,


    /* =========================================================
       HAUPTWARENGRUPPE NUMMER
    ========================================================= */

    t39.art_hauptwarengruppe_nummer AS art_hauptwarengruppe_nummer_39,
    t32.art_hauptwarengruppe_nummer AS art_hauptwarengruppe_nummer_32,
    t42.art_hauptwarengruppe_nummer AS art_hauptwarengruppe_nummer_42,
    t36.art_hauptwarengruppe_nummer AS art_hauptwarengruppe_nummer_36,

    {{ match_score('art_hauptwarengruppe_nummer') }}
        AS art_hauptwarengruppe_nummer_matchscore,

    {{ match_value('art_hauptwarengruppe_nummer') }}
        AS art_hauptwarengruppe_nummer_match,


    /* =========================================================
       HAUPTWARENGRUPPE
    ========================================================= */

    t39.art_hauptwarengruppe AS art_hauptwarengruppe_39,
    t32.art_hauptwarengruppe AS art_hauptwarengruppe_32,
    t42.art_hauptwarengruppe AS art_hauptwarengruppe_42,
    t36.art_hauptwarengruppe AS art_hauptwarengruppe_36,

    {{ match_score('art_hauptwarengruppe') }}
        AS art_hauptwarengruppe_matchscore,

    {{ match_value('art_hauptwarengruppe') }}
        AS art_hauptwarengruppe_match,


    /* =========================================================
       HAUPTWARENBEZEICHNUNG
    ========================================================= */

    t39.art_hauptwarenbezeichnung AS art_hauptwarenbezeichnung_39,
    t32.art_hauptwarenbezeichnung AS art_hauptwarenbezeichnung_32,
    t42.art_hauptwarenbezeichnung AS art_hauptwarenbezeichnung_42,
    t36.art_hauptwarenbezeichnung AS art_hauptwarenbezeichnung_36,

    {{ match_score('art_hauptwarenbezeichnung') }}
        AS art_hauptwarenbezeichnung_matchscore,

    {{ match_value('art_hauptwarenbezeichnung') }}
        AS art_hauptwarenbezeichnung_match,

    {{ match_value_unique('art_hauptwarenbezeichnung') }}
        AS art_hauptwarenbezeichnung_reporting,


    /* =========================================================
       NEBENWARENGRUPPE NUMMER
    ========================================================= */

    t39.art_nebenwarengruppe_nummer AS art_nebenwarengruppe_nummer_39,
    t32.art_nebenwarengruppe_nummer AS art_nebenwarengruppe_nummer_32,
    t42.art_nebenwarengruppe_nummer AS art_nebenwarengruppe_nummer_42,
    t36.art_nebenwarengruppe_nummer AS art_nebenwarengruppe_nummer_36,

    {{ match_score('art_nebenwarengruppe_nummer') }}
        AS art_nebenwarengruppe_nummer_matchscore,

    {{ match_value('art_nebenwarengruppe_nummer') }}
        AS art_nebenwarengruppe_nummer_match,


    /* =========================================================
       NEBENWARENGRUPPE
    ========================================================= */

    t39.art_nebenwarengruppe AS art_nebenwarengruppe_39,
    t32.art_nebenwarengruppe AS art_nebenwarengruppe_32,
    t42.art_nebenwarengruppe AS art_nebenwarengruppe_42,
    t36.art_nebenwarengruppe AS art_nebenwarengruppe_36,

    {{ match_score('art_nebenwarengruppe') }}
        AS art_nebenwarengruppe_matchscore,

    {{ match_value('art_nebenwarengruppe') }}
        AS art_nebenwarengruppe_match,


    /* =========================================================
       NEBENWARENGRUPPE BEZEICHNUNG
    ========================================================= */

    t39.art_nebenwarengruppebezeichnung AS art_nebenwarengruppebezeichnung_39,
    t32.art_nebenwarengruppebezeichnung AS art_nebenwarengruppebezeichnung_32,
    t42.art_nebenwarengruppebezeichnung AS art_nebenwarengruppebezeichnung_42,
    t36.art_nebenwarengruppebezeichnung AS art_nebenwarengruppebezeichnung_36,

    {{ match_score('art_nebenwarengruppebezeichnung') }}
        AS art_nebenwarengruppebezeichnung_matchscore,

    {{ match_value('art_nebenwarengruppebezeichnung') }}
        AS art_nebenwarengruppebezeichnung_match,

    {{ match_value_unique('art_nebenwarengruppebezeichnung') }}
        AS art_nebenwarengruppebezeichnung_reporting,


    /* =========================================================
       HERSTELLERNUMMER
    ========================================================= */

    t39.art_herstellernummer AS art_herstellernummer_39,
    t32.art_herstellernummer AS art_herstellernummer_32,
    t42.art_herstellernummer AS art_herstellernummer_42,
    t36.art_herstellernummer AS art_herstellernummer_36,

    {{ match_score('art_herstellernummer') }}
        AS art_herstellernummer_matchscore,

    {{ match_value('art_herstellernummer') }}
        AS art_herstellernummer_match,

    {{ match_value_unique('art_herstellernummer') }}
        AS art_herstellernummer_reporting,


    /* =========================================================
       LIEFERANT
    ========================================================= */

    t39.art_lieferant AS art_lieferant_39,
    t32.art_lieferant AS art_lieferant_32,
    t42.art_lieferant AS art_lieferant_42,
    t36.art_lieferant AS art_lieferant_36,

    {{ match_score('art_lieferant') }}
        AS art_lieferant_matchscore,

    {{ match_value('art_lieferant') }}
        AS art_lieferant_match,


    /* =========================================================
       LIEFERANTENBEZEICHNUNG
    ========================================================= */

    t39.art_lieferantbezeichnung AS art_lieferantbezeichnung_39,
    t32.art_lieferantbezeichnung AS art_lieferantbezeichnung_32,
    t42.art_lieferantbezeichnung AS art_lieferantbezeichnung_42,
    t36.art_lieferantbezeichnung AS art_lieferantbezeichnung_36,

    {{ match_score('art_lieferantbezeichnung') }}
        AS art_lieferantbezeichnung_matchscore,

    {{ match_value('art_lieferantbezeichnung') }}
        AS art_lieferantbezeichnung_match,

    {{ match_value_unique('art_lieferantbezeichnung') }}
        AS art_lieferantbezeichnung_reporting,


    /* =========================================================
       DIVERS FLAG
    ========================================================= */

    t39.art_divers_flag AS art_divers_flag_39,
    t32.art_divers_flag AS art_divers_flag_32,
    t42.art_divers_flag AS art_divers_flag_42,
    t36.art_divers_flag AS art_divers_flag_36,

    {{ match_score('art_divers_flag') }}
        AS art_divers_flag_matchscore,

    {{ match_value('art_divers_flag') }}
        AS art_divers_flag_match,


    /* =========================================================
       EK NETTO
    ========================================================= */

    t39.art_ek_netto AS art_ek_netto_39,
    t32.art_ek_netto AS art_ek_netto_32,
    t42.art_ek_netto AS art_ek_netto_42,
    t36.art_ek_netto AS art_ek_netto_36,

    {{ match_score('art_ek_netto') }}
        AS art_ek_netto_matchscore,

    {{ match_value('art_ek_netto') }}
        AS art_ek_netto_match,


    /* =========================================================
       LAGEREINHEIT
    ========================================================= */

    t39.art_lagereinheit AS art_lagereinheit_39,
    t32.art_lagereinheit AS art_lagereinheit_32,
    t42.art_lagereinheit AS art_lagereinheit_42,
    t36.art_lagereinheit AS art_lagereinheit_36,

    {{ match_score('art_lagereinheit') }}
        AS art_lagereinheit_matchscore,

    {{ match_value('art_lagereinheit') }}
        AS art_lagereinheit_match,


    /* =========================================================
       ARTIKEL OHNE TEMPERATURGRENZE
    ========================================================= */

    t39.art_artikel_ohne_temperaturgrenze AS art_artikel_ohne_temperaturgrenze_39,
    t32.art_artikel_ohne_temperaturgrenze AS art_artikel_ohne_temperaturgrenze_32,
    t42.art_artikel_ohne_temperaturgrenze AS art_artikel_ohne_temperaturgrenze_42,
    t36.art_artikel_ohne_temperaturgrenze AS art_artikel_ohne_temperaturgrenze_36,

    {{ match_score('art_artikel_ohne_temperaturgrenze') }}
        AS art_artikel_ohne_temperaturgrenze_matchscore,

    {{ match_value('art_artikel_ohne_temperaturgrenze') }}
        AS art_artikel_ohne_temperaturgrenze_match,


    /* =========================================================
       TEMPERATURGRENZE VORHANDEN
    ========================================================= */

    t39.art_temperaturgrenze_vorhanden AS art_temperaturgrenze_vorhanden_39,
    t32.art_temperaturgrenze_vorhanden AS art_temperaturgrenze_vorhanden_32,
    t42.art_temperaturgrenze_vorhanden AS art_temperaturgrenze_vorhanden_42,
    t36.art_temperaturgrenze_vorhanden AS art_temperaturgrenze_vorhanden_36,

    {{ match_score('art_temperaturgrenze_vorhanden') }}
        AS art_temperaturgrenze_vorhanden_matchscore,

    {{ match_value('art_temperaturgrenze_vorhanden') }}
        AS art_temperaturgrenze_vorhanden_match,


    /* =========================================================
       LAGERTEMPERATUR VON
    ========================================================= */

    t39.art_lagertemperatur_von AS art_lagertemperatur_von_39,
    t32.art_lagertemperatur_von AS art_lagertemperatur_von_32,
    t42.art_lagertemperatur_von AS art_lagertemperatur_von_42,
    t36.art_lagertemperatur_von AS art_lagertemperatur_von_36,

    {{ match_score('art_lagertemperatur_von') }}
        AS art_lagertemperatur_von_matchscore,

    {{ match_value('art_lagertemperatur_von') }}
        AS art_lagertemperatur_von_match,


    /* =========================================================
       LAGERTEMPERATUR BIS
    ========================================================= */

    t39.art_lagertemperatur_bis AS art_lagertemperatur_bis_39,
    t32.art_lagertemperatur_bis AS art_lagertemperatur_bis_32,
    t42.art_lagertemperatur_bis AS art_lagertemperatur_bis_42,
    t36.art_lagertemperatur_bis AS art_lagertemperatur_bis_36,

    {{ match_score('art_lagertemperatur_bis') }}
        AS art_lagertemperatur_bis_matchscore,

    {{ match_value('art_lagertemperatur_bis') }}
        AS art_lagertemperatur_bis_match,


    /* =========================================================
       TRANSPORTTEMPERATUR VON
    ========================================================= */

    t39.art_transporttemperatur_von AS art_transporttemperatur_von_39,
    t32.art_transporttemperatur_von AS art_transporttemperatur_von_32,
    t42.art_transporttemperatur_von AS art_transporttemperatur_von_42,
    t36.art_transporttemperatur_von AS art_transporttemperatur_von_36,

    {{ match_score('art_transporttemperatur_von') }}
        AS art_transporttemperatur_von_matchscore,

    {{ match_value('art_transporttemperatur_von') }}
        AS art_transporttemperatur_von_match,


    /* =========================================================
       TRANSPORTTEMPERATUR BIS
    ========================================================= */

    t39.art_transporttemperatur_bis AS art_transporttemperatur_bis_39,
    t32.art_transporttemperatur_bis AS art_transporttemperatur_bis_32,
    t42.art_transporttemperatur_bis AS art_transporttemperatur_bis_42,
    t36.art_transporttemperatur_bis AS art_transporttemperatur_bis_36,

    {{ match_score('art_transporttemperatur_bis') }}
        AS art_transporttemperatur_bis_matchscore,

    {{ match_value('art_transporttemperatur_bis') }}
        AS art_transporttemperatur_bis_match


FROM artikel_ids base

LEFT JOIN t39
    ON base.art_artikelnummer = t39.art_artikelnummer

LEFT JOIN t32
    ON base.art_artikelnummer = t32.art_artikelnummer

LEFT JOIN t42
    ON base.art_artikelnummer = t42.art_artikelnummer

LEFT JOIN t36
    ON base.art_artikelnummer = t36.art_artikelnummer

LEFT JOIN tos
    ON base.art_artikelnummer = tos.art_artikelnummer

ORDER BY base.art_artikelnummer