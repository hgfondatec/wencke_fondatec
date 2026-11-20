{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['gold', 'nachlieferung', 'wareneingang']
    )
}}

WITH lieferscheine AS (
    SELECT
        mandant,
        adr_nr,
        ref_bel_nr,
        COUNT(DISTINCT lieferschein_wencke_id) AS anzahl_lieferscheine,
        COUNT(*) FILTER (WHERE bel_nl_nachlieferung = 'TL' or bel_nl_nachlieferung is null) AS anzahl_tl
    FROM {{ ref('silver_wencke_belege_kundenlieferscheine') }}
    GROUP BY mandant, adr_nr, ref_bel_nr
),
basis AS (
    SELECT
        b.mandant,
        DATE_TRUNC('month', b.bel_date)::date AS monat,
        l.adr_nr,
        COALESCE(l.anzahl_lieferscheine, 0) AS gesamt_lieferungen,
        CASE
            WHEN b.mandant = '42' THEN
                GREATEST(COALESCE(l.anzahl_lieferscheine, 0) - COALESCE(l.anzahl_tl, 0), 0)
            ELSE
                GREATEST(COALESCE(l.anzahl_lieferscheine, 0) - 1, 0)
        END AS nl_lieferung
    FROM {{ ref('silver_wencke_belege_kundenauftraege') }} AS b
    LEFT JOIN lieferscheine AS l
        ON l.ref_bel_nr = b.bel_nr
        AND l.mandant = b.mandant
)
SELECT
    mandant,
    monat,
    adr_nr,
    SUM(nl_lieferung) AS nl_lieferung,
    SUM(gesamt_lieferungen) AS gesamt_lieferungen,
    ROUND(100.0 * SUM(nl_lieferung) / NULLIF(SUM(gesamt_lieferungen), 0), 2) AS nl_quote_prozent
FROM basis
GROUP BY mandant, monat, adr_nr