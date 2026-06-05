{{
    config(
        materialized='table',
        tags=['mandant']
    )
}}

with mandant as (

    select *
    from {{ ref('wencke_bronze_mandanten') }}

)

select
    cast(mandant_id as varchar(255))         as mandant_id,
    cast(mandant_name as varchar(255))       as mandant_name,
    cast(mandant_zusatzinfo as varchar(255)) as mandant_zusatzinfo,
    cast(mandant_strasse as varchar(255))    as mandant_strasse,
    cast(mandant_plz as varchar(255))        as mandant_plz,
    cast(mandant_stadt as varchar(255))      as mandant_stadt

from mandant