{{ config(materialized='table') }}

with source_data as (

    select
        adr_2_8                              as adr_adressnummer,
        adr_20_30                            as adr_name,
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
        adr_1219_2                           as adr_adresstyp
    from {{ source('raw', 'm39adr') }} 

)

select *
from source_data