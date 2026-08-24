{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}
WITH monthly_product AS (
    SELECT
        DATE_TRUNC('month', bel_date)::date AS monat,
        pos_artikel_nr,
        pos_artikel_text,
        SUM(pos_menge) AS menge,
        SUM(rechnung_umsatz_calc) AS umsatz,
        SUM(rohertrag_vor_bonus_calc) AS rohertrag
    FROM {{ ref('gold_wencke_facts_belege_positionen') }}
    GROUP BY
        DATE_TRUNC('month', bel_date)::date,
        pos_artikel_nr,
        pos_artikel_text
),
monthly_comparison AS (
    SELECT
        monat,
        pos_artikel_nr,
        pos_artikel_text,
        menge,
        umsatz,
        rohertrag,
        LAG(menge) OVER (
            PARTITION BY pos_artikel_nr
            ORDER BY monat
        ) AS menge_vormonat,
        LAG(umsatz) OVER (
            PARTITION BY pos_artikel_nr
            ORDER BY monat
        ) AS umsatz_vormonat,
        LAG(rohertrag) OVER (
            PARTITION BY pos_artikel_nr
            ORDER BY monat
        ) AS rohertrag_vormonat
    FROM monthly_product
)
SELECT
    monat,
    pos_artikel_nr,
    pos_artikel_text,
    menge,
    menge_vormonat,
    menge - menge_vormonat AS menge_delta,
    CASE
        WHEN menge_vormonat <> 0
        THEN (menge - menge_vormonat) / menge_vormonat
    END AS menge_delta_pct,
    umsatz,
    umsatz_vormonat,
    umsatz - umsatz_vormonat AS umsatz_delta,
    CASE
        WHEN umsatz_vormonat <> 0
        THEN (umsatz - umsatz_vormonat) / umsatz_vormonat
    END AS umsatz_delta_pct,
    rohertrag,
    rohertrag_vormonat,
    rohertrag - rohertrag_vormonat AS rohertrag_delta,
    CASE
        WHEN rohertrag_vormonat <> 0
        THEN (rohertrag - rohertrag_vormonat) / rohertrag_vormonat
    END AS rohertrag_delta_pct,
    CASE
        WHEN umsatz <> 0
        THEN rohertrag / umsatz
    END AS marge,
    CASE
        WHEN umsatz_vormonat <> 0
        THEN rohertrag_vormonat / umsatz_vormonat
    END AS marge_vormonat,
    CASE
        WHEN umsatz <> 0
            AND umsatz_vormonat <> 0
        THEN
            (rohertrag / umsatz)
            -
            (rohertrag_vormonat / umsatz_vormonat)
    END AS marge_delta
FROM monthly_comparison
WHERE umsatz_vormonat IS NOT NULL