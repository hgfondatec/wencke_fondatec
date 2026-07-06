{{ config(materialized='table') }}

with source_data as (

    select
        adr_2_8                              as adr_adressnummer,
        adr_20_30                            as adr_name,
        adr_50_30                            as adr_name_2,
        adr_80_30                            as adr_adresse,
        adr_110_10                           as adr_plz,
        adr_120_30                           as adr_stadt,
        adr_242_20                           as adr_nummer,
        adr_347_30                           as adr_ansprechpartner,
        adr_466_8                            as adr_vertreternummer,
        adr_498_8                            as adr_debitorenkonto,
        adr_482_8                            as adr_praesident,
        adr_681_8                            as adr_rechnungsempfaenger,
        adr_673_8                            as adr_heim,
        adr_689_8                            as adr_krankenkasse,
        adr_820_1                            as adr_oe_1,
        adr_821_1                            as adr_oe_2,
        adr_822_1                            as adr_oe_3,
        adr_823_1                            as adr_oe_4,
        adr_875_8                            as adr_zentrale_GVS_nummer,
        adr_1024_30                          as adr_name_3,
        adr_1219_2                           as adr_adresstyp,
        adr_1054_1                           as adr_servicehandbuch_vorhanden,
        adr_1055_1                           as adr_servicehandbuch_jahr,
        adr_1056_1                           as adr_servicehandbuch_monat,
        adr_1057_1                           as adr_dosiertechnik,
        adr_1058_1                           as adr_serviceintervall_anzahl_jaehrlich,
        adr_1059_1                           as adr_schulung,
        adr_1060_1                           as adr_letzte_schulung_jahr,
        adr_1061_1                           as adr_letzte_schulung_monat,
        adr_1062_1                           as adr_haende_hygieneplan_vorhanden,
        adr_1063_1                           as adr_gefahrstoffverzeichnis

    from {{ source('raw', 'm39adr') }}

)

select *
from source_data