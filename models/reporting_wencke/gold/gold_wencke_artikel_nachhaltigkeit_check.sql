
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['bestand']
    )
}}

WITH basis AS (
    SELECT
        art_artikelnummer,
        hat_bestand,

        COALESCE(verfuegbar_39, 0) = 1 AS verfuegbar_39,
        COALESCE(verfuegbar_32, 0) = 1 AS verfuegbar_32,
        COALESCE(verfuegbar_42, 0) = 1 AS verfuegbar_42,
        COALESCE(verfuegbar_36, 0) = 1 AS verfuegbar_36,

        art_nachhaltiger_artikel_39,
        art_nachhaltiger_artikel_32,
        art_nachhaltiger_artikel_42,
        art_nachhaltiger_artikel_36,

        art_nh_blauer_engel_39,
        art_nh_blauer_engel_32,
        art_nh_blauer_engel_42,
        art_nh_blauer_engel_36,

        art_nh_eu_ecolabel_39,
        art_nh_eu_ecolabel_32,
        art_nh_eu_ecolabel_42,
        art_nh_eu_ecolabel_36,

        art_nh_nordic_ecolabel_39,
        art_nh_nordic_ecolabel_32,
        art_nh_nordic_ecolabel_42,
        art_nh_nordic_ecolabel_36,

        art_nh_fsc_39,
        art_nh_fsc_32,
        art_nh_fsc_42,
        art_nh_fsc_36,

        art_nh_sonstiges_39,
        art_nh_sonstiges_32,
        art_nh_sonstiges_42,
        art_nh_sonstiges_36,

        art_nh_sonstiges_name_39,
        art_nh_sonstiges_name_32,
        art_nh_sonstiges_name_42,
        art_nh_sonstiges_name_36

    FROM {{ ref('gold_wencke_artikel_check') }}
),

-- Nachhaltigkeitsmerkmale in Kategoriezeilen umwandeln
kategorien AS (
    SELECT
        b.art_artikelnummer,
        b.hat_bestand,

        b.verfuegbar_39,
        b.verfuegbar_32,
        b.verfuegbar_42,
        b.verfuegbar_36,

        k.kategorie,
        k.sortierung,

        k.wert_39,
        k.wert_32,
        k.wert_42,
        k.wert_36

    FROM basis b

    CROSS JOIN LATERAL (
        VALUES
            ('Nachhaltiger Artikel', 1,
                b.art_nachhaltiger_artikel_39::text,
                b.art_nachhaltiger_artikel_32::text,
                b.art_nachhaltiger_artikel_42::text,
                b.art_nachhaltiger_artikel_36::text),

            ('Blauer Engel', 2,
                b.art_nh_blauer_engel_39::text,
                b.art_nh_blauer_engel_32::text,
                b.art_nh_blauer_engel_42::text,
                b.art_nh_blauer_engel_36::text),

            ('EU Ecolabel', 3,
                b.art_nh_eu_ecolabel_39::text,
                b.art_nh_eu_ecolabel_32::text,
                b.art_nh_eu_ecolabel_42::text,
                b.art_nh_eu_ecolabel_36::text),

            ('Nordic Ecolabel', 4,
                b.art_nh_nordic_ecolabel_39::text,
                b.art_nh_nordic_ecolabel_32::text,
                b.art_nh_nordic_ecolabel_42::text,
                b.art_nh_nordic_ecolabel_36::text),

            ('FSC', 5,
                b.art_nh_fsc_39::text,
                b.art_nh_fsc_32::text,
                b.art_nh_fsc_42::text,
                b.art_nh_fsc_36::text),

            ('Sonstiges', 6,
                b.art_nh_sonstiges_39::text,
                b.art_nh_sonstiges_32::text,
                b.art_nh_sonstiges_42::text,
                b.art_nh_sonstiges_36::text),

            ('Sonstiges Bezeichnung', 7,
                b.art_nh_sonstiges_name_39::text,
                b.art_nh_sonstiges_name_32::text,
                b.art_nh_sonstiges_name_42::text,
                b.art_nh_sonstiges_name_36::text)

    ) AS k(
        kategorie,
        sortierung,
        wert_39,
        wert_32,
        wert_42,
        wert_36
    )
),

