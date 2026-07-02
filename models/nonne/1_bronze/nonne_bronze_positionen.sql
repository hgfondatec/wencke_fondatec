{{ 
    config(
        materialized='table',
        tags=['belege_position']
    ) 
}}

with source_data as (

    select
        pos_2_1            as pos_belegart,
        pos_1_1            as pos_beleg_status,
        pos_3_8            as pos_belegnummer,
        pos_11_6           as pos_positionsnummer,
        pos_17_1           as pos_zeilenstatus,
        pos_18_25          as pos_artikelnummer,
        pos_45_60          as pos_artikeltext,
        pos_164_8          as pos_gesamtmenge,
        pos_280_12         as pos_gesamtumsatz_vor_bonus,
        POS_308_12         as pos_ek_einzeln,
        pos_504_3          as pos_rekla_grund,
        pos_524_3          as pos_rekla_information,
        pos_527_17         as pos_rekla_verursacher,
        pos_574_12         as pos_gesamtumsatz,
        pos_596_10         as pos_gesamtrohertrag,
        pos_596_10         as pos_rohertrag_verrechnet,
        pos_1604_1         as pos_rekla_massnahme,
        pos_1734_9         as pos_rohertrag_vor_bonus,
        pos_1754_7         as pos_umsatz_bonus_vorlaeufig,
        pos_1766_7         as pos_umsatz_bonus_endgueltig
        

    from {{ source('raw', 'm36pos_test') }}

)

select *
from source_data