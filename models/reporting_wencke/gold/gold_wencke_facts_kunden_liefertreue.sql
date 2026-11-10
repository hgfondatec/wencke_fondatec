
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
        a.auftrags_nr,
        a.auftrags_created_at,
        a.auftrags_datum,
        a.auftrags_zeitfenster,
        a.auftrags_datum_final,

        a.adr_nr AS adressnummer,
        CONCAT(a.adr_nr, '_', a.mandant) AS adress_key,

        l.ref_bel_nr,
        l.lieferschein_wencke_id,
        l.lieferschein_nr,
        l.lieferschein_datum,
        l.versand_datum,

        -- Frist: zwei Werktage ab finalem Auftragsdatum
        CASE
            -- Montag bis Mittwoch -> +2 Tage
            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final)
                 BETWEEN 1 AND 3
                THEN a.auftrags_datum_final + 2

            -- Donnerstag -> Montag
            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 4
                THEN a.auftrags_datum_final + 4

            -- Freitag -> Dienstag
            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 5
                THEN a.auftrags_datum_final + 4

            -- Samstag -> Mittwoch
            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 6
                THEN a.auftrags_datum_final + 4

            -- Sonntag -> Mittwoch
            WHEN EXTRACT(ISODOW FROM a.auftrags_datum_final) = 7
                THEN a.auftrags_datum_final + 3

            ELSE NULL
        END AS frist_datum

    FROM {{ ref('silver_wencke_belege_kundenauftraege') }} AS a

    LEFT JOIN {{ ref('silver_wencke_belege_kundenlieferscheine') }} AS l
        ON a.wencke_id = l.auftrags_wencke_id
       AND a.mandant = l.mandant
       AND a.adr_nr = l.adr_nr

    -- Dynamischer Filter: aktuelles und vorheriges Kalenderjahr
    WHERE a.auftrags_datum >=
          (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year')::date
      AND a.auftrags_datum <= CURRENT_DATE
),

liefertreue AS (
    SELECT
        *,

        -- Tatsächliche Lieferdauer in Kalendertagen
        versand_datum - auftrags_datum_final
            AS lieferdauer_tage,

        -- Abweichung gegenüber der Frist
        versand_datum - frist_datum
            AS abweichung_tage,

        -- Liefertreue-Status
        CASE
            WHEN auftrags_datum_final IS NULL
                THEN 'Auftragsdatum fehlt'

            WHEN versand_datum IS NULL
                 AND CURRENT_DATE <= frist_datum
                THEN 'Offen innerhalb Frist'

            WHEN versand_datum IS NULL
                 AND CURRENT_DATE > frist_datum
                THEN 'Offen überfällig'

            WHEN versand_datum <= frist_datum
                THEN 'Pünktlich'

            ELSE 'Verspätet'
        END AS liefertreue_status,

        -- Numerische Kennzahl für Power BI
        CASE
            WHEN auftrags_datum_final IS NULL THEN NULL
            WHEN versand_datum IS NULL THEN NULL
            WHEN versand_datum <= frist_datum THEN 1
            ELSE 0
        END AS liefertreue_48h

    FROM basis
)

SELECT
    l.*,
    a.adr_text,
    a.adr_vertreter_nr

FROM liefertreue AS l

LEFT JOIN {{ ref('silver_wencke_adressen') }} AS a
    ON l.adress_key = CONCAT(a.adr_nr, '_', a.mandant)
