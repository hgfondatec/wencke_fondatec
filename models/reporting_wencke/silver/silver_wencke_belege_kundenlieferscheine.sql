
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['silver', 'kunden_liefertreue']
    )
}}

WITH referenzen AS (
    SELECT DISTINCT
        wencke_id,
        ref_bel_nr
    FROM {{ ref('bronze_wencke_belege_referenzen') }}
    WHERE ref_typ = 'uebernahme_auftrag'
      AND ref_bel_nr IS NOT NULL
),

lieferscheine AS (
    SELECT DISTINCT
        b.wencke_id,
        b.mandant,
        b.bel_nr AS lieferschein_nr,
        b.bel_date::date AS lieferschein_date,

        CASE
            WHEN b.bel_project_nr IS NOT NULL
                THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END AS adr_nr

    FROM {{ ref('bronze_wencke_belege') }} AS b

    WHERE b.bel_art = 'L'
),

zugeordnete_lieferscheine AS (
    SELECT
        l.mandant,
        l.wencke_id AS lieferschein_wencke_id,
        l.lieferschein_nr,
        l.lieferschein_date,
        l.adr_nr,
        r.ref_bel_nr,

        ROW_NUMBER() OVER (
            PARTITION BY
                l.mandant,
                r.ref_bel_nr
            ORDER BY
                l.lieferschein_date ASC NULLS LAST,
                l.wencke_id ASC
        ) AS rn

    FROM referenzen AS r

    INNER JOIN lieferscheine AS l
        ON l.wencke_id = r.wencke_id
)

SELECT
    mandant,
    lieferschein_wencke_id,
    lieferschein_nr,
    lieferschein_date,

    -- Versand: 1 Werktag nach Lieferscheindatum
    -- Montag bis Freitag als Werktage
    CASE
        -- Montag bis Donnerstag -> Folgetag
        WHEN EXTRACT(ISODOW FROM lieferschein_date)
             BETWEEN 1 AND 4
            THEN lieferschein_date + 1

        -- Freitag -> Montag
        WHEN EXTRACT(ISODOW FROM lieferschein_date) = 5
            THEN lieferschein_date + 3

        -- Samstag -> Montag
        WHEN EXTRACT(ISODOW FROM lieferschein_date) = 6
            THEN lieferschein_date + 2

        -- Sonntag -> Montag
        WHEN EXTRACT(ISODOW FROM lieferschein_date) = 7
            THEN lieferschein_date + 1

        ELSE NULL
    END AS versand_datum,

    adr_nr,
    ref_bel_nr

FROM zugeordnete_lieferscheine

WHERE rn = 1