-- Positive Nachhaltigkeitsmerkmale ermitteln
-- Nur "trifft zu" zählt als positiv.
-- Bei Sonstiges Bezeichnung zählt ein konkreter Text.
normalisiert AS (
    SELECT
        art_artikelnummer,
        hat_bestand,

        verfuegbar_39,
        verfuegbar_32,
        verfuegbar_42,
        verfuegbar_36,

        kategorie,
        sortierung,

        CASE
            WHEN kategorie = 'Sonstiges Bezeichnung'
            THEN
                NULLIF(TRIM(wert_39), '') IS NOT NULL
                AND LOWER(TRIM(wert_39)) NOT IN (
                    'nicht klassifiziert',
                    'nicht klassifziert',
                    'trifft nicht zu'
                )
            ELSE
                LOWER(TRIM(COALESCE(wert_39, '')))
                    IN ('trifft zu', 'true', 't', '1')
        END AS wert_39,

        CASE
            WHEN kategorie = 'Sonstiges Bezeichnung'
            THEN
                NULLIF(TRIM(wert_32), '') IS NOT NULL
                AND LOWER(TRIM(wert_32)) NOT IN (
                    'nicht klassifiziert',
                    'nicht klassifziert',
                    'trifft nicht zu'
                )
            ELSE
                LOWER(TRIM(COALESCE(wert_32, '')))
                    IN ('trifft zu', 'true', 't', '1')
        END AS wert_32,

        CASE
            WHEN kategorie = 'Sonstiges Bezeichnung'
            THEN
                NULLIF(TRIM(wert_42), '') IS NOT NULL
                AND LOWER(TRIM(wert_42)) NOT IN (
                    'nicht klassifiziert',
                    'nicht klassifziert',
                    'trifft nicht zu'
                )
            ELSE
                LOWER(TRIM(COALESCE(wert_42, '')))
                    IN ('trifft zu', 'true', 't', '1')
        END AS wert_42,

        CASE
            WHEN kategorie = 'Sonstiges Bezeichnung'
            THEN
                NULLIF(TRIM(wert_36), '') IS NOT NULL
                AND LOWER(TRIM(wert_36)) NOT IN (
                    'nicht klassifiziert',
                    'nicht klassifziert',
                    'trifft nicht zu'
                )
            ELSE
                LOWER(TRIM(COALESCE(wert_36, '')))
                    IN ('trifft zu', 'true', 't', '1')
        END AS wert_36

    FROM kategorien
),

-- Pro Artikel und Kategorie genau eine Zeile
artikel_kategorien AS (
    SELECT
        art_artikelnummer,
        kategorie,
        sortierung,

        BOOL_OR(
            LOWER(TRIM(COALESCE(hat_bestand::text, '')))
                IN ('hat bestand', 'true', 't', '1', 'ja', 'x')
        ) AS hat_bestand,

        BOOL_OR(verfuegbar_39) AS verfuegbar_39,
        BOOL_OR(verfuegbar_32) AS verfuegbar_32,
        BOOL_OR(verfuegbar_42) AS verfuegbar_42,
        BOOL_OR(verfuegbar_36) AS verfuegbar_36,

        BOOL_OR(wert_39 AND verfuegbar_39) AS wert_39,
        BOOL_OR(wert_32 AND verfuegbar_32) AS wert_32,
        BOOL_OR(wert_42 AND verfuegbar_42) AS wert_42,
        BOOL_OR(wert_36 AND verfuegbar_36) AS wert_36

    FROM normalisiert

    GROUP BY
        art_artikelnummer,
        kategorie,
        sortierung
),

-- Gesamt Nachhaltig aus allen Einzelmerkmalen
gesamt AS (
    SELECT
        art_artikelnummer,
        'Gesamt Nachhaltig' AS kategorie,
        0 AS sortierung,

        BOOL_OR(hat_bestand) AS hat_bestand,

        BOOL_OR(verfuegbar_39) AS verfuegbar_39,
        BOOL_OR(verfuegbar_32) AS verfuegbar_32,
        BOOL_OR(verfuegbar_42) AS verfuegbar_42,
        BOOL_OR(verfuegbar_36) AS verfuegbar_36,

        BOOL_OR(wert_39) AS wert_39,
        BOOL_OR(wert_32) AS wert_32,
        BOOL_OR(wert_42) AS wert_42,
        BOOL_OR(wert_36) AS wert_36

    FROM artikel_kategorien

    GROUP BY art_artikelnummer
),

vereint AS (
    SELECT * FROM artikel_kategorien

    UNION ALL

    SELECT * FROM gesamt
),

-- Mindestens ein verfügbarer Mandant hat ein X
-- in der jeweiligen Kategorie
bewertung AS (
    SELECT
        v.*,

        (
            v.wert_39
            OR v.wert_32
            OR v.wert_42
            OR v.wert_36
        ) AS mindestens_ein_merkmal,

        (
            v.verfuegbar_39
            OR v.verfuegbar_32
            OR v.verfuegbar_42
            OR v.verfuegbar_36
        ) AS artikel_verfuegbar

    FROM vereint v
),

-- Nachhaltigkeitsabdeckung auf Artikelebene
abdeckung AS (
    SELECT
        art_artikelnummer,

        verfuegbar_39,
        verfuegbar_32,
        verfuegbar_42,
        verfuegbar_36,

        wert_39 AS nachhaltig_39,
        wert_32 AS nachhaltig_32,
        wert_42 AS nachhaltig_42,
        wert_36 AS nachhaltig_36

    FROM gesamt
),

