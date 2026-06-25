{{
    config(
        materialized='table',
        tags=['bestand']
    )
}}

with artikel_bestand as (

    select * from {{ ref('nonne_silver_artikel_bestand') }}

    union all

    select * from {{ ref('glasofix_silver_artikel_bestand') }}

    union all

    select * from {{ ref('lloyd_silver_artikel_bestand') }}

    union all

    select * from {{ ref('vms_silver_artikel_bestand') }}

)

select
   *
from artikel_bestand