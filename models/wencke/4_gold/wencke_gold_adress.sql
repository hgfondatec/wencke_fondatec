{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with final as (

    select concat(mapping_adressnummer,'_42') as key, vms.*, 42 as mandant_id from {{ ref('vms_gold_adress') }} vms
    union
    select concat(mapping_adressnummer,'_36') as key, nonne.*, 36 as manadant_id from {{ ref('nonne_gold_adress') }} nonne
    union
    select concat(mapping_adressnummer,'_32') as key, lloyd.*, 32 as manadant_id from {{ ref('lloyd_gold_adress') }} lloyd
    union
    select concat(mapping_adressnummer,'_39') as key, glasofix.*, 39 as manadant_id from {{ ref('glasofix_gold_adress') }} glasofix

)

select
    *
from final
order by mapping_adressnummer