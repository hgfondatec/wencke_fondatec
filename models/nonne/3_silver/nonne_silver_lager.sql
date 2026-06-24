{{
    config(
        materialized='table',
        tags=['lager']
    )
}}

with lager_nonne_ref as (

    select
        lager_id::varchar(10)       as lager_id,
        lager_name1::varchar(255)   as lager_name1,
        lager_name2::varchar(255)   as lager_name2,
        '36'::varchar(10)           as mandant_id

    from {{ ref('nonne_bronze_lager') }}

),

lager_nonne as (

    select
        lager_id,
        lager_name1,
        lager_name2,
        mandant_id,
        mandant_id || '_' || lager_id as mandant_lager_key

    from lager_nonne_ref

)

select *
from lager_nonne