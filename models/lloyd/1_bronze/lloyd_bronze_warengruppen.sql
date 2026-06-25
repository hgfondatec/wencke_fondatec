{{ config(materialized='table') }}

with source_data as (

    select
        dbk56_0_5                            as wg_nummer,
        dbk56_180_60                         as wg_name
    from {{ source('raw', 'm32nk') }}

)

select *
from source_data