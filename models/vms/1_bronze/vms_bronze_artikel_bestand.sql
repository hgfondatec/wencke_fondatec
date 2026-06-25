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
        ART_1706_5  as art_lagereinheit,
        ART_138_8   as lieferantenbezeichnung,
        ART_1065_1  as gesperrter_artikel,
        ART_828_1   as auswahl_gesperrt,
        ART_6721_1  as gefahrstoff,

        ART_4230_10 as bestand_l1,
        ART_4240_10 as beauftragt_l1,
        ART_4250_10 as verfuegbar_l1,
        ART_4260_10 as bestellt_l1,
        ART_4270_10 as bestelltzum_l1,
        ART_4280_8  as naechsterbestelltermin_l1,
        ART_4289_1  as ueberbestand_l1,
        ART_4468_8  as mindestbestand_l1,
        ART_4500_3  as reichweite_l1,

        ART_4290_10 as bestand_l2,
        ART_4300_10 as beauftragt_l2,
        ART_4310_10 as verfuegbar_l2,
        ART_4320_10 as bestellt_l2,
        ART_4330_10 as bestelltzum_l2,
        ART_4340_8  as naechsterbestelltermin_l2,
        ART_4349_1  as ueberbestand_l2,
        ART_4476_8  as mindestbestand_l2,
        ART_4503_3  as reichweite_l2,

        ART_4350_10 as bestand_l3,
        ART_4360_10 as beauftragt_l3,
        ART_4370_10 as verfuegbar_l3,
        ART_4380_10 as bestellt_l3,
        ART_4390_10 as naechsterbestelltermin_l3,
        ART_4400_8  as naechstebestellmenge_l3,
        ART_4408_1  as ueberbestand_l3,
        ART_4484_8  as mindestbestand_l3,
        ART_4506_3  as reichweite_l3

    from {{ source('raw', 'm42art_lgr') }}

)

select *
from source_data