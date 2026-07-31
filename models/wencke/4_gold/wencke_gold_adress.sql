{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with final as (

    select concat(mapping_adressnummer,'_42') as key, vms.*, 42 as mandant_id, concat(adr_vertreternummer,'_42') as vertreter_key from {{ ref('vms_gold_adress') }} vms
    union
    select concat(mapping_adressnummer,'_36') as key, nonne.*, 36 as manadant_id, concat(adr_vertreternummer,'_36') as vertreter_key from {{ ref('nonne_gold_adress') }} nonne
    union
    select concat(mapping_adressnummer,'_32') as key, lloyd.*, 32 as manadant_id, concat(adr_vertreternummer,'_32') as vertreter_key from {{ ref('lloyd_gold_adress') }} lloyd
    union
    select concat(mapping_adressnummer,'_39') as key, glasofix.*, 39 as manadant_id, concat(adr_vertreternummer,'_39') as vertreter_key from {{ ref('glasofix_gold_adress') }} glasofix
    union
    select concat(mapping_adressnummer,'_38') as key, kernreich.*, 38 as manadant_id, concat(adr_vertreternummer,'_38') as vertreter_key from {{ ref('kernreich_gold_adress') }} kernreich

)

select
    *
from final
order by mapping_adressnummer