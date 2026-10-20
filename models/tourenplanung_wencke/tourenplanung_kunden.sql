
{{ config(
    materialized = 'table',
    schema = 'tourenplanung'
) }}

WITH kundendaten AS (
    SELECT
        beleg_adress_key,
        adr_nr,
        adr_text,
        adr_strasse,
        adr_plz,
        adr_ort,
        adr_land,
        vertreter_key,
        adr_abc_kunde,
        besuchsberichte_soll,
        besuch_ist,
        letzter_besuch
    FROM {{ ref('gold_wencke_adressen') }}
    WHERE vertreter_key IN (
        '103_36',
        '111_36',
        '114_36',
        '115_36',
        '301_32',
        '307_32',
        '367_32',
        '767_32',
        '201_42',
        '206_42',
        '207_42',
        '209_42'
    )
),

umsatz AS (
    SELECT
        adress_key,
        COALESCE(SUM(rechnung_umsatz_vor_bonus_calc) FILTER (
            WHERE bel_date >= DATE_TRUNC('year', CURRENT_DATE)
              AND bel_date < CURRENT_DATE + INTERVAL '1 day'
        ), 0) AS umsatz_dieses_jahr,

        COALESCE(SUM(rechnung_umsatz_vor_bonus_calc) FILTER (
            WHERE bel_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
              AND bel_date < CURRENT_DATE - INTERVAL '1 year' + INTERVAL '1 day'
        ), 0) AS umsatz_vorjahr_ytd,

        COALESCE(SUM(rohertrag_vor_bonus_calc) FILTER (
            WHERE bel_date >= DATE_TRUNC('year', CURRENT_DATE)
              AND bel_date < CURRENT_DATE + INTERVAL '1 day'
        ), 0) AS rohertrag_dieses_jahr

    FROM {{ ref('gold_wencke_facts_belege_positionen') }}
    WHERE adress_key IN (
        SELECT beleg_adress_key
        FROM kundendaten
    )
    GROUP BY adress_key
),

vertreter AS (
    SELECT
        vertreter_key,
        MAX(ver_vertreternummer_name) AS ver_vertreternummer_name
    FROM {{ ref('gold_wencke_vertreter') }}
    GROUP BY vertreter_key
),

geodaten AS (
    SELECT
        beleg_adress_key,
        latitude,
        longitude
    FROM reporting_tourenplanung.tourenplanung_geocoding
    WHERE geocoding_status = 'OK'
),

basis AS (
    SELECT
        k.beleg_adress_key,
        k.adr_nr,
        k.adr_text,
        k.adr_strasse,
        k.adr_plz,
        k.adr_ort,
        k.adr_land,
        k.vertreter_key,
        v.ver_vertreternummer_name AS vertreter,
        k.adr_abc_kunde,
        k.besuchsberichte_soll,
        k.besuch_ist,
        k.letzter_besuch,
        g.latitude,
        g.longitude,
        COALESCE(u.umsatz_dieses_jahr, 0) AS umsatz_dieses_jahr,
        COALESCE(u.umsatz_vorjahr_ytd, 0) AS umsatz_vorjahr_ytd,
        COALESCE(u.rohertrag_dieses_jahr, 0) AS rohertrag_dieses_jahr

    FROM kundendaten k

    LEFT JOIN umsatz u
        ON k.beleg_adress_key = u.adress_key

    LEFT JOIN vertreter v
        ON k.vertreter_key = v.vertreter_key

    LEFT JOIN geodaten g
        ON k.beleg_adress_key = g.beleg_adress_key
)

SELECT
    *,
    ROUND(
        (
            100.0 * rohertrag_dieses_jahr
            / NULLIF(umsatz_dieses_jahr, 0)
        )::numeric,
        2
    ) AS rohertragsquote_prozent,

    ROUND(
        (
            100.0 * (
                umsatz_dieses_jahr - umsatz_vorjahr_ytd
            )
            / NULLIF(umsatz_vorjahr_ytd, 0)
        )::numeric,
        2
    ) AS umsatzentwicklung_prozent

FROM basis
