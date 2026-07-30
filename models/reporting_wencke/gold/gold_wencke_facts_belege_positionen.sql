{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH belege_positionen AS (

    SELECT
        b.internal_id,
        b.wencke_id,
        b.mandant,
        b.bel_status,
        b.bel_nr,
        b.bel_steuer_art,
        b.bel_art,
        b.bel_beleg_gruppe,
        b.bg_beleggruppe,
        b.bel_final_adr_nr,
        b.bel_vertreter_nr,
        b.bel_date,
        b.bel_project_nr,
        b.bel_oe_5,
        b.bel_beleg_bonus,

        p.pos_nr,
        p.pos_artikel_nr,
        p.pos_artikel_text,
        p.pos_hersteller_nr,
        p.pos_steuer_spalte,
        p.pos_steuer_schluessel,
        p.pos_steuersatz,
        p.pos_steuerberechnung,
        p.pos_rabattfaehig,
        p.pos_bonusfaehig,
        p.pos_skontofaehig,
        p.pos_mengeneinheit_text,
        p.pos_umrechnungsfaktor,
        p.pos_einzelpreis,
        p.pos_einzelpreis2,
        p.pos_effektivpreis,
        p.pos_aktionspreis,
        p.pos_gesamtbetrag,
        p.pos_gesamtbetrag_ohne_nk,
        p.pos_gesamtumsatz,
        p.pos_ek_betrag,
        p.pos_ek_betrag_euro,
        p.pos_rohertrag_prozent,
        p.pos_rohertrag,
        p.pos_rohertrag_vor_bonus,
        p.pos_menge,
        p.pos_skontofaehig_betrag,
        p.positionsart,
        p.pos_created_by_user

    FROM {{ ref('silver_wencke_belege_rechnung_gutschrift') }} b

    INNER JOIN {{ ref('silver_wencke_belege_positionen_gesamt') }} p
        ON b.internal_id = p.wencke_lv_belege_id

)

SELECT
    *,

    CASE
        WHEN bel_beleg_bonus THEN 'Nur Bonusbelege'
        ELSE 'Ohne Bonusbelege'
    END AS rechnung_bonusbelege_flag,

    CONCAT(
        COALESCE(bel_final_adr_nr::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS adress_key,

    CASE
        WHEN bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN -1
        WHEN bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN 1
        ELSE 0
    END AS beleg_vorzeichen,

    CASE
        WHEN bel_steuer_art IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN COALESCE(pos_gesamtbetrag, 0)

        WHEN bel_steuer_art IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN COALESCE(pos_gesamtbetrag, 0) * -1

        WHEN COALESCE(bel_steuer_art, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN
                COALESCE(pos_rohertrag, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)

        WHEN COALESCE(bel_steuer_art, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN (
                COALESCE(pos_rohertrag, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)
            ) * -1

        ELSE COALESCE(pos_rohertrag, 0)
    END AS rechnung_umsatz_calc,

    CASE
        WHEN bel_steuer_art IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN COALESCE(pos_gesamtumsatz, 0)

        WHEN bel_steuer_art IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN COALESCE(pos_gesamtumsatz, 0) * -1

        WHEN COALESCE(bel_steuer_art, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN
                COALESCE(pos_rohertrag_vor_bonus, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)

        WHEN COALESCE(bel_steuer_art, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN (
                COALESCE(pos_rohertrag_vor_bonus, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)
            ) * -1

        ELSE COALESCE(pos_rohertrag_vor_bonus, 0)
    END AS rechnung_umsatz_vor_bonus_calc,

    COALESCE(pos_ek_betrag, 0)
        * COALESCE(pos_menge, 0)
        * CASE
            WHEN bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
                THEN -1
            ELSE 1
        END AS ek_gesamt_calc,

    COALESCE(pos_rohertrag, 0)
        * CASE
            WHEN bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
                THEN -1
            ELSE 1
        END AS rohertrag_calc,

    COALESCE(pos_rohertrag_vor_bonus, 0)
        * CASE
            WHEN bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
                THEN -1
            ELSE 1
        END AS rohertrag_vor_bonus_calc,

    CASE
        WHEN bg_beleggruppe IN (
            'G00',
            'G01',
            'G02',
            'R00',
            'R83'
        ) THEN 1
        ELSE 0
    END AS umsatzrelevant

FROM belege_positionen