{{
    config(
        materialized='table',
        tags=['bestand']
    )
}}

with source_data as (

    select distinct
        cast(ART_1_25    as varchar(255)) as artikelnummer,

        cast(ART_4230_10 as varchar(255)) as bestand_l1,
        cast(ART_4240_10 as varchar(255)) as beauftragt_l1,
        cast(ART_4250_10 as varchar(255)) as verfuegbar_l1,
        cast(ART_4260_10 as varchar(255)) as bestellt_l1,
        cast(ART_4270_10 as varchar(255)) as bestelltzum_l1,
        cast(ART_4280_8  as varchar(255)) as naechsterbestelltermin_l1,
        cast(ART_4289_1  as varchar(255)) as ueberbestand_l1,
        cast(ART_4468_8  as varchar(255)) as mindestbestand_l1,
        cast(ART_4500_3  as varchar(255)) as reichweite_l1,

        cast(ART_4290_10 as varchar(255)) as bestand_l2,
        cast(ART_4300_10 as varchar(255)) as beauftragt_l2,
        cast(ART_4310_10 as varchar(255)) as verfuegbar_l2,
        cast(ART_4320_10 as varchar(255)) as bestellt_l2,
        cast(ART_4330_10 as varchar(255)) as bestelltzum_l2,
        cast(ART_4340_8  as varchar(255)) as naechsterbestelltermin_l2,
        cast(ART_4349_1  as varchar(255)) as ueberbestand_l2,
        cast(ART_4476_8  as varchar(255)) as mindestbestand_l2,
        cast(ART_4503_3  as varchar(255)) as reichweite_l2,

        cast(ART_4350_10 as varchar(255)) as bestand_l3,
        cast(ART_4360_10 as varchar(255)) as beauftragt_l3,
        cast(ART_4370_10 as varchar(255)) as verfuegbar_l3,
        cast(ART_4380_10 as varchar(255)) as bestellt_l3,
        cast(ART_4390_10 as varchar(255)) as naechsterbestelltermin_l3,
        cast(ART_4400_8  as varchar(255)) as naechstebestellmenge_l3,
        cast(ART_4408_1  as varchar(255)) as ueberbestand_l3,
        cast(ART_4484_8  as varchar(255)) as mindestbestand_l3,
        cast(ART_4506_3  as varchar(255)) as reichweite_l3,

        cast(ART_4410_10 as varchar(255)) as bestand_l5,
        cast(ART_4420_10 as varchar(255)) as beauftragt_l5,
        cast(ART_4430_10 as varchar(255)) as verfuegbar_l5,
        cast(ART_4440_10 as varchar(255)) as bestellt_l5,
        cast(ART_4450_10 as varchar(255)) as naechsterbestelltermin_l5,
        cast(ART_4460_8  as varchar(255)) as naechstebestellmenge_l5,
        cast(ART_4409_1  as varchar(255)) as ueberbestand_l5,
        cast(ART_4492_8  as varchar(255)) as mindestbestand_l5,
        cast(ART_4509_3  as varchar(255)) as reichweite_l5

    from {{ source('raw', 'm32art') }}

)

select *
from source_data