{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with artikel_nonne as
(
    select * from {{ ref('nonne_gold_facts') }}

)



select
    *
from artikel_nonne