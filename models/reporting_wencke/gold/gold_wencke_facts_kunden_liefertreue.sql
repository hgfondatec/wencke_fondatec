
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['gold', 'kunden_liefertreue', 'powerbi']
    )
}}

WITH basis AS (
    SELECT
        a.mandant,
        a.wencke_id AS auftrags_wencke_id,
        a.bel_nr,
        a.auftrags_created_at,
        a.auftrags_datum,
        a.auftrags_zeitfenster,
        a.auftrags_datum_final,

        a.adr_nr AS adressnummer,
        CONCAT(a.adr_nr, '_', a.mandant) AS adress_key,

        l.ref_bel_nr,
        l.lieferschein_wencke_id,
        l.lieferschein_nr,
        l.lieferschein_date,
        l.versand_datum,

        -- Lieferfrist: 2 Werktage
        CASE
            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final)
                 BETWEEN 1 AND 3
                THEN a.auftrags_datum_final + 2

            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 4
                THEN a.auftrags_datum_final + 4

            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 5
                THEN a.auftrags_datum_final + 4

            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 6
                THEN a.auftrags_datum_final + 3

            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 7
                THEN a.auftrags_datum_final + 2

            ELSE NULL
        END AS frist_datum,

        -- Zweite Grenze: 7 Werktage
        CASE
            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final)
                 BETWEEN 1 AND 3
                THEN a.auftrags_datum_final + 9

            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final)
                 BETWEEN 4 AND 5
                THEN a.auftrags_datum_final + 11

            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 6
                THEN a.auftrags_datum_final + 10

            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 7
                THEN a.auftrags_datum_final + 9

            ELSE NULL
        END AS frist_datum_7_werktage,

        ver.tour,
        ver.fahrer,
        ver.lkw

    FROM {{ ref('silver_wencke_belege_kundenauftraege') }} AS a

    INNER JOIN {{ ref('silver_wencke_belege_kundenlieferscheine') }} AS l
        ON l.ref_bel_nr = a.bel_nr
       AND l.mandant = a.mandant

    LEFT JOIN {{ ref('bronze_wencke_belege_versand') }} AS ver
        ON ver.wencke_id = a.wencke_id

    WHERE a.auftrags_datum >=
          (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year')::date
      AND a.auftrags_datum <= CURRENT_DATE
),

-- Berechnung der Werktage
basis_mit_werktagen AS (
    SELECT
        b.*,

        -- Abweichung zwischen Frist und Versand
        CASE
            WHEN b.versand_datum IS NULL
                 OR b.frist_datum IS NULL
                THEN NULL

            WHEN b.versand_datum >= b.frist_datum
                THEN abw.werktage_zwischen

            ELSE -abw.werktage_zwischen
        END AS abweichung_werktage,

        -- NEU: Lieferdauer zwischen Auftrag und Versand
        CASE
            WHEN b.auftrags_datum_final IS NULL
                 OR b.versand_datum IS NULL
                THEN NULL

            WHEN b.versand_datum >= b.auftrags_datum_final
                THEN dauer.werktage_zwischen

            ELSE -dauer.werktage_zwischen
        END AS lieferdauer_werktage

    FROM basis AS b

    -- Werktage zwischen Frist und Versand
    CROSS JOIN LATERAL (
        SELECT
            COUNT(*) FILTER (
                WHERE EXTRACT(ISODOW FROM d.tag) BETWEEN 1 AND 5
            )::integer AS werktage_zwischen

        FROM generate_series(
            LEAST(
                b.frist_datum,
                b.versand_datum
            )::timestamp + INTERVAL '1 day',

            GREATEST(
                b.frist_datum,
                b.versand_datum
            )::timestamp,

            INTERVAL '1 day'
        ) AS d(tag)
    ) AS abw

    -- NEU: Werktage zwischen Auftrag und Versand
    CROSS JOIN LATERAL (
        SELECT
            COUNT(*) FILTER (
                WHERE EXTRACT(ISODOW FROM d.tag) BETWEEN 1 AND 5
            )::integer AS werktage_zwischen

        FROM generate_series(
            LEAST(
                b.auftrags_datum_final,
                b.versand_datum
            )::timestamp + INTERVAL '1 day',

            GREATEST(
                b.auftrags_datum_final,
                b.versand_datum
            )::timestamp,

            INTERVAL '1 day'
        ) AS d(tag)
    ) AS dauer
),

liefertreue AS (
    SELECT
        *,

        -- NEU: Lieferdauer in Werktagen statt Kalendertagen
        lieferdauer_werktage AS lieferdauer_tage,

        -- Abweichung zur Frist in Werktagen
        abweichung_werktage AS abweichung_tage,

        -- Liefertreue-Status
        CASE
            WHEN auftrags_datum_final IS NULL
                 OR versand_datum IS NULL
                THEN NULL

            WHEN versand_datum < frist_datum
                THEN 'zu früh'

            WHEN versand_datum > frist_datum_7_werktage
                THEN 'zu spät'

            ELSE 'OK'
        END AS liefertreue_status,

        -- Numerische Kennzahl für Power BI
        CASE
            WHEN auftrags_datum_final IS NULL THEN NULL
            WHEN versand_datum IS NULL THEN NULL
            WHEN versand_datum <= frist_datum THEN 1
            ELSE 0
        END AS liefertreue_48h

    FROM basis_mit_werktagen
)

SELECT
    l.*,

    -- Sortierreihenfolge für Power BI
    CASE
        WHEN l.liefertreue_status = 'zu früh'
            THEN 1

        WHEN l.liefertreue_status = 'OK'
            THEN 2

        WHEN l.liefertreue_status = 'zu spät'
            THEN 3

        ELSE NULL
    END AS statusprio,

    CASE
        WHEN LOWER(TRIM(l.auftrags_zeitfenster::text)) = 'vor 12 uhr' THEN 1

        WHEN LOWER(TRIM(l.auftrags_zeitfenster::text)) = 'nach 12 uhr' THEN 2

        ELSE NULL
    END AS zeitfenster_prio,


    a.adr_text,
    a.adr_vertreter_nr

FROM liefertreue AS l

LEFT JOIN {{ ref('silver_wencke_adressen') }} AS a
    ON l.adress_key = CONCAT(a.adr_nr, '_', a.mandant)
