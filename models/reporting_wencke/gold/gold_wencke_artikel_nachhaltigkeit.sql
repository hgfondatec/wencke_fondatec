{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}


WITH artikel_attribute AS (
    SELECT
        wlaa.artikel_nr,
        wlaa.mandant,
        BOOL_OR(
            COALESCE(wlaa.art_nachhaltiger_artikel, FALSE)
            OR COALESCE(wlaa.art_nh_blauer_engel, FALSE)
            OR COALESCE(wlaa.art_nh_eu_ecolabel, FALSE)
            OR COALESCE(wlaa.art_nh_nordic_ecolabel, FALSE)
            OR COALESCE(wlaa.art_nh_fsc, FALSE)
            OR COALESCE(wlaa.art_nh_sonstiges, FALSE)
            OR NULLIF(TRIM(wlaa.art_nh_sonstiges_name), '') IS NOT NULL
        ) AS ist_nachhaltiger_artikel,
        MAX(wlaa.art_gewicht_brutto) AS art_gewicht_brutto
    FROM {{ ref('bronze_wencke_artikel_attribute') }} wlaa
    GROUP BY
        wlaa.artikel_nr,
        wlaa.mandant
),

basis AS (
    SELECT
        wlb.mandant,
        DATE_TRUNC('month', wlb.bel_date)::date AS monat,
        wlb.pos_artikel_nr,
        COALESCE(aa.ist_nachhaltiger_artikel, FALSE) AS ist_nachhaltiger_artikel,
        wlb.rechnung_umsatz_vor_bonus_calc AS rechnung_umsatz_calc,
        wlb.rechnung_menge_calc,
        COALESCE(aa.art_gewicht_brutto, 0) AS art_gewicht_brutto
    FROM {{ ref('gold_wencke_facts_belege_positionen') }} wlb
    LEFT JOIN artikel_attribute aa
        ON aa.mandant = wlb.mandant
        AND aa.artikel_nr = wlb.pos_artikel_nr
    WHERE
        wlb.bel_art IN ('R', 'G')
        AND wlb.bel_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '2 years'
        AND wlb.bel_date < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
        AND wlb.bel_status = 'N'
),

umsatz AS (
    SELECT
        mandant,
        monat,
        'Umsatz' AS kategorie,
        SUM(rechnung_umsatz_calc) FILTER (
            WHERE ist_nachhaltiger_artikel = TRUE
        ) AS nachhaltig,
        SUM(rechnung_umsatz_calc) AS gesamt
    FROM basis
    GROUP BY
        mandant,
        monat
),

tonnage AS (
    SELECT
        mandant,
        monat,
        'Tonnage' AS kategorie,
        SUM(
            rechnung_menge_calc * art_gewicht_brutto / 1000.0
        ) FILTER (
            WHERE ist_nachhaltiger_artikel = TRUE
        ) AS nachhaltig,
        SUM(
            rechnung_menge_calc * art_gewicht_brutto / 1000.0
        ) AS gesamt
    FROM basis
    GROUP BY
        mandant,
        monat
),

ausgabe AS (
    SELECT * FROM umsatz

    UNION ALL

    SELECT * FROM tonnage
)

SELECT
    mandant,
    monat,
    kategorie,
    nachhaltig,
    gesamt,
    ROUND(
        100.0 * nachhaltig / NULLIF(gesamt, 0),
        2
    ) AS quote_prozent
FROM ausgabe
