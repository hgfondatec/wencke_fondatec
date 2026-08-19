{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH belege_positionen AS (

    SELECT
        b.wencke_id,
        b.mandant,
        b.bel_status,
        b.bel_nr,
        b.bel_steuer_art,
        b.bel_art,
        b.bel_beleg_gruppe,

        CASE
            WHEN b.bel_project_nr IS NOT NULL THEN b.bel_oe_5
            ELSE b.bel_adr_nr
        END AS bel_final_adr_nr,

        b.bel_vertreter_nr,
        b.bel_date,
        b.bel_project_nr,
        b.bel_oe_5,
        b.bel_beleg_bonus,
        CONCAT(b.bel_art,b.bel_beleg_gruppe) as bg_beleggruppe,
        b.bel_filiale,
        b.bel_liefernde_filiale,
        'A' || LPAD(b.bel_created_by_user::text, 3, '0') AS bel_auftrag_ersteller,
        'L' || LPAD(l.bel_updated_by_user::text, 3, '0') AS bel_lieferschein_ersteller,
        'R' || LPAD(l.bel_updated_by_user::text, 3, '0') AS bel_rechnung_updater,
        b.bel_versand_art,

        br.rezept_variante,

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
        p.pos_bonus_erledigt,
        p.pos_bonus_betrag_endgueltig,
        p.pos_bonus_betrag_vorlaeufig,
        p.pos_menge,
        p.pos_skontofaehig_betrag,
        p.positionsart,
        p.pos_created_by_user,

        ver.tour,
        ver.fahrer,
        ver.lkw,
        ver.gewicht,
        ver.gesamtgewicht_netto,
        ver.gesamtgewicht_brutto,


        lfa.lieferant_kurzname,
        lfa.lieferant_anrede,
        lfa.lieferant_vorname,
        lfa.lieferant_nachname,
        lfa.lieferant_name1,
        lfa.lieferant_name2,
        lfa.lieferant_name3,
        lfa.lieferant_strasse,
        lfa.lieferant_hausnr,
        lfa.lieferant_plz,
        lfa.lieferant_ort


    FROM {{ ref('bronze_wencke_belege') }} b

    LEFT JOIN {{ ref('bronze_wencke_belege') }} l
        ON l.bel_nr = b.bel_lieferschein_nr
        AND b.mandant = l.mandant
        AND l.bel_art = 'L'

    LEFT JOIN {{ ref('bronze_wencke_belege_rezept') }} br
        ON b.wencke_id = br.wencke_id

    LEFT JOIN {{ ref('bronze_wencke_belege_versand') }} ver
        ON ver.wencke_id = b.wencke_id

    INNER JOIN {{ ref('silver_wencke_belege_positionen_gesamt') }} p
        ON b.wencke_id = p.bel_wencke_id

    LEFT JOIN {{ ref('silver_wencke_belege_adressen_lfa') }} lfa
        ON lfa.wencke_id = b.wencke_id

    WHERE b.bel_date >= DATE '2025-01-01'
        AND b.bel_date < DATE '2027-01-01'
        AND b.bel_status = 'N'

)

SELECT
    *,

    CASE
        WHEN bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN COALESCE(pos_menge, 0) * -1
        WHEN bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN COALESCE(pos_menge, 0)
        ELSE 0
    END AS rechnung_menge_calc,

    CASE
        WHEN bel_beleg_bonus THEN 'Nur Bonusbelege'
        ELSE 'Ohne Bonusbelege'
    END AS rechnung_bonusbelege_flag,

    CASE
        WHEN pos_artikel_nr IN ('ZZ','09990016') THEN 'Nur ZZ & 09990016'
        ELSE 'Ohne Zusatzartikel'
    END AS sbs_artikel_filter,

    CONCAT(
        COALESCE(bel_final_adr_nr::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS adress_key,

    CONCAT(
        COALESCE(pos_artikel_nr::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS artikel_key,

    CONCAT(
        COALESCE(mandant::text, ''),
        '_',
        COALESCE(bel_filiale::text, '')
    ) AS mandant_filial_key,


    CASE
        WHEN bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN -1
        WHEN bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN 1
        ELSE 0
    END AS beleg_vorzeichen,

    CASE
        WHEN pos_steuerberechnung IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN COALESCE(pos_gesamtbetrag, 0)

        WHEN pos_steuerberechnung IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN COALESCE(pos_gesamtbetrag, 0) * -1

        WHEN COALESCE(pos_steuerberechnung, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN
                COALESCE(pos_rohertrag_vor_bonus, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)

        WHEN COALESCE(pos_steuerberechnung, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN (
                COALESCE(pos_rohertrag_vor_bonus, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)
            ) * -1

        ELSE COALESCE(pos_rohertrag, 0)
    END AS rechnung_umsatz_vor_bonus_calc,

    CASE
        WHEN pos_steuerberechnung IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
             AND COALESCE(pos_bonus_erledigt, FALSE)
            THEN COALESCE(pos_gesamtbetrag, 0)-COALESCE(pos_bonus_betrag_endgueltig, 0)
        
        WHEN pos_steuerberechnung IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
             AND NOT COALESCE(pos_bonus_erledigt, FALSE)
            THEN COALESCE(pos_gesamtbetrag, 0)-COALESCE(pos_bonus_betrag_vorlaeufig, 0)

        WHEN pos_steuerberechnung IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
             AND COALESCE(pos_bonus_erledigt, FALSE)
            THEN (COALESCE(pos_gesamtbetrag, 0)-COALESCE(pos_bonus_betrag_endgueltig, 0)) * -1
        
        WHEN pos_steuerberechnung IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
             AND NOT COALESCE(pos_bonus_erledigt, FALSE)
            THEN (COALESCE(pos_gesamtbetrag, 0)-COALESCE(pos_bonus_betrag_vorlaeufig, 0)) * -1

        WHEN COALESCE(pos_steuerberechnung, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('R00', 'R83', 'R70')
            THEN
                COALESCE(pos_rohertrag, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)

        WHEN COALESCE(pos_steuerberechnung, '') NOT IN ('3', '5')
             AND bg_beleggruppe IN ('G00', 'G01', 'G02', 'G50')
            THEN (
                COALESCE(pos_rohertrag, 0)
                + COALESCE(pos_ek_betrag, 0)
                * COALESCE(pos_menge, 0)
            ) * -1

        ELSE COALESCE(pos_rohertrag, 0)
    END AS rechnung_umsatz_calc,

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