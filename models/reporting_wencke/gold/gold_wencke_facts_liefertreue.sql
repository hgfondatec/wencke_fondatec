
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['gold', 'liefertermintreue', 'powerbi']
    )
}}

WITH basis AS (
    SELECT DISTINCT
        b.mandant,
        DATE_TRUNC('month', b.bel_date)::date AS monat,
        b.bel_nr AS bestellung_nr,
        l.lieferschein_wencke_id,
        l.lieferschein_nr,
        l.adr_nr AS adressnummer,
        CONCAT(l.adr_nr, '_', b.mandant) AS adress_key,
        l.lieferschein_date::date - b.bel_liefer_versand_date::date AS abweichung_tage
    FROM {{ ref('silver_wencke_belege_bestellungen') }} AS b
    INNER JOIN {{ ref('silver_wencke_belege_lieferscheine') }} AS l
        ON l.ref_bel_nr = b.bel_nr
       AND l.mandant = b.mandant
    WHERE b.bel_liefer_versand_date IS NOT NULL
      AND l.lieferschein_date IS NOT NULL
),
aggregation AS (
    SELECT
        mandant,
        monat,
        adressnummer,
        adress_key,
        COUNT(*) FILTER (WHERE abweichung_tage <= 0) AS anzahl_puenktlich,
        COUNT(*) FILTER (WHERE abweichung_tage BETWEEN 1 AND 5) AS anzahl_1_5_tage_verspaetet,
        COUNT(*) FILTER (WHERE abweichung_tage BETWEEN 6 AND 10) AS anzahl_6_10_tage_verspaetet,
        COUNT(*) FILTER (WHERE abweichung_tage BETWEEN 11 AND 20) AS anzahl_11_20_tage_verspaetet,
        COUNT(*) FILTER (WHERE abweichung_tage > 20) AS anzahl_ueber_20_tage_verspaetet
    FROM basis
    GROUP BY
        mandant,
        monat,
        adressnummer,
        adress_key
),
kategorien AS (
    SELECT
        mandant,
        monat,
        adressnummer,
        adress_key,
        'Pünktlich' AS kategorie,
        1 AS sort,
        anzahl_puenktlich AS value
    FROM aggregation
    UNION ALL
    SELECT
        mandant,
        monat,
        adressnummer,
        adress_key,
        '1-5 Tage verspätet' AS kategorie,
        2 AS sort,
        anzahl_1_5_tage_verspaetet AS value
    FROM aggregation
    UNION ALL
    SELECT
        mandant,
        monat,
        adressnummer,
        adress_key,
        '6-10 Tage verspätet' AS kategorie,
        3 AS sort,
        anzahl_6_10_tage_verspaetet AS value
    FROM aggregation
    UNION ALL
    SELECT
        mandant,
        monat,
        adressnummer,
        adress_key,
        '11-20 Tage verspätet' AS kategorie,
        4 AS sort,
        anzahl_11_20_tage_verspaetet AS value
    FROM aggregation
    UNION ALL
    SELECT
        mandant,
        monat,
        adressnummer,
        adress_key,
        '> 20 Tage verspätet' AS kategorie,
        5 AS sort,
        anzahl_ueber_20_tage_verspaetet AS value
    FROM aggregation
)
SELECT
    k.mandant,
    k.monat,
    k.adressnummer,
    k.adress_key,
    a.adr_text,
    a.adr_vertreter_nr,
    CASE
        WHEN k.adressnummer::text IN (
            '700289',
            '700336',
            '700919',
            '701861',
            '770305',
            '770880',
            '771005',
            '771047',
            '771425',
            '771443',
            '771600',
            '771198',
            '772307',
            '772401',
            '773027',
            '773710',
            '775851',
            '779072',
            '779079',
            '780098',
            '899991',
            '899992',
            '899993',
            '899995'
        ) THEN 'Intercompany'
        ELSE 'Exkl. Intercompany'
    END AS intercompany_flag,
    k.kategorie,
    k.sort,
    k.value
FROM kategorien AS k
LEFT JOIN {{ ref('silver_wencke_adressen') }} AS a
    ON k.adress_key = CONCAT(a.adr_nr, '_', a.mandant)
