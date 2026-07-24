{{
    config(
        materialized='table',
        tags=['artikel_check']
    ) 
}}

with final as (

    select lloyd.*, 32 as mandant_id, concat(ver_vertreternummer,'_32') as vertreter_key from {{ ref('lloyd_bronze_vertreter') }} lloyd
    union
    select nonne.*, 36 as mandant_id, concat(ver_vertreternummer,'_36') as vertreter_key from {{ ref('nonne_bronze_vertreter') }} nonne
    union
    select glasofix.*, 39 as mandant_id, concat(ver_vertreternummer,'_39') as vertreter_key from {{ ref('glasofix_bronze_vertreter') }} glasofix
    union
    select vms.*, 42 as mandant_id, concat(ver_vertreternummer,'_42') as vertreter_key from {{ ref('vms_bronze_vertreter') }} vms

)

select
    *
from final