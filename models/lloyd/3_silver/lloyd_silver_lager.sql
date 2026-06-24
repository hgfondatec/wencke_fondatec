{{
    config(
        materialized='table',
        tags=['lager']
    )
}}

with lager_lloyd_ref as (

    select
        lager_id::varchar(10)    as lager_id,
        lager_name1::varchar(255) as lager_name1,
        lager_name2::varchar(255) as lager_name2,
        '32'::varchar(10)        as mandant_id

    from {{ ref('lloyd_bronze_lager') }}

),

lager_lloyd as (

    select
        lager_id,
        lager_name1,
        lager_name2,
        mandant_id,
        mandant_id || '_' || lager_id as mandant_lager_key

    from lager_lloyd_ref

)

select *
from lager_lloyd