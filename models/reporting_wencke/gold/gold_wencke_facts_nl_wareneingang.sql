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
        lieferschein_wencke_id,
        lieferschein_nr,
        lieferschein_date,
        versand_art,

        ROW_NUMBER() OVER (
            PARTITION BY
                mandant,
                adr_nr,
                ref_bel_nr
            ORDER BY
                lieferschein_date,
                lieferschein_nr,
                lieferschein_wencke_id
        ) AS lieferung_reihenfolge

    FROM {{ ref('silver_wencke_belege_lieferscheine') }}

),

basis AS (

    SELECT DISTINCT
        b.mandant,
        DATE_TRUNC('month', b.bel_date)::date AS monat,

        l.adr_nr,
        l.ref_bel_nr,
        l.lieferschein_wencke_id,
        l.lieferschein_nr,
        l.lieferschein_date,
        l.versand_art,
        l.lieferung_reihenfolge,

        p.pos_artikel_nr,

        CONCAT(
            p.pos_artikel_nr,
            '_',
            b.mandant
        ) AS artikel_key,

        1 AS gesamt_lieferungen,

        CASE
            WHEN l.lieferung_reihenfolge > 1 THEN 1
            ELSE 0
        END AS nl_lieferung

    FROM {{ ref('silver_wencke_belege_bestellungen') }} AS b

    INNER JOIN lieferscheine AS l
        ON l.ref_bel_nr = b.bel_nr
        AND l.mandant = b.mandant

    INNER JOIN {{ ref('silver_wencke_belege_positionen_gesamt') }} AS p
        ON l.lieferschein_wencke_id = p.bel_wencke_id

    WHERE p.pos_artikel_nr IS NOT NULL
        AND TRIM(p.pos_artikel_nr::text) <> ''

)

SELECT *
FROM basis