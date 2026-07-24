{{ config(materialized='table') }}

with source_data as (

    SELECT DISTINCT
        vtr_2_8   AS ver_vertreternummer,
        vtr_20_30 AS ver_vertretername,
        CONCAT(vtr_2_8, '_', vtr_20_30) AS ver_vertreternummer_name

    from {{ source('raw', 'm39vtr') }}

)

select *
from source_data