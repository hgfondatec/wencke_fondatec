{{ config(materialized='table') }}

with lager_nonne_ref as (

    select
        lager_id                      as lager_id,
        lager_name_1                  as lager_name_1,
        lager_name_2                  as lager_name_2,
        cast('36' as varchar(2))      as mandant_id
    
    from {{ ref('nonne_bronze_lager') }}

)

select *
from lager_nonne_ref