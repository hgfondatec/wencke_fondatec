
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['silver', 'nachlieferung', 'liefertermintreue']
    )
}}

WITH referenzen AS (
    SELECT DISTINCT
        wencke_id,
        ref_bel_nr
    FROM {{ ref('bronze_wencke_belege_referenzen') }}
    WHERE ref_typ = 'uebernahme_angebot'
      AND ref_bel_nr IS NOT NULL
),
lieferscheine AS (
    SELECT DISTINCT
        b.wencke_id,
        b.mandant,
        b.bel_nr AS lieferschein_nr,
        b.bel_date AS lieferschein_date,
        CASE
            WHEN b.bel_project_nr IS NOT NULL THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END AS adr_nr
    FROM {{ ref('bronze_wencke_belege') }} AS b
    WHERE b.bel_art = 'l'
)
SELECT DISTINCT
    l.mandant,
    l.wencke_id AS lieferschein_wencke_id,
    l.lieferschein_nr,
    l.lieferschein_date,
    l.adr_nr,
    r.ref_bel_nr
FROM referenzen AS r
INNER JOIN lieferscheine AS l
    ON l.wencke_id = r.wencke_id
