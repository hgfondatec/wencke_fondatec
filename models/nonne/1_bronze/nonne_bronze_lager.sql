{{ config(materialized='table') }}

with source_data as (

    select
        lag_1_8                              as lager_id,
        lag_1_8                              as lager_name_1,
        lag_51_60                            as lager_name_2
    from {{ source('raw', 'm36lag') }}

)

select *
from source_data