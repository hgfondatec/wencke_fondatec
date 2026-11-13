
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
        b.bel_nr,
        b.bel_created_at::timestamp AS auftrags_created_at,
        CASE
            WHEN b.bel_project_nr IS NOT NULL THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END AS adr_nr
    FROM {{ ref('bronze_wencke_belege') }} AS b
    WHERE b.bel_art = 'A'
),

auftraege_berechnet AS (
    SELECT
        a.*,

        a.auftrags_created_at::date AS auftrags_datum,

        CASE
            WHEN a.auftrags_created_at::time < TIME '12:00:00'
                THEN 'Vor 12 Uhr'
            ELSE 'Ab 12 Uhr'
        END AS auftrags_zeitfenster,

        CASE
            -- Samstag -> Montag
            WHEN EXTRACT(ISODOW FROM a.auftrags_created_at) = 6
                THEN a.auftrags_created_at::date + 2

            -- Sonntag -> Montag
            WHEN EXTRACT(ISODOW FROM a.auftrags_created_at) = 7
                THEN a.auftrags_created_at::date + 1

            -- Freitag ab 12 Uhr -> Montag
            WHEN EXTRACT(ISODOW FROM a.auftrags_created_at) = 5
                 AND a.auftrags_created_at::time >= TIME '12:00:00'
                THEN a.auftrags_created_at::date + 3

            -- Montag bis Donnerstag ab 12 Uhr
            WHEN a.auftrags_created_at::time >= TIME '12:00:00'
                THEN a.auftrags_created_at::date + 1

            -- Vor 12 Uhr -> gleicher Tag
            ELSE a.auftrags_created_at::date
        END AS auftrags_datum_final

    FROM auftraege AS a
)

SELECT *
FROM auftraege_berechnet
