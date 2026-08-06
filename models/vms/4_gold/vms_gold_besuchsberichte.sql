{{
    config(
        materialized='table',
        tags=['besuchsberichte']
    )
}}

with source_data as (

    select *
    from {{ ref('vms_bronze_besuchsberichte') }}

)

select
    *,
    '42'::varchar(10) as mandant_id,
    adressnummer || '_42' as mapping_adressnummer
from source_data