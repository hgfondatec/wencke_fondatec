{{ config(materialized='table') }}

with source_data as (

    select
        distinct dbk30_0_60              as bg_beleggruppe,
        dbk30_60_1                       as bg_belegart,
        dbk30_70_2                       as bg_beleggruppe_id
    from {{ source('raw', 'm42bg') }}
    order by dbk30_70_2

)

select *
from source_data