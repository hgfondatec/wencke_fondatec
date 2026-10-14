
{{ config(
    materialized = 'table',
    schema = 'tourenplanung'
) }}

WITH kunden AS (
    SELECT *
    FROM {{ ref('tourenplanung_prioritaet') }}
),

touren AS (
    SELECT
        tour_id,
        vertreter_key,
        tour,
        anzahl_kunden,
        fahrzeit_minuten,
        besuchszeit_minuten,
        gesamtdauer_minuten,
        score_summe,
        route_geojson
    FROM reporting_tourenplanung.tourenplanung_tour
),

stopps AS (
    SELECT
        tour_id,
        tour_stop_id,
        stopp_nr,
        beleg_adress_key,
        ankunft_minuten
    FROM reporting_tourenplanung.tourenplanung_tour_stop
),

radius AS (
    SELECT
        tour_id,
        beleg_adress_key,
        entfernung_route_km,
        ist_im_10km_radius
    FROM reporting_tourenplanung.tourenplanung_kunden_radius
),

kunden_daten AS (
    SELECT
        t.tour_id,
        k.vertreter_key,
        k.vertreter,
        t.tour,

        k.beleg_adress_key,
        k.adr_nr,
        k.adr_text,
        k.adr_strasse,
        k.adr_plz,
        k.adr_ort,
        k.adr_land,
        k.latitude,
        k.longitude,

        k.umsatz_dieses_jahr,
        k.umsatz_vorjahr_ytd,
        k.rohertrag_dieses_jahr,
        k.rohertragsquote_prozent,
        k.umsatzentwicklung_prozent,

        k.adr_abc_kunde,
        k.besuchsberichte_soll,
        k.besuch_ist,
        k.letzter_besuch,

        k.score_umsatz,
        k.score_rohertrag,
        k.score_entwicklung,
        k.score_besuch,
        k.score_letzter_besuch,
        k.score_abc,
        k.score_gesamt,
        k.prioritaet_rang,

        CASE
            WHEN s.tour_stop_id IS NOT NULL THEN 1
            ELSE 0
        END AS ist_tourkunde,

        s.stopp_nr,
        s.ankunft_minuten,

        t.anzahl_kunden AS tour_anzahl_kunden,
        t.fahrzeit_minuten AS tour_fahrzeit_minuten,
        t.besuchszeit_minuten AS tour_besuchszeit_minuten,
        t.gesamtdauer_minuten AS tour_gesamtdauer_minuten,
        t.score_summe AS tour_score_summe,
        t.route_geojson,

        r.entfernung_route_km,
        COALESCE(r.ist_im_10km_radius, 0)
            AS ist_im_10km_radius,

        CASE
            WHEN s.tour_stop_id IS NOT NULL
                THEN 'Tourkunde'
            WHEN COALESCE(r.ist_im_10km_radius, 0) = 1
                THEN 'Kunde in der Nähe'
            ELSE 'Weiterer Kunde'
        END::text AS kunden_status,

        'Kunde'::text AS datentyp,

        NULL::text AS pfad_id,

        NULL::integer AS punkt_reihenfolge

    FROM kunden k

    LEFT JOIN touren t
        ON t.vertreter_key = k.vertreter_key

    LEFT JOIN stopps s
        ON s.tour_id = t.tour_id
       AND s.beleg_adress_key = k.beleg_adress_key

    LEFT JOIN radius r
        ON r.tour_id = t.tour_id
       AND r.beleg_adress_key = k.beleg_adress_key
),

routen_daten AS (
    SELECT
        t.tour_id,
        t.vertreter_key::text AS vertreter_key,
        NULL::text AS vertreter,
        t.tour,

        NULL::text AS beleg_adress_key,
        NULL::varchar AS adr_nr,
        NULL::text AS adr_text,
        NULL::varchar AS adr_strasse,
        NULL::varchar AS adr_plz,
        NULL::varchar AS adr_ort,
        NULL::varchar AS adr_land,

        rp.latitude::double precision AS latitude,
        rp.longitude::double precision AS longitude,

        NULL::numeric AS umsatz_dieses_jahr,
        NULL::numeric AS umsatz_vorjahr_ytd,
        NULL::numeric AS rohertrag_dieses_jahr,
        NULL::numeric AS rohertragsquote_prozent,
        NULL::numeric AS umsatzentwicklung_prozent,

        NULL::varchar AS adr_abc_kunde,
        NULL::smallint AS besuchsberichte_soll,
        NULL::smallint AS besuch_ist,
        NULL::date AS letzter_besuch,

        NULL::numeric AS score_umsatz,
        NULL::numeric AS score_rohertrag,
        NULL::numeric AS score_entwicklung,
        NULL::numeric AS score_besuch,
        NULL::numeric AS score_letzter_besuch,
        NULL::numeric AS score_abc,
        NULL::numeric AS score_gesamt,
        NULL::bigint AS prioritaet_rang,

        0 AS ist_tourkunde,

        NULL::integer AS stopp_nr,
        NULL::numeric AS ankunft_minuten,

        t.anzahl_kunden AS tour_anzahl_kunden,
        t.fahrzeit_minuten AS tour_fahrzeit_minuten,
        t.besuchszeit_minuten AS tour_besuchszeit_minuten,
        t.gesamtdauer_minuten AS tour_gesamtdauer_minuten,
        t.score_summe AS tour_score_summe,
        t.route_geojson,

        NULL::double precision AS entfernung_route_km,
        0 AS ist_im_10km_radius,

        'Route'::text AS kunden_status,
        'Route'::text AS datentyp,

        rp.pfad_id::text AS pfad_id,
        rp.punkt_reihenfolge::integer AS punkt_reihenfolge

    FROM reporting_tourenplanung.tourenplanung_route_punkte rp

    JOIN touren t
        ON t.tour_id = rp.tour_id
)

SELECT *
FROM kunden_daten

UNION ALL

SELECT *
FROM routen_daten
