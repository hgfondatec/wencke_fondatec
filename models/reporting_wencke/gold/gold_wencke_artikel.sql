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

values_long AS (

    SELECT
        s.art_artikelnummer,
        v.field_name,
        v.value

    FROM {{ ref('silver_wencke_artikel') }} s

    CROSS JOIN LATERAL (

        VALUES

            ('art_artikelname', s.art_artikelname::text),
            ('art_warengruppe', s.art_warengruppe::text),

            ('art_hauptwarengruppe_nummer', s.art_hauptwarengruppe_nummer::text),
            ('art_hauptwarengruppe', s.art_hauptwarengruppe::text),
            ('art_hauptwarenbezeichnung', s.art_hauptwarenbezeichnung::text),

            ('art_nebenwarengruppe_nummer', s.art_nebenwarengruppe_nummer::text),
            ('art_nebenwarengruppe', s.art_nebenwarengruppe::text),
            ('art_nebenwarengruppebezeichnung', s.art_nebenwarengruppebezeichnung::text),

            ('art_herstellernummer', s.art_herstellernummer::text),

            ('art_lieferant', s.art_lieferant::text),
            ('art_lieferantbezeichnung', s.art_lieferantbezeichnung::text),

            ('art_divers_flag', s.art_divers_flag::text),

            ('art_ek_netto', s.art_ek_netto::text),
            ('art_lagereinheit', s.art_lagereinheit::text),

            ('art_bezeichnung_2', s.art_bezeichnung_2::text),
            ('art_bezeichnung_3', s.art_bezeichnung_3::text),
            ('art_bezeichnung_4', s.art_bezeichnung_4::text),

            ('art_artikel_ohne_temperaturgrenze', s.art_artikel_ohne_temperaturgrenze::text),
            ('art_temperaturgrenze_vorhanden', s.art_temperaturgrenze_vorhanden::text),

            ('art_lagertemperatur_von', s.art_lagertemperatur_von::text),
            ('art_lagertemperatur_bis', s.art_lagertemperatur_bis::text),

            ('art_transporttemperatur_von', s.art_transporttemperatur_von::text),
            ('art_transporttemperatur_bis', s.art_transporttemperatur_bis::text),

            ('art_sort_kz', s.art_sort_kz::text),
            ('art_pauschalartikel', s.art_pauschalartikel::text),
            ('art_pflege_divisor', s.art_pflege_divisor::text),
            ('art_abc_kategorie', s.art_abc_kategorie::text),

            ('art_gesperrter_artikel', s.art_gesperrter_artikel::text),
            ('art_auswahl_gesperrt', s.art_auswahl_gesperrt::text),

            ('art_gefahrstoff', s.art_gefahrstoff::text)

    ) v(field_name, value)

    WHERE v.value IS NOT NULL

),

scores AS (

    SELECT
        art_artikelnummer,
        field_name,
        value,
        COUNT(*) AS score

    FROM values_long

    GROUP BY
        art_artikelnummer,
        field_name,
        value

),

ranked AS (

    SELECT
        art_artikelnummer,
        field_name,
        value,

        ROW_NUMBER() OVER (

            PARTITION BY
                art_artikelnummer,
                field_name

            ORDER BY
                score DESC,
                LENGTH(value) DESC,
                value ASC

        ) AS rn

    FROM scores

),

