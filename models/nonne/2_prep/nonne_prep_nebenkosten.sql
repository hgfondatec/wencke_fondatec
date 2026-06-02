{{ 
    config(
        materialized='table'
    ) 
}}

with nebkosten as (

    select
        bel_belegnummer,

        sum(cast(replace(nullif(bel_nk_frachtkostenpauschale, ''), ',', '.') as float)) as frachtkostenpauschale,
        sum(cast(replace(nullif(bel_nk_verpackung, ''), ',', '.') as float)) as verpackung,
        sum(cast(replace(nullif(bel_nk_mindermengenzuschlag, ''), ',', '.') as float)) as mindermengenzuschlag,
        sum(cast(replace(nullif(bel_nk_fuell_abnutzgebuehr, ''), ',', '.') as float)) as fuell_abnutzgebuehr,
        sum(cast(replace(nullif(bel_nk_gefahrgut, ''), ',', '.') as float)) as gefahrgut

    from {{ ref('nonne_bronze_belege') }}
    where bel_belegstatus_a_n = 'N'
    group by bel_belegnummer

),

final as (

    select
        n.bel_belegnummer as pos_belegnummer,
        x.pos_artikelnummer,
        x.pos_positionsnummer,

        null::float as pos_ek_einzeln,
        x.betrag as pos_gesamtrohertrag,
        x.betrag as pos_rohertrag_vor_bonus,
        x.betrag as pos_gesamtumsatz,
        x.betrag as pos_gesamtumsatz_vor_bonus,
        1::float as pos_gesamtmenge

    from nebkosten n

    cross join lateral (
        values
            ('09990002', n.frachtkostenpauschale,     9001),
            ('09990017', n.verpackung,               9002),
            ('09990013', n.mindermengenzuschlag,     9003),
            ('09990016', n.fuell_abnutzgebuehr,      9004),
            ('09990018', n.gefahrgut,                9005)
    ) as x(pos_artikelnummer, betrag, pos_positionsnummer)

    where x.betrag is not null
      and x.betrag <> 0

)

select *
from final