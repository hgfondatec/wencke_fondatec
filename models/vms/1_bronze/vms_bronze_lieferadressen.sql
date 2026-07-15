{{ 
    config(
        materialized='table',
        tags=['lager']
    ) 
}}

with source_data as (

    select distinct
        idbid0208_0_8 as lfa_nr,
        idbid0208_8_8 as lfa_debitor,
        idbid0208_16_40 as lfa_name1, 
        idbid0208_56_40 as lfa_name2, 
        idbid0208_136_40 as lfa_strasse, 
        idbid0208_179_7 as lfa_plz, 
        idbid0208_186_40 as lfa_ort, 
        idbid0208_226_20 as lfa_telefon
       
    from {{ source('raw', 'm42idbid0208') }}

)

select
    *
from source_data