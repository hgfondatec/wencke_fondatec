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
        CAST(pos_3_8 as varchar(20))              as pos_belegnummer,
        CAST(pos_11_6 as varchar(20))             as pos_positionsnummer,
        pos_17_1           as pos_zeilenstatus,
        pos_18_25          as pos_artikelnummer,
        pos_45_60          as pos_artikeltext,
        CAST(pos_164_8 as varchar(20))          as pos_gesamtmenge,
        CAST(pos_280_12 as varchar(20))          as pos_gesamtumsatz_vor_bonus,
        CAST(POS_308_12 as varchar(20))          as pos_ek_einzeln,
        pos_504_3          as pos_rekla_grund,
        pos_524_3          as pos_rekla_information,
        pos_527_17         as pos_rekla_verursacher,
        CAST(pos_574_12 as varchar(20))          as pos_gesamtumsatz,
        CAST(pos_596_10 as varchar(20))          as pos_gesamtrohertrag,
        CAST(pos_596_10 as varchar(20))          as pos_rohertrag_verrechnet,
        pos_1604_1         as pos_rekla_massnahme,
        CAST(pos_1734_9 as varchar(20))          as pos_rohertrag_vor_bonus,
        CAST(pos_1754_7 as varchar(20))          as pos_umsatz_bonus_vorlaeufig,
        CAST(pos_1766_7 as varchar(20))          as pos_umsatz_bonus_endgueltig
        

    from {{ source('raw', 'm42pos_test') }}

)

select *
from source_data