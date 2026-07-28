{{
    config(
        materialized='table',
        tags=['besuchsberichte']
    )
}}

with source_data as (

    select *
    from {{ ref('nonne_bronze_besuchsberichte') }}

)

select
    *,
    '36'::varchar(10) as mandant_id,
    adressnummer || '_36' as mapping_adressnummer
from source_data