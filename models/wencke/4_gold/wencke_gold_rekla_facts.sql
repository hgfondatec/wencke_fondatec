{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with final as (

    select concat(rekla_adress_nr,'_32') as adress_key, lloyd.*, 32 as mandant_id from {{ ref('lloyd_gold_rekla_facts') }} lloyd where rekla_grund is not null
    union
    select concat(rekla_adress_nr,'_36') as adress_key, nonne.*, 36 as mandant_id from {{ ref('nonne_gold_rekla_facts') }} nonne where rekla_grund is not null
    union
    select concat(rekla_adress_nr,'_39') as adress_key, glasofix.*, 39 as mandant_id from {{ ref('glasofix_gold_rekla_facts') }} glasofix where rekla_grund is not null
    union
    select concat(rekla_adress_nr,'_42') as adress_key, vms.*, 42 as mandant_id from {{ ref('vms_gold_rekla_facts') }} vms where rekla_grund is not null

)

select
    *
from final
order by adress_key