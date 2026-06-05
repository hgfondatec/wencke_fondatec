{{
    config(
        materialized='table',
        tags=['bestand']
    )
}}

with artikelbestand_glasofix_ref as (

    select
        cast(artikelnummer as varchar(255))                                         as artikelnummer,

        cast(nullif(replace(trim(bestand_l1), ',', '.'), '') as float)              as bestand_l1,
        cast(nullif(replace(trim(beauftragt_l1), ',', '.'), '') as float)           as beauftragt_l1,
        cast(nullif(replace(trim(verfuegbar_l1), ',', '.'), '') as float)           as verfuegbar_l1,
        cast(nullif(replace(trim(bestellt_l1), ',', '.'), '') as float)             as bestellt_l1,
        cast(bestelltzum_l1 as varchar(255))                                        as bestelltzum_l1,
        cast(naechsterbestelltermin_l1 as varchar(255))                             as naechsterbestelltermin_l1,
        cast(ueberbestand_l1 as varchar(1))                                         as ueberbestand_l1,
        cast(nullif(replace(trim(mindestbestand_l1), ',', '.'), '') as float)       as mindestbestand_l1,
        cast(nullif(replace(trim(reichweite_l1), ',', '.'), '') as float)           as reichweite_l1,

        cast(nullif(replace(trim(bestand_l2), ',', '.'), '') as float)              as bestand_l2,
        cast(nullif(replace(trim(beauftragt_l2), ',', '.'), '') as float)           as beauftragt_l2,
        cast(nullif(replace(trim(verfuegbar_l2), ',', '.'), '') as float)           as verfuegbar_l2,
        cast(nullif(replace(trim(bestellt_l2), ',', '.'), '') as float)             as bestellt_l2,
        cast(bestelltzum_l2 as varchar(255))                                        as bestelltzum_l2,
        cast(naechsterbestelltermin_l2 as varchar(255))                             as naechsterbestelltermin_l2,
        cast(ueberbestand_l2 as varchar(1))                                         as ueberbestand_l2,
        cast(nullif(replace(trim(mindestbestand_l2), ',', '.'), '') as float)       as mindestbestand_l2,
        cast(nullif(replace(trim(reichweite_l2), ',', '.'), '') as float)           as reichweite_l2,

        cast(nullif(replace(trim(bestand_l3), ',', '.'), '') as float)              as bestand_l3,
        cast(nullif(replace(trim(beauftragt_l3), ',', '.'), '') as float)           as beauftragt_l3,
        cast(nullif(replace(trim(verfuegbar_l3), ',', '.'), '') as float)           as verfuegbar_l3,
        cast(nullif(replace(trim(bestellt_l3), ',', '.'), '') as float)             as bestellt_l3,
        cast(naechsterbestelltermin_l3 as varchar(255))                             as naechsterbestelltermin_l3,
        cast(nullif(replace(trim(naechstebestellmenge_l3), ',', '.'), '') as float) as naechstebestellmenge_l3,
        cast(ueberbestand_l3 as varchar(1))                                         as ueberbestand_l3,
        cast(nullif(replace(trim(mindestbestand_l3), ',', '.'), '') as float)       as mindestbestand_l3,
        cast(nullif(replace(trim(reichweite_l3), ',', '.'), '') as float)           as reichweite_l3,

        cast(nullif(replace(trim(bestand_l5), ',', '.'), '') as float)              as bestand_l5,
        cast(nullif(replace(trim(beauftragt_l5), ',', '.'), '') as float)           as beauftragt_l5,
        cast(nullif(replace(trim(verfuegbar_l5), ',', '.'), '') as float)           as verfuegbar_l5,
        cast(nullif(replace(trim(bestellt_l5), ',', '.'), '') as float)             as bestellt_l5,
        cast(naechsterbestelltermin_l5 as varchar(255))                             as naechsterbestelltermin_l5,
        cast(nullif(replace(trim(naechstebestellmenge_l5), ',', '.'), '') as float) as naechstebestellmenge_l5,
        cast(ueberbestand_l5 as varchar(1))                                         as ueberbestand_l5,
        cast(nullif(replace(trim(mindestbestand_l5), ',', '.'), '') as float)       as mindestbestand_l5,
        cast(nullif(replace(trim(reichweite_l5), ',', '.'), '') as float)           as reichweite_l5

    from {{ ref('glasofix_bronze_artikel_bestand') }}

),

artikelbestand_glasofix as (

    select
        artikelnummer,
        cast('L1' as varchar(10))     as lager_id,
        bestand_l1                    as lagerbestand,
        beauftragt_l1                 as beauftragt,
        verfuegbar_l1                 as verfuegbar,
        bestellt_l1                   as bestellt,
        bestelltzum_l1                as bestelltzum,
        naechsterbestelltermin_l1     as naechster_bestelltermin,
        cast(null as float)           as naechste_bestellmenge,
        ueberbestand_l1               as ueberbestand,
        mindestbestand_l1             as mindestbestand,
        reichweite_l1                 as reichweite,
        cast('39' as varchar(10))     as mandant_id
    from artikelbestand_glasofix_ref

    union all

    select
        artikelnummer,
        cast('L2' as varchar(10))     as lager_id,
        bestand_l2                    as lagerbestand,
        beauftragt_l2                 as beauftragt,
        verfuegbar_l2                 as verfuegbar,
        bestellt_l2                   as bestellt,
        bestelltzum_l2                as bestelltzum,
        naechsterbestelltermin_l2     as naechster_bestelltermin,
        cast(null as float)           as naechste_bestellmenge,
        ueberbestand_l2               as ueberbestand,
        mindestbestand_l2             as mindestbestand,
        reichweite_l2                 as reichweite,
        cast('39' as varchar(10))     as mandant_id
    from artikelbestand_glasofix_ref

    union all

    select
        artikelnummer,
        cast('L3' as varchar(10))     as lager_id,
        bestand_l3                    as lagerbestand,
        beauftragt_l3                 as beauftragt,
        verfuegbar_l3                 as verfuegbar,
        bestellt_l3                   as bestellt,
        cast(null as varchar(255))    as bestelltzum,
        naechsterbestelltermin_l3     as naechster_bestelltermin,
        naechstebestellmenge_l3       as naechste_bestellmenge,
        ueberbestand_l3               as ueberbestand,
        mindestbestand_l3             as mindestbestand,
        reichweite_l3                 as reichweite,
        cast('39' as varchar(10))     as mandant_id
    from artikelbestand_glasofix_ref

    union all

    select
        artikelnummer,
        cast('L5' as varchar(10))     as lager_id,
        bestand_l5                    as lagerbestand,
        beauftragt_l5                 as beauftragt,
        verfuegbar_l5                 as verfuegbar,
        bestellt_l5                   as bestellt,
        cast(null as varchar(255))    as bestelltzum,
        naechsterbestelltermin_l5     as naechster_bestelltermin,
        naechstebestellmenge_l5       as naechste_bestellmenge,
        ueberbestand_l5               as ueberbestand,
        mindestbestand_l5             as mindestbestand,
        reichweite_l5                 as reichweite,
        cast('39' as varchar(10))     as mandant_id
    from artikelbestand_glasofix_ref

)

select *
from artikelbestand_glasofix