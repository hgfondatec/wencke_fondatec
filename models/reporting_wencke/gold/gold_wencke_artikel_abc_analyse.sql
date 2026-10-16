
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
        SUM(COALESCE(lagerbestand, 0)) AS lagerbestand,
        SUM(COALESCE(verfuegbar, 0)) AS verfuegbar,
        SUM(COALESCE(mindestbestand, 0)) AS mindestbestand
    FROM {{ ref('silver_wencke_artikel_bestand') }}
    GROUP BY
        mandant_id,
        artikelnummer
),

umsatz AS (
    SELECT
        mandant::text AS mandant,
        pos_artikel_nr::text AS artikelnummer,
        SUM(COALESCE(rechnung_umsatz_vor_bonus_calc, 0)) AS jahresumsatz,
        SUM(COALESCE(rechnung_menge_calc, 0)) AS jahresmenge,
        SUM(COALESCE(rohertrag_vor_bonus_calc, 0)) AS jahresrohertrag
    FROM {{ ref('gold_wencke_facts_belege_positionen_master') }} 
    WHERE bel_art IN ('R', 'G')
      AND bel_date >= DATE_TRUNC('year', CURRENT_DATE)
      AND bel_date < CURRENT_DATE + INTERVAL '1 day'
      AND pos_artikel_nr IS NOT NULL
    GROUP BY
        mandant,
        pos_artikel_nr
),

artikel_mandant AS (
    SELECT
        COALESCE(b.mandant, u.mandant) AS mandant,
        COALESCE(b.artikelnummer, u.artikelnummer) AS artikelnummer,
        COALESCE(b.lagerbestand, 0) AS lagerbestand,
        COALESCE(b.verfuegbar, 0) AS verfuegbar,
        COALESCE(b.mindestbestand, 0) AS mindestbestand,
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
        SUM(lagerbestand) AS lagerbestand,
        SUM(verfuegbar) AS verfuegbar,
        SUM(mindestbestand) AS mindestbestand,
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
        SUM(jahresumsatz) OVER (
            PARTITION BY mandant
        ) AS gesamtumsatz,
        SUM(jahresumsatz) OVER (
            PARTITION BY mandant
            ORDER BY jahresumsatz DESC, artikelnummer
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS umsatz_kumuliert
    FROM basis
    WHERE jahresumsatz > 0
),

abc AS (
    SELECT
        *,
        ROUND(
            (jahresumsatz / NULLIF(gesamtumsatz, 0) * 100)::numeric,
            2
        ) AS umsatzanteil_prozent,
        ROUND(
            (umsatz_kumuliert / NULLIF(gesamtumsatz, 0) * 100)::numeric,
            2
        ) AS kumulierter_umsatzanteil_prozent,
        CASE
            WHEN (umsatz_kumuliert - jahresumsatz)
                / NULLIF(gesamtumsatz, 0) < 0.80 THEN 'A'
            WHEN (umsatz_kumuliert - jahresumsatz)
                / NULLIF(gesamtumsatz, 0) < 0.95 THEN 'B'
            ELSE 'C'
        END AS abc_klasse
    FROM rangfolge
)

SELECT
    mandant,
    artikelnummer,
    lagerbestand,
    verfuegbar,
    mindestbestand,
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
