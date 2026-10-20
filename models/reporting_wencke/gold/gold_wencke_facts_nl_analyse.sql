
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['gold', 'nachlieferung', 'powerbi']
    )
}}

WITH gesamt AS (
    SELECT
        mandant,
        monat,
        adr_nr,
        'Warenausgang' AS bereich,
        nl_lieferung,
        gesamt_lieferungen,
        nl_quote_prozent
    FROM {{ ref('gold_wencke_facts_nl_warenausgang') }}
    UNION ALL
    SELECT
        mandant,
        monat,
        adr_nr,
        'Wareneingang' AS bereich,
        nl_lieferung,
        gesamt_lieferungen,
        nl_quote_prozent
    FROM {{ ref('gold_wencke_facts_nl_wareneingang') }}
)
SELECT
    g.mandant,
    g.monat,
    g.adr_nr,
    a.adr_text,
    CONCAT(g.adr_nr, '_', g.mandant) AS adress_key,
    CASE
        WHEN g.bereich = 'Warenausgang'
             AND a.adr_vertreter_nr = 91
            THEN 'Intercompany'
        WHEN g.bereich = 'Wareneingang'
             AND g.adr_nr::text IN (
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
             )
            THEN 'Intercompany'
        ELSE 'Exkl. Intercompany'
    END AS intercompany_flag,
    g.bereich,
    g.nl_lieferung,
    g.gesamt_lieferungen,
    g.nl_quote_prozent
FROM gesamt AS g
LEFT JOIN {{ ref('silver_wencke_adressen') }} AS a
    ON CONCAT(g.adr_nr, '_', g.mandant) = CONCAT(a.adr_nr, '_', a.mandant)
