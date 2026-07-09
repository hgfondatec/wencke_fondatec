{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with final as (

    select vms.*, 42 as mandant_id from {{ ref('vms_gold_rekla_facts') }} vms
    union
    select nonne.*, 36 as manadant_id from {{ ref('nonne_gold_rekla_facts') }} nonne
    union
    select lloyd.*, 32 as manadant_id from {{ ref('lloyd_gold_rekla_facts') }} lloyd
    union
    select glasofix.*, 39 as manadant_id from {{ ref('glasofix_gold_rekla_facts') }} glasofix

)

select
    *
from final