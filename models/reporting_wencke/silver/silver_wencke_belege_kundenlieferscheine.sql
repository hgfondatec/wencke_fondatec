
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['silver', 'kunden_liefertreue']
    )
}}

WITH auftraege AS (
    SELECT DISTINCT
        b.wencke_id,
        b.mandant,
        b.bel_nr AS auftrags_nr,
        b.bel_lieferschein_nr AS lieferschein_nr,

        CASE
            WHEN b.bel_project_nr IS NOT NULL THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END AS adr_nr

    FROM {{ ref('bronze_wencke_belege') }} AS b
    WHERE b.bel_art = 'A'
),

lieferscheine AS (
    SELECT DISTINCT
        b.wencke_id AS lieferschein_wencke_id,
        b.mandant,
        b.bel_nr AS lieferschein_nr,
        b.bel_date::date AS lieferschein_datum,

        CASE
            WHEN b.bel_project_nr IS NOT NULL THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END AS adr_nr

    FROM {{ ref('bronze_wencke_belege') }} AS b
    WHERE b.bel_art = 'L'
)

SELECT DISTINCT
    a.wencke_id AS auftrags_wencke_id,
    a.mandant,
    a.auftrags_nr,
    a.adr_nr,
    a.lieferschein_nr AS ref_bel_nr,

    l.lieferschein_wencke_id,
    l.lieferschein_nr,
    l.lieferschein_datum,

    -- Versand erfolgt einen Tag nach Lieferscheindatum
    l.lieferschein_datum + 1 AS versand_datum

FROM auftraege AS a

LEFT JOIN lieferscheine AS l
    ON a.lieferschein_nr = l.lieferschein_nr
   AND a.mandant = l.mandant
   AND a.adr_nr = l.adr_nr
