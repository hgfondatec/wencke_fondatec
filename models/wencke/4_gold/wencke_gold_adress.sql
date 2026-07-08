{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with final as (

    select vms.*, 42 as mandant_id from {{ ref('vms_gold_adress') }} vms
    union
    select nonne.*, 36 as manadant_id from {{ ref('nonne_gold_adress') }} nonne
    union
    select lloyd.*, 32 as manadant_id from {{ ref('lloyd_gold_adress') }} lloyd
    union
    select glasofix.*, 39 as manadant_id from {{ ref('glasofix_gold_adress') }} glasofix

)

select
    *
from final
order by mapping_adressnummer