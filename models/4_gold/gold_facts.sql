{{ 
    config(
        materialized='table',
        tags=['gold_facts']
    ) 
}}


with
silver_belege_positionen as (
    select *
    from {{ ref('silver_belege_positionen') }}

    UNION ALL

    select *
    from {{ ref('silver_pauschale') }}

)

select 

    bel_pos.bel_belegnummer as rechnung_beleg_nr,
    bel_pos.bel_belegdatum as rechnnung_bel_datum,
    bel_pos.bel_adressnummer as rechnung_adress_nr,
    bel_pos.pos_artikelnummer as rechnung_artikel_nr,
    bel_pos.pos_positionsnummer as rechnung_positionsnummer,
    bel_pos.bg_beleggruppe as rechnung_beleggruppe,
    bel_pos."BG_Beleggruppe" as rechnung_beleggruppe_name,
    bel_pos.rechnung_bonusbelege_flag,

    CASE 
        when bel_pos.bg_beleggruppe IN ('G00','G01','G02','R00','R83') then 'ja'
        else 'nein'
    end as umsatzrelevant,

    bel_pos.pos_gesamtmenge as rechnung_gesamtmenge,
    bel_pos.pos_gesamtumsatz as rechnung_gesamtumsatz,
    bel_pos.pos_gesamtrohertrag as rechnung_gesamtrohertrag,
    bel_pos.pos_ek_einzeln as rechnung_ek_einzeln,

    case
        when bel_pos.rechnung_steuerart IN('3','5') and bel_pos.bg_beleggruppe IN ('R00','R83') then bel_pos.pos_gesamtumsatz
        when bel_pos.rechnung_steuerart IN('3','5') and bel_pos.bg_beleggruppe IN ('G00','G01','G02') then bel_pos.pos_gesamtumsatz*(-1)
        when bel_pos.rechnung_steuerart <> '3' and bel_pos.bg_beleggruppe IN ('R00','R83') then bel_pos.pos_gesamtrohertrag 
             + (bel_pos.pos_ek_einzeln * bel_pos.pos_gesamtmenge)   
        when bel_pos.rechnung_steuerart <> '3' and bel_pos.bg_beleggruppe IN ('G00','G01','G02') then (bel_pos.pos_gesamtrohertrag 
             + (bel_pos.pos_ek_einzeln * bel_pos.pos_gesamtmenge)) *(-1)
        else bel_pos.pos_gesamtrohertrag
    end as rechnung_umsatz_calc,

    case
        when bel_pos.rechnung_steuerart IN('3','5') and bel_pos.bg_beleggruppe IN ('R00','R83') then bel_pos.pos_gesamtumsatz_vor_bonus
        when bel_pos.rechnung_steuerart IN('3','5') and bel_pos.bg_beleggruppe IN ('G00','G01','G02') then bel_pos.pos_gesamtumsatz_vor_bonus*(-1)
        when bel_pos.rechnung_steuerart <> '3' and bel_pos.bg_beleggruppe IN ('R00','R83') then bel_pos.pos_rohertrag_vor_bonus 
             + (bel_pos.pos_ek_einzeln * bel_pos.pos_gesamtmenge)   
        when bel_pos.rechnung_steuerart <> '3' and bel_pos.bg_beleggruppe IN ('G00','G01','G02') then (bel_pos.pos_rohertrag_vor_bonus 
             + (bel_pos.pos_ek_einzeln * bel_pos.pos_gesamtmenge)) *(-1)
        else bel_pos.pos_rohertrag_vor_bonus
    end as rechnung_umsatz_vor_bonus_calc,

     case
        when bel_pos.bg_beleggruppe IN ('R00','R83') then bel_pos.pos_gesamtrohertrag
        when  bel_pos.bg_beleggruppe IN ('G00','G01','G02') then bel_pos.pos_gesamtrohertrag*(-1)
        else null
    end as rechnung_rohertrag_calc,

    case
        when bel_pos.bg_beleggruppe IN ('R00','R83') then bel_pos.pos_rohertrag_vor_bonus
        when  bel_pos.bg_beleggruppe IN ('G00','G01','G02') then bel_pos.pos_rohertrag_vor_bonus*(-1)
        else null
    end as rechnung_rohertrag_vor_bonus_calc

from silver_belege_positionen bel_pos