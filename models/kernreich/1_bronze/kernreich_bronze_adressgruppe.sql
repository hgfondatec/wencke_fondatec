{{ config(materialized='table') }}

with source_data as (

    select
        distinct TRIM(agp_0_60)            as adrgruppe_id,
        agp_60_8                           as adrgruppe_name

    from {{ source('raw', 'm38adrgrp') }}

)

select *
from source_data