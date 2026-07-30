{{ 
    config(
        materialized='table',
        tags=['gold_facts']
    ) 
}}

WITH silver_belege_positionen AS (
    SELECT *
    FROM {{ ref('glasofix_silver_belege_positionen') }}
)


SELECT

    LPAD(TRIM(bel_pos.bel_belegnummer)::text, 8, '0') AS rechnung_beleg_nr,
    bel_pos.bel_belegdatum AS rechnnung_bel_datum,

    CASE
        WHEN COALESCE(TRIM(bel_pos.bel_projektnummer), '') <> ''
        THEN TRIM(bel_pos.bel_heim)
     ELSE TRIM(bel_pos.bel_adressnummer)
    END AS rechnung_adress_nr,

    adr.adr_krankenkasse as rechnung_krankenkasse,
    kk.krankenkasse_bezeichnung as rechnung_kk_bezeichnung,
    adr.adr_rechnungsempfaenger as rechnung_re_empfaenger,
    re.rechnungsempfaenger_bezeichnung as rechnung_re_bezeichnung,

    bel_pos.bel_projektnummer AS rechnung_projekt_nr,
    bel_pos.pos_artikelnummer AS rechnung_artikel_nr,
    bel_pos.pos_positionsnummer AS rechnung_positionsnummer,
    bel_pos.bg_beleggruppe AS rechnung_beleggruppe,
    bel_pos."BG_Beleggruppe" AS rechnung_beleggruppe_name,

    lieferadressen.lfa_name1,
    lieferadressen.lfa_name2,
    lieferadressen.lfa_strasse,
    lieferadressen.lfa_plz,
    lieferadressen.lfa_ort,
    lieferadressen.lfa_telefon,

    CASE
        WHEN bel_pos.rechnung_bonusbelege_flag = 'J' THEN 'Nur Bonusbelege'
        ELSE 'Ohne Bonusbelege'
    END AS rechnung_bonusbelege_flag,

    CASE
        WHEN bel_pos.bg_beleggruppe IN ('G00', 'G01', 'G02', 'R00', 'R83') THEN 'ja'
        ELSE 'nein'
    END AS umsatzrelevant,

    bel_pos.pos_gesamtmenge AS rechnung_gesamtmenge,
    bel_pos.pos_gesamtumsatz AS rechnung_gesamtumsatz,
    bel_pos.pos_gesamtrohertrag AS rechnung_gesamtrohertrag,
    bel_pos.pos_ek_einzeln AS rechnung_ek_einzeln,

    CASE
        WHEN bel_pos.rechnung_steuerart IN ('3', '5')
            AND bel_pos.bg_beleggruppe IN ('R00', 'R83','R70')
            THEN bel_pos.pos_gesamtumsatz
        WHEN bel_pos.rechnung_steuerart IN ('3', '5')
            AND bel_pos.bg_beleggruppe IN ('G00', 'G01', 'G02','G50')
            THEN bel_pos.pos_gesamtumsatz * -1
        WHEN bel_pos.rechnung_steuerart <> '3'
            AND bel_pos.bg_beleggruppe IN ('R00', 'R83','R70')
            THEN (COALESCE(bel_pos.pos_gesamtrohertrag , 0) + COALESCE(bel_pos.pos_ek_einzeln, 0) * COALESCE(bel_pos.pos_gesamtmenge, 0))
        WHEN bel_pos.rechnung_steuerart <> '3'
            AND bel_pos.bg_beleggruppe IN ('G00', 'G01', 'G02','G50')
            THEN (COALESCE(bel_pos.pos_gesamtrohertrag , 0) + COALESCE(bel_pos.pos_ek_einzeln, 0) * COALESCE(bel_pos.pos_gesamtmenge, 0))* -1
        ELSE bel_pos.pos_gesamtrohertrag
    END AS rechnung_umsatz_calc,

    CASE
        WHEN bel_pos.rechnung_steuerart IN ('3', '5')
            AND bel_pos.bg_beleggruppe IN ('R00', 'R83','R70')
            THEN bel_pos.pos_gesamtumsatz_vor_bonus
        WHEN bel_pos.rechnung_steuerart IN ('3', '5')
            AND bel_pos.bg_beleggruppe IN ('G00', 'G01', 'G02','G50')
            THEN bel_pos.pos_gesamtumsatz_vor_bonus * -1
        WHEN bel_pos.rechnung_steuerart <> '3'
            AND bel_pos.bg_beleggruppe IN ('R00', 'R83','R70')
            THEN (COALESCE(bel_pos.pos_rohertrag_vor_bonus,0) + COALESCE(bel_pos.pos_ek_einzeln,0) * COALESCE(bel_pos.pos_gesamtmenge,0)) 
        WHEN bel_pos.rechnung_steuerart <> '3'
            AND bel_pos.bg_beleggruppe IN ('G00', 'G01', 'G02','G50')
            THEN (COALESCE(bel_pos.pos_rohertrag_vor_bonus,0) + COALESCE(bel_pos.pos_ek_einzeln,0) * COALESCE(bel_pos.pos_gesamtmenge,0)) * -1
        ELSE bel_pos.pos_rohertrag_vor_bonus
    END AS rechnung_umsatz_vor_bonus_calc,

    CASE
        WHEN bel_pos.bg_beleggruppe IN ('R00', 'R83','R70')
            THEN bel_pos.pos_gesamtrohertrag
        WHEN bel_pos.bg_beleggruppe IN ('G00', 'G01', 'G02','G50')
            THEN bel_pos.pos_gesamtrohertrag * -1
        ELSE NULL
    END AS rechnung_rohertrag_calc,

    CASE
        WHEN bel_pos.bg_beleggruppe IN ('R00', 'R83','R70')
            THEN bel_pos.pos_rohertrag_vor_bonus
        WHEN bel_pos.bg_beleggruppe IN ('G00', 'G01', 'G02','G50')
            THEN bel_pos.pos_rohertrag_vor_bonus * -1
        ELSE NULL
    END AS rechnung_rohertrag_vor_bonus_calc


