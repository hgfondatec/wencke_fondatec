
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

kategorien AS (
    SELECT
        b.art_artikelnummer,
        b.hat_bestand,
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
                art_nachhaltiger_artikel_39,
                art_nachhaltiger_artikel_32,
                art_nachhaltiger_artikel_42,
                art_nachhaltiger_artikel_36),
            ('Blauer Engel', 2,
                art_nh_blauer_engel_39,
                art_nh_blauer_engel_32,
                art_nh_blauer_engel_42,
                art_nh_blauer_engel_36),
            ('EU Ecolabel', 3,
                art_nh_eu_ecolabel_39,
                art_nh_eu_ecolabel_32,
                art_nh_eu_ecolabel_42,
                art_nh_eu_ecolabel_36),
            ('Nordic Ecolabel', 4,
                art_nh_nordic_ecolabel_39,
                art_nh_nordic_ecolabel_32,
                art_nh_nordic_ecolabel_42,
                art_nh_nordic_ecolabel_36),
            ('FSC', 5,
                art_nh_fsc_39,
                art_nh_fsc_32,
                art_nh_fsc_42,
                art_nh_fsc_36),
            ('Sonstiges', 6,
                art_nh_sonstiges_39,
                art_nh_sonstiges_32,
                art_nh_sonstiges_42,
                art_nh_sonstiges_36),
            ('Sonstiges Bezeichnung', 7,
                art_nh_sonstiges_name_39,
                art_nh_sonstiges_name_32,
                art_nh_sonstiges_name_42,
                art_nh_sonstiges_name_36)
    ) AS k(
        kategorie,
        sortierung,
        wert_39,
        wert_32,
        wert_42,
        wert_36
    )
),

normalisiert AS (
    SELECT
        art_artikelnummer,
        hat_bestand,
        kategorie,
        sortierung,
        LOWER(TRIM(COALESCE(wert_39::text, ''))) NOT IN ('', 'false', 'f', '0', 'nein', 'no') AS wert_39,
        LOWER(TRIM(COALESCE(wert_32::text, ''))) NOT IN ('', 'false', 'f', '0', 'nein', 'no') AS wert_32,
        LOWER(TRIM(COALESCE(wert_42::text, ''))) NOT IN ('', 'false', 'f', '0', 'nein', 'no') AS wert_42,
        LOWER(TRIM(COALESCE(wert_36::text, ''))) NOT IN ('', 'false', 'f', '0', 'nein', 'no') AS wert_36
    FROM kategorien
),

gesamt AS (
    SELECT
        art_artikelnummer,
        hat_bestand,
        'Gesamt Nachhaltig' AS kategorie,
        0 AS sortierung,
        BOOL_OR(wert_39) AS wert_39,
        BOOL_OR(wert_32) AS wert_32,
        BOOL_OR(wert_42) AS wert_42,
        BOOL_OR(wert_36) AS wert_36
    FROM normalisiert
    GROUP BY
        art_artikelnummer,
        hat_bestand
),

vereint AS (
    SELECT * FROM normalisiert
    UNION ALL
    SELECT * FROM gesamt
),

final AS (
    SELECT
        art_artikelnummer AS artikelnummer,
        kategorie,
        CASE WHEN wert_39 THEN 'X' END AS mandant_39,
        CASE WHEN wert_32 THEN 'X' END AS mandant_32,
        CASE WHEN wert_42 THEN 'X' END AS mandant_42,
        CASE WHEN wert_36 THEN 'X' END AS mandant_36,
        CASE
            WHEN LOWER(TRIM(COALESCE(hat_bestand::text, '')))
                IN ('hat bestand')
            THEN 'Ja'
            ELSE 'Nein'
        END AS bestand,
        sortierung
    FROM vereint
    WHERE
        wert_39
        OR wert_32
        OR wert_42
        OR wert_36
)

SELECT *
FROM final
ORDER BY
    artikelnummer,
    sortierung
