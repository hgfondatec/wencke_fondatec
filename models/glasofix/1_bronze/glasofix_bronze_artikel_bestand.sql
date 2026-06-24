{{
    config(
        materialized='table',
        tags=['bestand']
    )
}}

with source_data as (

    select distinct
        ART_1_25    as artikelnummer,
        ART_178_9   as art_ek_netto,
        --ART_1706_5 as art_lagereinheit,
        ART_4230_10 as bestand_l1,
        ART_4240_10 as beauftragt_l1,
        ART_4250_10 as verfuegbar_l1,
        ART_4260_10 as bestellt_l1,
        ART_4270_10 as bestelltzum_l1,
        ART_4280_8  as naechsterbestelltermin_l1,
        ART_4289_1  as ueberbestand_l1,
        ART_4468_8  as mindestbestand_l1,
        ART_4500_3  as reichweite_l1

    from {{ source('raw', 'm39art_lgr') }}

)

select *
from source_data