-- Umsatz je Artikel für aktuelles Kalenderjahr
umsatz AS (
    SELECT
        pos_artikel_nr::text AS artikelnummer,

        SUM(
            COALESCE(rechnung_umsatz_vor_bonus_calc, 0)
        ) AS jahresumsatz,

        SUM(
            COALESCE(rechnung_menge_calc, 0)
        ) AS jahresmenge,

        SUM(
            COALESCE(rohertrag_vor_bonus_calc, 0)
        ) AS jahresrohertrag

    FROM {{ ref('gold_wencke_facts_belege_positionen') }}

    WHERE bel_date >= DATE_TRUNC('year', CURRENT_DATE)
      AND bel_date < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
      AND mandant::text IN ('39', '32', '42', '36')

    GROUP BY pos_artikel_nr::text
),

final AS (
    SELECT
        b.art_artikelnummer AS artikelnummer,
        b.kategorie,

        -- Glasofix
        CASE
            WHEN NOT b.verfuegbar_39 THEN NULL
            WHEN b.wert_39 THEN 'X'
            WHEN b.mindestens_ein_merkmal THEN 'Fehlt'
            ELSE NULL
        END AS glasofix,

        -- Lloyd
        CASE
            WHEN NOT b.verfuegbar_32 THEN NULL
            WHEN b.wert_32 THEN 'X'
            WHEN b.mindestens_ein_merkmal THEN 'Fehlt'
            ELSE NULL
        END AS lloyd,

        -- VMS
        CASE
            WHEN NOT b.verfuegbar_42 THEN NULL
            WHEN b.wert_42 THEN 'X'
            WHEN b.mindestens_ein_merkmal THEN 'Fehlt'
            ELSE NULL
        END AS vms,

        -- Nonne
        CASE
            WHEN NOT b.verfuegbar_36 THEN NULL
            WHEN b.wert_36 THEN 'X'
            WHEN b.mindestens_ein_merkmal THEN 'Fehlt'
            ELSE NULL
        END AS nonne,

        -- Bestand
        CASE
            WHEN b.hat_bestand THEN 'Ja'
            ELSE 'Nein'
        END AS bestand,

        -- Verfügbarkeit
        b.verfuegbar_39 AS verfuegbar_glasofix,
        b.verfuegbar_32 AS verfuegbar_lloyd,
        b.verfuegbar_42 AS verfuegbar_vms,
        b.verfuegbar_36 AS verfuegbar_nonne,

        -- Nachhaltigkeitsabdeckung
        CASE
            WHEN (
                (NOT a.verfuegbar_39 OR a.nachhaltig_39)
                AND (NOT a.verfuegbar_32 OR a.nachhaltig_32)
                AND (NOT a.verfuegbar_42 OR a.nachhaltig_42)
                AND (NOT a.verfuegbar_36 OR a.nachhaltig_36)
            )
            THEN 'Vollständig'

            WHEN NOT (
                a.nachhaltig_39
                OR a.nachhaltig_32
                OR a.nachhaltig_42
                OR a.nachhaltig_36
            )
            THEN 'Keine Abdeckung'

            ELSE CONCAT(
                'Nur ',
                CONCAT_WS(' + ',
                    CASE WHEN a.nachhaltig_39 THEN 'Glasofix' END,
                    CASE WHEN a.nachhaltig_32 THEN 'Lloyd' END,
                    CASE WHEN a.nachhaltig_42 THEN 'VMS' END,
                    CASE WHEN a.nachhaltig_36 THEN 'Nonne' END
                )
            )
        END AS nachhaltigkeit_abdeckung,

        -- Handlungsbedarf:
        -- Mindestens ein X und ein Fehlt
        -- bei verfügbaren Mandanten
        CASE
            WHEN b.mindestens_ein_merkmal
                AND (
                    (b.verfuegbar_39 AND NOT b.wert_39)
                    OR (b.verfuegbar_32 AND NOT b.wert_32)
                    OR (b.verfuegbar_42 AND NOT b.wert_42)
                    OR (b.verfuegbar_36 AND NOT b.wert_36)
                )
            THEN 'Ja'
            ELSE 'Nein'
        END AS nachhaltigkeit_handlungsbedarf,

        -- Umsatzkennzahlen
        COALESCE(u.jahresumsatz, 0) AS jahresumsatz,
        COALESCE(u.jahresmenge, 0) AS jahresmenge,
        COALESCE(u.jahresrohertrag, 0) AS jahresrohertrag,

        b.sortierung

    FROM bewertung b

    INNER JOIN abdeckung a
        ON b.art_artikelnummer = a.art_artikelnummer

    LEFT JOIN umsatz u
        ON b.art_artikelnummer::text = u.artikelnummer

    WHERE b.artikel_verfuegbar
)

SELECT *
FROM final
ORDER BY artikelnummer, sortierung
