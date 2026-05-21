{{ 
    config(
        materialized='table',
        tags=['gold_facts']
    ) 
}}

with rechnung as (
    select *
    from {{ ref('silver_rechnung_belege') }}
    where rechnung_beleggruppe is not null 
),

position as (
    select *
    from {{ ref('silver_belege_positionen') }}
)


select 

    rechnung.rechnung_beleg_nr,
    case 
            when rechnung.rechnnung_bel_datum ~ '^\d{2}\.\d{2}\.\d{4}$'
            then to_date(rechnung.rechnnung_bel_datum, 'DD.MM.YYYY')
            else null
        end as rechnnung_bel_datum,

    _position_rechnung.bel_adressnummer as rechnung_adress_nr,
    _position_rechnung.pos_artikelnummer as rechnung_artikel_nr,

    _position_rechnung.bg_beleggruppe as rechnung_beleggruppe,
    _position_rechnung."BG_Beleggruppe" as rechnung_beleggruppe_name,

    CASE 
        when _position_rechnung.bg_beleggruppe IN ('G00','G01','G02','R00','R83') then 'ja'
        else 'nein'
    end as umsatzrelevant,

    _position_rechnung.pos_gesamtmenge as rechnung_gesamtmenge,
    _position_rechnung.pos_gesamtumsatz as rechnung_gesamtumsatz,
    _position_rechnung.pos_gesamtrohertrag as rechnung_gesamtrohertrag,
    _position_rechnung.pos_ek_einzeln as rechnung_ek_einzeln,

    case
        when rechnung.rechnung_steuerart IN('3','5') and _position_rechnung.bg_beleggruppe IN ('R00','R83') then _position_rechnung.pos_gesamtumsatz
        when rechnung.rechnung_steuerart IN('3','5') and _position_rechnung.bg_beleggruppe IN ('G00','G01','G02') then _position_rechnung.pos_gesamtumsatz*(-1)
        when rechnung.rechnung_steuerart <> '3' and _position_rechnung.bg_beleggruppe IN ('R00','R83') then _position_rechnung.pos_gesamtrohertrag 
             + (_position_rechnung.pos_ek_einzeln * _position_rechnung.pos_gesamtmenge)   
        when rechnung.rechnung_steuerart <> '3' and _position_rechnung.bg_beleggruppe IN ('G00','G01','G02') then (_position_rechnung.pos_gesamtrohertrag 
             + (_position_rechnung.pos_ek_einzeln * _position_rechnung.pos_gesamtmenge)) *(-1)
        else _position_rechnung.pos_gesamtrohertrag
    end as rechnung_umsatz_calc

from rechnung

left join position _position_rechnung
    on CAST(rechnung.rechnung_beleg_nr  as varchar(14))= _position_rechnung.bel_belegnummer 


order by rechnung.rechnung_beleg_nr