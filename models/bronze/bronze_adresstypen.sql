{{ config(materialized='table') }}

with source_data as (

    select
        distinct dbk08_0_2           as adrtyp_id,
        dbk08_180_60                 as adrtyp_name
    from {{ source('raw', 'm36adrart') }}

)

select *
from source_data