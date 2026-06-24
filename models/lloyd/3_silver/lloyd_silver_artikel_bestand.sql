{{
    config(
        materialized='table',
        tags=['bestand']
    )
}}

with artikelbestand_lloyd_ref as (

    select
        artikelnummer::varchar(255) as artikelnummer,
        {{ safe_float('art_ek_netto') }}            as art_ek_netto,
        -- art_lagereinheit::varchar(255)           as art_lagereinheit,

        {{ safe_float('bestand_l1') }}              as bestand_l1,
        {{ safe_float('beauftragt_l1') }}           as beauftragt_l1,
        {{ safe_float('verfuegbar_l1') }}           as verfuegbar_l1,
        {{ safe_float('bestellt_l1') }}             as bestellt_l1,
        bestelltzum_l1::varchar(255)                as bestelltzum_l1,
        naechsterbestelltermin_l1::varchar(255)     as naechsterbestelltermin_l1,
        ueberbestand_l1::varchar(1)                 as ueberbestand_l1,
        {{ safe_float('mindestbestand_l1') }}       as mindestbestand_l1,
        {{ safe_float('reichweite_l1') }}           as reichweite_l1,

        {{ safe_float('bestand_l3') }}              as bestand_l3,
        {{ safe_float('beauftragt_l3') }}           as beauftragt_l3,
        {{ safe_float('verfuegbar_l3') }}           as verfuegbar_l3,
        {{ safe_float('bestellt_l3') }}             as bestellt_l3,
        naechsterbestelltermin_l3::varchar(255)     as naechsterbestelltermin_l3,
        {{ safe_float('naechstebestellmenge_l3') }} as naechstebestellmenge_l3,
        ueberbestand_l3::varchar(1)                 as ueberbestand_l3,
        {{ safe_float('mindestbestand_l3') }}       as mindestbestand_l3,
        {{ safe_float('reichweite_l3') }}           as reichweite_l3

    from {{ ref('lloyd_bronze_artikel_bestand') }}

),

artikelbestand_lloyd as (

    select
        artikelnummer,
        art_ek_netto,
        -- art_lagereinheit,
        'L1'::varchar(10)         as lager_id,
        bestand_l1                as lagerbestand,
        beauftragt_l1             as beauftragt,
        verfuegbar_l1             as verfuegbar,
        bestellt_l1               as bestellt,
        bestelltzum_l1            as bestelltzum,
        naechsterbestelltermin_l1 as naechster_bestelltermin,
        null::float               as naechste_bestellmenge,
        ueberbestand_l1           as ueberbestand,
        mindestbestand_l1         as mindestbestand,
        reichweite_l1             as reichweite,
        '32'::varchar(10)         as mandant_id,
        '32_L1'::varchar(20)      as mandant_lager_key
    from artikelbestand_lloyd_ref

    union all

    select
        artikelnummer,
        art_ek_netto,
        -- art_lagereinheit,
        'L3'::varchar(10)         as lager_id,
        bestand_l3                as lagerbestand,
        beauftragt_l3             as beauftragt,
        verfuegbar_l3             as verfuegbar,
        bestellt_l3               as bestellt,
        null::varchar(255)        as bestelltzum,
        naechsterbestelltermin_l3 as naechster_bestelltermin,
        naechstebestellmenge_l3   as naechste_bestellmenge,
        ueberbestand_l3           as ueberbestand,
        mindestbestand_l3         as mindestbestand,
        reichweite_l3             as reichweite,
        '32'::varchar(10)         as mandant_id,
        '32_L3'::varchar(20)      as mandant_lager_key
    from artikelbestand_lloyd_ref

)

select *
from artikelbestand_lloyd