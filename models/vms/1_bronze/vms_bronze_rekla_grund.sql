{{ config(materialized='table') }}

with source_data as (

    select
        idbid0234_0_3                              as rekla_grund_id,
        idbid0234_3_30                             as rekla_grund_bezeichnung,
        idbid0234_33_60                            as rekla_grund_beschreibung
        
    from {{ source('raw', 'm42idbid0234') }}

)

select *
from source_data