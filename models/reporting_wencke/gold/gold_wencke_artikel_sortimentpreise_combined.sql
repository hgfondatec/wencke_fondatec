{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH umsatz AS (
    SELECT
        mandant,
        adress_key,
        TRIM(pos_artikel_nr::text) AS artikel,
        SUM(rechnung_umsatz_vor_bonus_calc) AS gesamtumsatz,
        SUM(rechnung_umsatz_vor_bonus_calc) FILTER (
            WHERE bel_date >= DATE_TRUNC('YEAR', CURRENT_DATE)
        ) AS umsatz_aktuelles_jahr,
        SUM(rechnung_umsatz_vor_bonus_calc) FILTER (
            WHERE bel_date < DATE_TRUNC('YEAR', CURRENT_DATE)
        ) AS umsatz_vorjahr
    FROM {{ ref('gold_wencke_facts_belege_positionen') }}
    WHERE bel_date >= DATE_TRUNC('YEAR', CURRENT_DATE) - INTERVAL '1 YEAR'
      AND bel_date < DATE_TRUNC('YEAR', CURRENT_DATE) + INTERVAL '1 YEAR'
    GROUP BY
        mandant,
        adress_key,
        TRIM(pos_artikel_nr::text)
    HAVING SUM(rechnung_umsatz_vor_bonus_calc) <> 0
),

relevante_adressen AS (
    SELECT DISTINCT
        mandant,
        adress_key
    FROM umsatz
),

relevante_artikel AS (
    SELECT DISTINCT
        artikel AS artikel_nummer
    FROM umsatz
),

adressen AS (
    SELECT
        a.beleg_mandant_id,
        a.adr_nr,
        a.adress_key,
        a.adr_text,
        a.praesident_ebene_1_bezeichnung,
        a.praesident_ebene_2_bezeichnung,
        a.praesident_ebene_3_bezeichnung
    FROM {{ ref('gold_wencke_adressen') }} a
    INNER JOIN relevante_adressen r
        ON r.mandant = a.beleg_mandant_id
       AND r.adress_key = a.adress_key
),

adress_zuordnung AS (
    SELECT
        beleg_mandant_id AS mandant,
        TRIM(adr_nr::text) AS preis_adr_nr,
        adr_nr AS debitor_nr,
        adress_key AS debitor_adress_key,
        'Debitor' AS preis_herkunft,
        adr_text AS herkunft_bezeichnung,
        1 AS prioritaet
    FROM adressen
    WHERE adr_nr IS NOT NULL

    UNION ALL

    SELECT
        beleg_mandant_id AS mandant,
        TRIM(SPLIT_PART(praesident_ebene_1_bezeichnung, '-', 1)) AS preis_adr_nr,
        adr_nr AS debitor_nr,
        adress_key AS debitor_adress_key,
        'Präsident 1' AS preis_herkunft,
        praesident_ebene_1_bezeichnung AS herkunft_bezeichnung,
        2 AS prioritaet
    FROM adressen
    WHERE NULLIF(TRIM(praesident_ebene_1_bezeichnung), '') IS NOT NULL

    UNION ALL

    SELECT
        beleg_mandant_id AS mandant,
        TRIM(SPLIT_PART(praesident_ebene_2_bezeichnung, '-', 1)) AS preis_adr_nr,
        adr_nr AS debitor_nr,
        adress_key AS debitor_adress_key,
        'Präsident 2' AS preis_herkunft,
        praesident_ebene_2_bezeichnung AS herkunft_bezeichnung,
        3 AS prioritaet
    FROM adressen
    WHERE NULLIF(TRIM(praesident_ebene_2_bezeichnung), '') IS NOT NULL

    UNION ALL

    SELECT
        beleg_mandant_id AS mandant,
        TRIM(SPLIT_PART(praesident_ebene_3_bezeichnung, '-', 1)) AS preis_adr_nr,
        adr_nr AS debitor_nr,
        adress_key AS debitor_adress_key,
        'Präsident 3' AS preis_herkunft,
        praesident_ebene_3_bezeichnung AS herkunft_bezeichnung,
        4 AS prioritaet
    FROM adressen
    WHERE NULLIF(TRIM(praesident_ebene_3_bezeichnung), '') IS NOT NULL
),

artikelstamm AS (
    SELECT DISTINCT
        TRIM(a.art_artikelnummer::text) AS artikel_nummer,
        TRIM(a.art_warengruppe::text) AS warengruppe
    FROM {{ ref('gold_wencke_artikel') }} a
    INNER JOIN relevante_artikel r
        ON r.artikel_nummer = TRIM(a.art_artikelnummer::text)
    WHERE a.art_artikelnummer IS NOT NULL
),

sortimentpreise_erweitert AS (
    -- Direkter Artikelpreis
    SELECT
        sp.*,
        a.artikel_nummer,
        a.warengruppe,
        'Artikel' AS artikel_preis_herkunft,
        1 AS artikel_prioritaet
    FROM {{ ref('gold_wencke_artikel_sortimentpreise') }} sp
    INNER JOIN artikelstamm a
        ON a.artikel_nummer = TRIM(sp.artikel::text)
    WHERE LENGTH(TRIM(sp.artikel::text)) <> 4

    UNION ALL

    -- Warengruppenpreis auf konkrete Artikel erweitern
    SELECT
        sp.*,
        a.artikel_nummer,
        a.warengruppe,
        'Warengruppe' AS artikel_preis_herkunft,
        2 AS artikel_prioritaet
    FROM {{ ref('gold_wencke_artikel_sortimentpreise') }} sp
    INNER JOIN artikelstamm a
        ON a.warengruppe = TRIM(sp.artikel::text)
    WHERE LENGTH(TRIM(sp.artikel::text)) = 4
),

preise AS (
    SELECT
        sp.*,
        a.debitor_nr,
        a.debitor_adress_key,
        a.preis_herkunft,
        a.herkunft_bezeichnung,
        a.prioritaet,
        u.gesamtumsatz,
        u.umsatz_aktuelles_jahr,
        u.umsatz_vorjahr
    FROM adress_zuordnung a
    INNER JOIN umsatz u
        ON u.mandant = a.mandant
       AND u.adress_key = a.debitor_adress_key
    INNER JOIN sortimentpreise_erweitert sp
        ON sp.mandant = a.mandant
       AND TRIM(sp.adr_nr::text) = a.preis_adr_nr
       AND sp.artikel_nummer = u.artikel
),

preis_logik AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                mandant,
                debitor_adress_key,
                artikel_nummer
            ORDER BY
                -- 1 = aktuell, 2 = abgelaufen, 3 = zukünftig
                CASE
                    WHEN gueltig_ab <= CURRENT_DATE
                     AND gueltig_bis >= CURRENT_DATE THEN 1
                    WHEN gueltig_bis < CURRENT_DATE THEN 2
                    ELSE 3
                END ASC,

                -- AKTUELL: Debitor -> P1 -> P2 -> P3
                CASE
                    WHEN gueltig_ab <= CURRENT_DATE
                     AND gueltig_bis >= CURRENT_DATE
                    THEN prioritaet
                END ASC,

                -- AKTUELL: Artikel -> Warengruppe
                CASE
                    WHEN gueltig_ab <= CURRENT_DATE
                     AND gueltig_bis >= CURRENT_DATE
                    THEN artikel_prioritaet
                END ASC,

                -- AKTUELL: neuesten Start bevorzugen
                CASE
                    WHEN gueltig_ab <= CURRENT_DATE
                     AND gueltig_bis >= CURRENT_DATE
                    THEN gueltig_ab
                END DESC,

                -- ABGELAUFEN: zuletzt abgelaufenen Preis nehmen
                CASE
                    WHEN gueltig_bis < CURRENT_DATE
                    THEN gueltig_bis
                END DESC,

                -- Bei gleichem Ende: Debitor -> P1 -> P2 -> P3
                CASE
                    WHEN gueltig_bis < CURRENT_DATE
                    THEN prioritaet
                END ASC,

                -- Danach Artikel -> Warengruppe
                CASE
                    WHEN gueltig_bis < CURRENT_DATE
                    THEN artikel_prioritaet
                END ASC,

                -- Zusätzlicher Tie-Breaker
                CASE
                    WHEN gueltig_bis < CURRENT_DATE
                    THEN gueltig_ab
                END DESC,

                -- Zukunft: frühesten Nachfolger zuerst
                CASE
                    WHEN gueltig_ab > CURRENT_DATE
                    THEN gueltig_ab
                END ASC,

                CASE
                    WHEN gueltig_ab > CURRENT_DATE
                    THEN prioritaet
                END ASC,

                CASE
                    WHEN gueltig_ab > CURRENT_DATE
                    THEN artikel_prioritaet
                END ASC
        ) AS reporting_rang_debitor
    FROM preise
),

preis_mit_flags AS (
    SELECT
        *,
        (
            reporting_rang_debitor = 1
            AND gueltig_ab <= CURRENT_DATE
        ) AS wird_reported_debitor,

        MIN(
            CASE
                WHEN gueltig_ab > CURRENT_DATE
                THEN gueltig_ab
            END
        ) OVER (
            PARTITION BY
                mandant,
                debitor_adress_key,
                artikel_nummer
        ) AS naechster_preis_ab_debitor
    FROM preis_logik
),

preise_final AS (
    SELECT
        *,
        CASE
            WHEN naechster_preis_ab_debitor IS NOT NULL
                THEN 'Mit Nachfolger'
            ELSE 'Ohne Nachfolger'
        END AS hat_nl_debitor
    FROM preis_mit_flags
)

SELECT *
FROM preise_final