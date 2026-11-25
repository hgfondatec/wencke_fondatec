{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['gold', 'nachlieferung', 'artikel', 'powerbi']
    )
}}

WITH gesamt AS (

    SELECT
        mandant,
        monat,
        adr_nr,
        ref_bel_nr,
        lieferschein_wencke_id,
        lieferschein_nr,
        lieferschein_date,
        lieferung_reihenfolge,
        versand_art,
        pos_artikel_nr,
        artikel_key,
        'Warenausgang' AS bereich,
        nl_lieferung,
        gesamt_lieferungen

    FROM {{ ref('gold_wencke_facts_nl_warenausgang') }}

    UNION ALL

    SELECT
        mandant,
        monat,
        adr_nr,
        ref_bel_nr,
        lieferschein_wencke_id,
        lieferschein_nr,
        lieferschein_date,
        lieferung_reihenfolge,
        versand_art,
        pos_artikel_nr,
        artikel_key,
        'Wareneingang' AS bereich,
        nl_lieferung,
        gesamt_lieferungen

    FROM {{ ref('gold_wencke_facts_nl_wareneingang') }}

)

SELECT
    g.mandant,
    g.monat,
    g.adr_nr,
    a.adr_text,

    CONCAT(
        g.adr_nr,
        '_',
        g.mandant
    ) AS adress_key,

    g.ref_bel_nr,
    g.lieferschein_wencke_id,
    g.lieferschein_nr,
    g.lieferschein_date,
    g.lieferung_reihenfolge,
    g.versand_art,

    CONCAT(
        g.lieferschein_wencke_id,
        '_',
        g.mandant,
        '_',
        g.bereich
    ) AS lieferschein_key,

    g.pos_artikel_nr,
    g.artikel_key,

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
    g.gesamt_lieferungen

FROM gesamt AS g

LEFT JOIN {{ ref('silver_wencke_adressen') }} AS a
    ON CONCAT(g.adr_nr, '_', g.mandant)
        = CONCAT(a.adr_nr, '_', a.mandant)