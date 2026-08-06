{{
    config(
        materialized='table',
        tags=['besuchsberichte']
    )
}}

with source_data as (

    select distinct
        idbse0043_0_19   as adressnummer_berichtsnummer,
        idbse0043_19_8   as adressnummer,
        idbse0043_35_8   as projektnummer,
        idbse0043_43_8   as vertreter,
        idbse0043_64_10  as datum,
        idbse0043_74_8   as startzeit,
        idbse0043_82_8   as endezeit,
        idbse0043_90_8   as besuchsdauer_minuten,
        idbse0043_98_60  as besuchsgrund,
        idbse0043_274_10 as kampagnen_nr,
        idbse0043_643_10 as pan_prozess,
        idbse0043_653_10 as pan_aufgabe
    from {{ source('raw', 'm39idbse0043') }}

)

select *
from source_data