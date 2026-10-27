
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

adressen AS (
    SELECT
        mandant,
        adr_nr,
        CASE
            WHEN BOOL_OR(adr_vertreter_nr::text = '91')
                THEN 'Intercompany'
            ELSE 'Exkl. Intercompany'
        END AS intercompany_flag
    FROM {{ ref('silver_wencke_adressen') }}
    GROUP BY
        mandant,
        adr_nr
),

basis AS (
    SELECT
        wlb.mandant,
        DATE_TRUNC('month', wlb.bel_date)::date AS monat,
        wlb.pos_artikel_nr,
        COALESCE(a.intercompany_flag, 'Exkl. Intercompany') AS intercompany_flag,
        COALESCE(aa.ist_nachhaltiger_artikel, FALSE) AS ist_nachhaltiger_artikel,
        wlb.rechnung_umsatz_vor_bonus_calc AS rechnung_umsatz_calc,
        wlb.rechnung_menge_calc,
        COALESCE(aa.art_gewicht_brutto, 0) AS art_gewicht_brutto
    FROM {{ ref('gold_wencke_facts_belege_positionen') }} wlb
    LEFT JOIN artikel_attribute aa
        ON aa.mandant = wlb.mandant
        AND aa.artikel_nr = wlb.pos_artikel_nr
    LEFT JOIN adressen a
        ON a.mandant::text = wlb.mandant::text
        AND a.adr_nr::text = wlb.bel_adr_nr::text
),

umsatz AS (
    SELECT
        mandant,
        monat,
        intercompany_flag,
        'Umsatz' AS kategorie,
        SUM(rechnung_umsatz_calc) FILTER (
            WHERE ist_nachhaltiger_artikel = TRUE
        ) AS nachhaltig,
        SUM(rechnung_umsatz_calc) AS gesamt
    FROM basis
    GROUP BY
        mandant,
        monat,
        intercompany_flag
),

tonnage AS (
    SELECT
        mandant,
        monat,
        intercompany_flag,
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
        monat,
        intercompany_flag
),

ausgabe AS (
    SELECT * FROM umsatz

    UNION ALL

    SELECT * FROM tonnage
)

SELECT
    mandant,
    monat,
    intercompany_flag,
    kategorie,
    nachhaltig,
    gesamt,
    ROUND(
        100.0 * nachhaltig / NULLIF(gesamt, 0),
        2
    ) AS quote_prozent
FROM ausgabe
