{{ config(materialized='table') }}

with source_data as (

    SELECT DISTINCT
        vtr_2_8   AS ver_vertreternummer,
        vtr_20_30 AS ver_vertretername,
        CONCAT(TRIM(vtr_2_8), '-', vtr_20_30) AS ver_vertreternummer_name

    from {{ source('raw', 'm39vtr') }}

)

select *
from source_data