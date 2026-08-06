{{
    config(
        materialized='table',
        tags=['besuchsberichte']
    )
}}

with source_data as (

    select *
    from {{ ref('lloyd_bronze_besuchsberichte') }}

)

select
    *,
    '32'::varchar(10) as mandant_id,
    adressnummer || '_32' as mapping_adressnummer
from source_data