{{
    config(
        materialized='table',
        tags=['bestand']
    )
}}

with artikelbestand_nonne_ref as (

    select
        artikelnummer::varchar(255)                 as artikelnummer,
        {{ safe_float('art_ek_netto') }}            as art_ek_netto,
        art_lagereinheit::varchar(10)               as art_lagereinheit,
        lieferantenbezeichnung::varchar(6)          as lieferantenbezeichnung,
        gesperrter_artikel::varchar(1)              as gesperrter_artikel,
        auswahl_gesperrt::varchar(1)                as auswahl_gesperrt,
        gefahrstoff::varchar(1)                     as gefahrstoff,

        {{ safe_float('bestand_l1') }}              as bestand_l1,
        {{ safe_float('beauftragt_l1') }}           as beauftragt_l1,
        {{ safe_float('verfuegbar_l1') }}           as verfuegbar_l1,
        {{ safe_float('bestellt_l1') }}             as bestellt_l1,
        bestelltzum_l1::varchar(255)                as bestelltzum_l1,
        naechsterbestelltermin_l1::varchar(255)     as naechsterbestelltermin_l1,
        ueberbestand_l1::varchar(1)                 as ueberbestand_l1,
        {{ safe_float('mindestbestand_l1') }}       as mindestbestand_l1,
        {{ safe_float('reichweite_l1') }}           as reichweite_l1,

        {{ safe_float('bestand_l2') }}              as bestand_l2,
        {{ safe_float('beauftragt_l2') }}           as beauftragt_l2,
        {{ safe_float('verfuegbar_l2') }}           as verfuegbar_l2,
        {{ safe_float('bestellt_l2') }}             as bestellt_l2,
        bestelltzum_l2::varchar(255)                as bestelltzum_l2,
        naechsterbestelltermin_l2::varchar(255)     as naechsterbestelltermin_l2,
        ueberbestand_l2::varchar(1)                 as ueberbestand_l2,
        {{ safe_float('mindestbestand_l2') }}       as mindestbestand_l2,
        {{ safe_float('reichweite_l2') }}           as reichweite_l2,

        {{ safe_float('bestand_l3') }}              as bestand_l3,
        {{ safe_float('beauftragt_l3') }}           as beauftragt_l3,
        {{ safe_float('verfuegbar_l3') }}           as verfuegbar_l3,
        {{ safe_float('bestellt_l3') }}             as bestellt_l3,
        naechsterbestelltermin_l3::varchar(255)     as naechsterbestelltermin_l3,
        {{ safe_float('naechstebestellmenge_l3') }} as naechstebestellmenge_l3,
        ueberbestand_l3::varchar(1)                 as ueberbestand_l3,
        {{ safe_float('mindestbestand_l3') }}       as mindestbestand_l3,
        {{ safe_float('reichweite_l3') }}           as reichweite_l3,

        {{ safe_float('bestand_l5') }}              as bestand_l5,
        {{ safe_float('beauftragt_l5') }}           as beauftragt_l5,
        {{ safe_float('verfuegbar_l5') }}           as verfuegbar_l5,
        {{ safe_float('bestellt_l5') }}             as bestellt_l5,
        naechsterbestelltermin_l5::varchar(255)     as naechsterbestelltermin_l5,
        {{ safe_float('naechstebestellmenge_l5') }} as naechstebestellmenge_l5,
        ueberbestand_l5::varchar(1)                 as ueberbestand_l5,
        {{ safe_float('mindestbestand_l5') }}       as mindestbestand_l5,
        {{ safe_float('reichweite_l5') }}           as reichweite_l5

    from {{ ref('nonne_bronze_artikel_bestand') }}

),

artikelbestand_nonne as (

    select
        artikelnummer,
        art_ek_netto,
        art_lagereinheit,
        lieferantenbezeichnung,
        gesperrter_artikel,
        auswahl_gesperrt,
        gefahrstoff,
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
        '36'::varchar(10)         as mandant_id,
        '36_L1'::varchar(20)      as mandant_lager_key
    from artikelbestand_nonne_ref

    union all

    select
        artikelnummer,
        art_ek_netto,
        art_lagereinheit,
        lieferantenbezeichnung,
        gesperrter_artikel,
        auswahl_gesperrt,
        gefahrstoff,
        'L2'::varchar(10)         as lager_id,
        bestand_l2                as lagerbestand,
        beauftragt_l2             as beauftragt,
        verfuegbar_l2             as verfuegbar,
        bestellt_l2               as bestellt,
        bestelltzum_l2            as bestelltzum,
        naechsterbestelltermin_l2 as naechster_bestelltermin,
        null::float               as naechste_bestellmenge,
        ueberbestand_l2           as ueberbestand,
        mindestbestand_l2         as mindestbestand,
        reichweite_l2             as reichweite,
        '36'::varchar(10)         as mandant_id,
        '36_L2'::varchar(20)      as mandant_lager_key
    from artikelbestand_nonne_ref

    union all

    select
        artikelnummer,
        art_ek_netto,
        art_lagereinheit,
        lieferantenbezeichnung,
        gesperrter_artikel,
        auswahl_gesperrt,
        gefahrstoff,
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
        '36'::varchar(10)         as mandant_id,
        '36_L3'::varchar(20)      as mandant_lager_key
    from artikelbestand_nonne_ref

    union all

    select
        artikelnummer,
        art_ek_netto,
        art_lagereinheit,
        lieferantenbezeichnung,
        gesperrter_artikel,
        auswahl_gesperrt,
        gefahrstoff,
        'L5'::varchar(10)         as lager_id,
        bestand_l5                as lagerbestand,
        beauftragt_l5             as beauftragt,
        verfuegbar_l5             as verfuegbar,
        bestellt_l5               as bestellt,
        null::varchar(255)        as bestelltzum,
        naechsterbestelltermin_l5 as naechster_bestelltermin,
        naechstebestellmenge_l5   as naechste_bestellmenge,
        ueberbestand_l5           as ueberbestand,
        mindestbestand_l5         as mindestbestand,
        reichweite_l5             as reichweite,
        '36'::varchar(10)         as mandant_id,
        '36_L5'::varchar(20)      as mandant_lager_key
    from artikelbestand_nonne_ref

)

select *
from artikelbestand_nonne