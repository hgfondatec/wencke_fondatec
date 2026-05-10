{{ config(materialized='table') }}

with source_data as (

    select
        pos_2_1            as pos_belegart,
        pos_3_8            as pos_belegnummer,
        pos_18_25          as pos_artikelnummer,
        pos_45_60          as pos_artikeltext,
        pos_1734_9         as pos_rohertrag_vor_bonus,
        pos_596_10         as pos_rohertrag_verrechnet,
        pos_164_8          as pos_gesamtmenge,
        pos_280_12         as pos_gesamtumsatz_vor_bonus,
        pos_1754_7         as pos_umsatz_bonus_vorlaeufig,
        pos_1766_7         as pos_umsatz_bonus_endgueltig
    from {{ source('raw', 'm36pos') }}

)

select *
from source_data