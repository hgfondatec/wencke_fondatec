
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['abc', 'bestand']
    )
}}
WITH bestand AS (
    SELECT
        mandant_id::text AS mandant,
        artikelnummer::text AS artikelnummer,
        MIN(NULLIF(TRIM(naechster_bestelltermin::text), '')::date) AS naechster_bestelltermin,
        SUM(COALESCE(naechste_bestellmenge, 0)) AS naechste_bestellmenge,
        SUM(COALESCE(lagerbestand, 0)) AS lagerbestand,
        SUM(COALESCE(verfuegbar, 0)) AS verfuegbar,
        SUM(COALESCE(mindestbestand, 0)) AS mindestbestand,
        SUM(
            COALESCE(art_ek_netto, 0) *
            COALESCE(lagerbestand, 0)
        ) AS lagerwert
    FROM {{ ref('silver_wencke_artikel_bestand') }}
    GROUP BY mandant_id, artikelnummer
),
umsatz AS (
    SELECT
        mandant::text AS mandant,
        pos_artikel_nr::text AS artikelnummer,
        SUM(COALESCE(rechnung_umsatz_vor_bonus_calc, 0)) AS jahresumsatz,
        SUM(COALESCE(rechnung_menge_calc, 0)) AS jahresmenge,
        SUM(COALESCE(rohertrag_vor_bonus_calc, 0)) AS jahresrohertrag
    FROM {{ ref('gold_wencke_facts_belege_positionen') }}
    WHERE bel_date >= DATE_TRUNC('year', CURRENT_DATE)
      AND bel_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY mandant, pos_artikel_nr
),
artikel_mandant AS (
    SELECT
        COALESCE(b.mandant, u.mandant) AS mandant,
        COALESCE(b.artikelnummer, u.artikelnummer) AS artikelnummer,
        b.naechster_bestelltermin,
        COALESCE(b.naechste_bestellmenge, 0) AS naechste_bestellmenge,
        COALESCE(b.lagerbestand, 0) AS lagerbestand,
        COALESCE(b.verfuegbar, 0) AS verfuegbar,
        COALESCE(b.mindestbestand, 0) AS mindestbestand,
        COALESCE(b.lagerwert, 0) AS lagerwert,
        COALESCE(u.jahresumsatz, 0) AS jahresumsatz,
        COALESCE(u.jahresmenge, 0) AS jahresmenge,
        COALESCE(u.jahresrohertrag, 0) AS jahresrohertrag
    FROM bestand b
    FULL OUTER JOIN umsatz u
        ON b.mandant = u.mandant
       AND b.artikelnummer = u.artikelnummer
),
artikel_gesamt AS (
    SELECT
        'Gesamt'::text AS mandant,
        artikelnummer,
        MIN(naechster_bestelltermin) AS naechster_bestelltermin,
        SUM(naechste_bestellmenge) AS naechste_bestellmenge,
        SUM(lagerbestand) AS lagerbestand,
        SUM(verfuegbar) AS verfuegbar,
        SUM(mindestbestand) AS mindestbestand,
        SUM(lagerwert) AS lagerwert,
        SUM(jahresumsatz) AS jahresumsatz,
        SUM(jahresmenge) AS jahresmenge,
        SUM(jahresrohertrag) AS jahresrohertrag
    FROM artikel_mandant
    GROUP BY artikelnummer
),
basis AS (
    SELECT * FROM artikel_mandant
    UNION ALL
    SELECT * FROM artikel_gesamt
),
rangfolge AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY mandant
            ORDER BY jahresumsatz DESC, artikelnummer
        ) AS umsatz_rang,
        SUM(GREATEST(jahresumsatz, 0)) OVER (
            PARTITION BY mandant
        ) AS gesamtumsatz,
        SUM(GREATEST(jahresumsatz, 0)) OVER (
            PARTITION BY mandant
            ORDER BY jahresumsatz DESC, artikelnummer
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS umsatz_kumuliert
    FROM basis
),
abc AS (
    SELECT
        *,
        CASE
            WHEN jahresumsatz > 0 THEN
                ROUND((jahresumsatz / NULLIF(gesamtumsatz, 0) * 100)::numeric, 2)
            ELSE 0
        END AS umsatzanteil_prozent,
        CASE
            WHEN jahresumsatz > 0 THEN
                ROUND((umsatz_kumuliert / NULLIF(gesamtumsatz, 0) * 100)::numeric, 2)
            ELSE NULL
        END AS kumulierter_umsatzanteil_prozent,
        CASE
            WHEN jahresumsatz <= 0 THEN 'C'
            WHEN (umsatz_kumuliert - jahresumsatz) / NULLIF(gesamtumsatz, 0) < 0.80 THEN 'A'
            WHEN (umsatz_kumuliert - jahresumsatz) / NULLIF(gesamtumsatz, 0) < 0.95 THEN 'B'
            ELSE 'C'
        END AS abc_klasse
    FROM rangfolge
)
SELECT
    mandant,
    artikelnummer,
    naechster_bestelltermin,
    naechste_bestellmenge,
    lagerbestand,
    verfuegbar,
    mindestbestand,
    lagerwert,
    jahresumsatz,
    jahresmenge,
    jahresrohertrag,
    umsatz_rang,
    gesamtumsatz,
    umsatz_kumuliert,
    umsatzanteil_prozent,
    kumulierter_umsatzanteil_prozent,
    abc_klasse
FROM abc