golden_values AS (

    SELECT

        art_artikelnummer,

        MAX(value) FILTER (
            WHERE field_name = 'art_artikelname'
        ) AS art_artikelname,

        MAX(value) FILTER (
            WHERE field_name = 'art_warengruppe'
        ) AS art_warengruppe,

        MAX(value) FILTER (
            WHERE field_name = 'art_hauptwarengruppe_nummer'
        ) AS art_hauptwarengruppe_nummer,

        MAX(value) FILTER (
            WHERE field_name = 'art_hauptwarengruppe'
        ) AS art_hauptwarengruppe,

        MAX(value) FILTER (
            WHERE field_name = 'art_hauptwarenbezeichnung'
        ) AS art_hauptwarenbezeichnung,

        MAX(value) FILTER (
            WHERE field_name = 'art_nebenwarengruppe_nummer'
        ) AS art_nebenwarengruppe_nummer,

        MAX(value) FILTER (
            WHERE field_name = 'art_nebenwarengruppe'
        ) AS art_nebenwarengruppe,

        MAX(value) FILTER (
            WHERE field_name = 'art_nebenwarengruppebezeichnung'
        ) AS art_nebenwarengruppebezeichnung,

        MAX(value) FILTER (
            WHERE field_name = 'art_herstellernummer'
        ) AS art_herstellernummer,

        MAX(value) FILTER (
            WHERE field_name = 'art_lieferant'
        ) AS art_lieferant,

        MAX(value) FILTER (
            WHERE field_name = 'art_lieferantbezeichnung'
        ) AS art_lieferantbezeichnung,

        MAX(value) FILTER (
            WHERE field_name = 'art_divers_flag'
        ) AS art_divers_flag,

        MAX(value) FILTER (
            WHERE field_name = 'art_ek_netto'
        )::numeric AS art_ek_netto,

        MAX(value) FILTER (
            WHERE field_name = 'art_lagereinheit'
        ) AS art_lagereinheit,

        MAX(value) FILTER (
            WHERE field_name = 'art_bezeichnung_2'
        ) AS art_bezeichnung_2,

        MAX(value) FILTER (
            WHERE field_name = 'art_bezeichnung_3'
        ) AS art_bezeichnung_3,

        MAX(value) FILTER (
            WHERE field_name = 'art_bezeichnung_4'
        ) AS art_bezeichnung_4,

        MAX(value) FILTER (
            WHERE field_name = 'art_artikel_ohne_temperaturgrenze'
        ) AS art_artikel_ohne_temperaturgrenze,

        MAX(value) FILTER (
            WHERE field_name = 'art_temperaturgrenze_vorhanden'
        ) AS art_temperaturgrenze_vorhanden,

        MAX(value) FILTER (
            WHERE field_name = 'art_lagertemperatur_von'
        ) AS art_lagertemperatur_von,

        MAX(value) FILTER (
            WHERE field_name = 'art_lagertemperatur_bis'
        ) AS art_lagertemperatur_bis,

        MAX(value) FILTER (
            WHERE field_name = 'art_transporttemperatur_von'
        ) AS art_transporttemperatur_von,

        MAX(value) FILTER (
            WHERE field_name = 'art_transporttemperatur_bis'
        ) AS art_transporttemperatur_bis,

        MAX(value) FILTER (
            WHERE field_name = 'art_sort_kz'
        ) AS art_sort_kz,

        MAX(value) FILTER (
            WHERE field_name = 'art_pauschalartikel'
        ) AS art_pauschalartikel,

        MAX(value) FILTER (
            WHERE field_name = 'art_pflege_divisor'
        ) AS art_pflege_divisor,

        MAX(value) FILTER (
            WHERE field_name = 'art_abc_kategorie'
        ) AS art_abc_kategorie,

        MAX(value) FILTER (
            WHERE field_name = 'art_gesperrter_artikel'
        ) AS art_gesperrter_artikel,

        MAX(value) FILTER (
            WHERE field_name = 'art_auswahl_gesperrt'
        ) AS art_auswahl_gesperrt,

        MAX(value) FILTER (
            WHERE field_name = 'art_gefahrstoff'
        ) AS art_gefahrstoff

    FROM ranked

    WHERE rn = 1

    GROUP BY art_artikelnummer

),

tos AS (

    SELECT DISTINCT
        ar_text AS art_artikelnummer

    FROM {{ ref('wencke_bronze_tos_artikel_attribut') }}

    WHERE ar_art = 1389

)

SELECT

    base.art_artikelnummer,

    g.art_artikelname,

    CASE
        WHEN g.art_artikelname IS NOT NULL
        THEN base.art_artikelnummer || '-' || g.art_artikelname
        ELSE NULL
    END AS art_bezeichnung,

    g.art_warengruppe,

    g.art_hauptwarengruppe_nummer,
    g.art_hauptwarengruppe,
    g.art_hauptwarenbezeichnung,

    g.art_nebenwarengruppe_nummer,
    g.art_nebenwarengruppe,
    g.art_nebenwarengruppebezeichnung,

    g.art_herstellernummer,

    g.art_lieferant,
    g.art_lieferantbezeichnung,

    g.art_divers_flag,

    g.art_ek_netto,

    g.art_lagereinheit,

    g.art_bezeichnung_2,
    g.art_bezeichnung_3,
    g.art_bezeichnung_4,

    g.art_artikel_ohne_temperaturgrenze,
    g.art_temperaturgrenze_vorhanden,

    g.art_lagertemperatur_von,
    g.art_lagertemperatur_bis,

    g.art_transporttemperatur_von,
    g.art_transporttemperatur_bis,

    g.art_sort_kz,
    g.art_pauschalartikel,
    g.art_pflege_divisor,
    g.art_abc_kategorie,

    g.art_gesperrter_artikel,
    g.art_auswahl_gesperrt,

    g.art_gefahrstoff,

    CASE
        WHEN tos.art_artikelnummer IS NOT NULL THEN 'J'
        ELSE 'N'
    END AS art_tos_verfuegbar

FROM artikel_ids base

LEFT JOIN golden_values g
    ON base.art_artikelnummer = g.art_artikelnummer

LEFT JOIN tos
    ON base.art_artikelnummer = tos.art_artikelnummer