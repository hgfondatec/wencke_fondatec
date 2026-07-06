{{ config(materialized='table') }}

with source_data as (

    select
        distinct TRUNC(agp_1_2)            as adrgruppe_id,
        agp_3_30                           as adrgruppe_name

    from {{ source('raw', 'm42adrgrp') }}

)

select *
from source_data