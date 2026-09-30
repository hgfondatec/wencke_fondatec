{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH umsatz AS (
    -- Nur Debitor + Artikel mit Umsatz im aktuellen oder vorherigen Jahr
    SELECT
        adress_key,
        pos_artikel_nr AS artikel,
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
    GROUP BY adress_key, pos_artikel_nr
    HAVING SUM(rechnung_umsatz_vor_bonus_calc) <> 0
),

adressen AS (
    -- Nur relevante Debitoren
    SELECT
        a.beleg_mandant_id,
        a.adr_nr,
        a.adress_key,
        a.praesident_ebene_1_bezeichnung,
        a.praesident_ebene_2_bezeichnung,
        a.praesident_ebene_3_bezeichnung
    FROM {{ ref('gold_wencke_adressen') }} a
    WHERE EXISTS (
        SELECT 1
        FROM umsatz u
        WHERE u.adress_key = a.adress_key
    )
),

adress_zuordnung AS (
    -- Kundenhierarchie: Debitor -> Präsident 1 -> Präsident 2 -> Präsident 3
    SELECT
        beleg_mandant_id AS mandant,
        TRIM(adr_nr::text) AS preis_adr_nr,
        adr_nr AS debitor_nr,
        adress_key AS debitor_adress_key,
        'Debitor' AS preis_herkunft,
        NULL::text AS herkunft_bezeichnung,
        1 AS prioritaet
    FROM adressen
    WHERE adr_nr IS NOT NULL

    UNION ALL

    SELECT
        beleg_mandant_id,
        TRIM(SPLIT_PART(praesident_ebene_1_bezeichnung, '-', 1)),
        adr_nr,
        adress_key,
        'Präsident 1',
        praesident_ebene_1_bezeichnung,
        2
    FROM adressen
    WHERE NULLIF(TRIM(praesident_ebene_1_bezeichnung), '') IS NOT NULL

    UNION ALL

    SELECT
        beleg_mandant_id,
        TRIM(SPLIT_PART(praesident_ebene_2_bezeichnung, '-', 1)),
        adr_nr,
        adress_key,
        'Präsident 2',
        praesident_ebene_2_bezeichnung,
        3
    FROM adressen
    WHERE NULLIF(TRIM(praesident_ebene_2_bezeichnung), '') IS NOT NULL

    UNION ALL

    SELECT
        beleg_mandant_id,
        TRIM(SPLIT_PART(praesident_ebene_3_bezeichnung, '-', 1)),
        adr_nr,
        adress_key,
        'Präsident 3',
        praesident_ebene_3_bezeichnung,
        4
    FROM adressen
    WHERE NULLIF(TRIM(praesident_ebene_3_bezeichnung), '') IS NOT NULL
),

artikelstamm AS (
    -- Artikelnummer ist im Artikelstamm eindeutig, daher kein Mandant notwendig
    SELECT DISTINCT
        art_artikelnummer AS artikel_nummer,
        art_warengruppe AS warengruppe
    FROM {{ ref('gold_wencke_artikel') }}
    WHERE art_artikelnummer IS NOT NULL
),

sortimentpreise_erweitert AS (
    /*
    Direkter Artikelpreis:
    artikel = ursprünglicher Wert aus Sortimentpreise
    artikel_nummer = konkrete Artikelnummer
    */
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

    /*
    Warengruppenpreis:
    Wenn artikel 4-stellig ist, handelt es sich um eine WGR.
    Diese wird auf alle konkreten Artikel der WGR aufgefächert.
    */
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
    -- Nur Debitor + konkrete Artikel, die tatsächlich Umsatz hatten
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
        ON u.adress_key = a.debitor_adress_key
    INNER JOIN sortimentpreise_erweitert sp
        ON sp.mandant = a.mandant
       AND TRIM(sp.adr_nr::text) = a.preis_adr_nr
       AND sp.artikel_nummer = TRIM(u.artikel::text)
),

preis_mit_nachfolger AS (
    /*
    Nachfolger innerhalb exakt derselben Preisquelle:
    - Debitor
    - konkreter Artikel
    - Kundenebene
    - Artikelebene
    - ursprünglicher Artikel/WGR
    */
    SELECT
        *,
        LEAD(gueltig_ab) OVER (
            PARTITION BY
                mandant,
                debitor_adress_key,
                artikel_nummer,
                prioritaet,
                artikel_prioritaet,
                artikel
            ORDER BY gueltig_ab
        ) AS naechster_preis_ab
    FROM preise
),

preis_logik AS (
    /*
    Priorität:
    1. Bereits gestarteter Preis
    2. Debitor -> Präsident 1 -> Präsident 2 -> Präsident 3
    3. Artikel -> Warengruppe
    4. Neuestes gueltig_ab

    gueltig_bis ist nur Tie-Breaker.
    */
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                mandant,
                debitor_adress_key,
                artikel_nummer
            ORDER BY
                CASE WHEN gueltig_ab <= CURRENT_DATE THEN 0 ELSE 1 END,
                prioritaet,
                artikel_prioritaet,
                CASE WHEN gueltig_ab <= CURRENT_DATE THEN gueltig_ab END DESC,
                gueltig_bis DESC
        ) AS reporting_rang_debitor
    FROM preis_mit_nachfolger
),

preise_final AS (
    SELECT
        *,
        (reporting_rang_debitor = 1 AND gueltig_ab <= CURRENT_DATE) AS wird_reported_debitor,
        CASE
            WHEN naechster_preis_ab IS NOT NULL THEN 'Mit Nachfolger'
            ELSE 'Ohne Nachfolger'
        END AS hat_nl_debitor
    FROM preis_logik
)

SELECT *
FROM preise_final