FROM silver_belege_positionen bel_pos

LEFT JOIN {{ ref('glasofix_bronze_adresse') }} adr
    ON adr.adr_adressnummer = TRIM(bel_pos.bel_projektnummer)
   AND COALESCE(TRIM(bel_pos.bel_projektnummer), '') <> ''

LEFT JOIN {{ ref('glasofix_silver_re_empfaenger') }} re
    ON adr.adr_rechnungsempfaenger = re.rechnungsempfaenger_id

LEFT JOIN {{ ref('glasofix_silver_krankenkasse') }} kk
    ON adr.adr_krankenkasse = kk.krankenkasse_id

LEFT JOIN {{ ref('glasofix_gold_adress') }} a
    ON a.mapping_adressnummer =
       CASE
           WHEN COALESCE(TRIM(bel_pos.bel_projektnummer), '') <> ''
           THEN TRIM(bel_pos.bel_heim)
           ELSE bel_pos.bel_adressnummer
       END

LEFT JOIN {{ ref('glasofix_gold_artikel') }} ar
    ON ar.art_artikelnummer = bel_pos.pos_artikelnummer

LEFT JOIN {{ source('reporting', 'wencke_gold_pflichtkategorien') }} wgp 
    ON wgp.adressart_id = a.adrgruppe_id::TEXT
   AND wgp.hauptwarengruppe_id = ar.art_hauptwarengruppe_nummer

LEFT JOIN {{ ref('glasofix_bronze_lieferadressen') }} lieferadressen
    ON CAST(lieferadressen.lfa_nr AS varchar(20)) = bel_pos.bel_blfa_nr
   AND CAST(lieferadressen.lfa_debitor AS varchar(20)) =
        CASE
            WHEN COALESCE(TRIM(bel_pos.bel_projektnummer), '') <> ''
                THEN TRIM(bel_pos.bel_heim)
            ELSE TRIM(bel_pos.bel_adressnummer)
        END