{{ 
    config(
        materialized='table',
        tags=['lager']
    ) 
}}

with source_data as (

    select distinct
        lag_1_8     as lager_id,
        lag_26_10   as lager_name1,
        lag_51_60   as lager_name2
    from {{ source('raw', 'm42lag') }}

)

select
    *
from source_data