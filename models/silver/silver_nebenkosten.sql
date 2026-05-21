{{ 
    config(
        materialized='table'
    ) 
}}

with nebkosten as (

    select
        bel_belegnummer,

        sum(cast(replace(nullif(bel_nk_frachtkostenpauschale, ''), ',', '.') as float)) as frachtkostenpauschale,
        sum(cast(replace(nullif(bel_nk_verpackung, ''), ',', '.') as float))            as verpackung,
        sum(cast(replace(nullif(bel_nk_mindermengenzuschlag, ''), ',', '.') as float))  as mindermengenzuschlag,
        sum(cast(replace(nullif(bel_nk_fuell_abnutzgebuehr, ''), ',', '.') as float))   as fuell_abnutzgebuehr,
        sum(cast(replace(nullif(bel_nk_gefahrgut, ''), ',', '.') as float))             as gefahrgut

    from {{ ref('bronze_belege') }}
    where bel_belegstatus_a_n ='N'
    group by bel_belegnummer
    

),

final as (

    select
        CAST(n.bel_belegnummer as integer) as pos_belegnummer ,
        x.pos_artikelnummer,
        null::float as pos_ek_einzeln,
        x.betrag as pos_gesamtrohertrag,
        x.betrag as pos_gesamtumsatz,
        1::float as pos_gesamtmenge

    from nebkosten n

    cross join lateral (
        values
            ('09990002', n.frachtkostenpauschale),
            ('09990017', n.verpackung),
            ('09990013', n.mindermengenzuschlag),
            ('09990016', n.fuell_abnutzgebuehr),
            ('09990018', n.gefahrgut)
    ) as x(pos_artikelnummer, betrag)

    where x.betrag is not null
      and x.betrag <> 0

)

select *
from final