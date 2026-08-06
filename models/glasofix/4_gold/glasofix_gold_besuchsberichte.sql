{{
    config(
        materialized='table',
        tags=['besuchsberichte']
    )
}}

with source_data as (

    select *
    from {{ ref('glasofix_bronze_besuchsberichte') }}

)

select
    *,
    '39'::varchar(10) as mandant_id,
    adressnummer || '_39' as mapping_adressnummer
from source_data