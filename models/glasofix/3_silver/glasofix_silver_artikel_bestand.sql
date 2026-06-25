{{
    config(
        materialized='table',
        tags=['bestand']
    )
}}

with artikelbestand_glasofix_ref as (

    select
        artikelnummer::varchar(255)                 as artikelnummer,
        {{ safe_float('art_ek_netto') }}            as art_ek_netto,
        art_lagereinheit::varchar(10)               as art_lagereinheit,
        lieferantenbezeichnung::varchar(6)          as lieferantenbezeichnung,
        gesperrter_artikel::varchar(1)              as gesperrter_artikel,
        auswahl_gesperrt::varchar(1)                as auswahl_gesperrt,
        {{ safe_float('bestand_l1') }}              as bestand_l1,
        {{ safe_float('beauftragt_l1') }}           as beauftragt_l1,
        {{ safe_float('verfuegbar_l1') }}           as verfuegbar_l1,
        {{ safe_float('bestellt_l1') }}             as bestellt_l1,
        bestelltzum_l1::varchar(255)                as bestelltzum_l1,
        naechsterbestelltermin_l1::varchar(255)     as naechsterbestelltermin_l1,
        ueberbestand_l1::varchar(1)                 as ueberbestand_l1,
        {{ safe_float('mindestbestand_l1') }}       as mindestbestand_l1,
        {{ safe_float('reichweite_l1') }}           as reichweite_l1

    from {{ ref('glasofix_bronze_artikel_bestand') }}

),

artikelbestand_glasofix as (

    select
        artikelnummer,
        art_ek_netto,
        art_lagereinheit,
        lieferantenbezeichnung,
        gesperrter_artikel,
        auswahl_gesperrt,
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
        '39'::varchar(10)         as mandant_id,
        '39_L1'::varchar(20)      as mandant_lager_key
    from artikelbestand_glasofix_ref

)

select *
from artikelbestand_glasofix