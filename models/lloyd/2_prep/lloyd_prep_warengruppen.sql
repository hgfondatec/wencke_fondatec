{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with warengruppen as (

    select 
        *
    from {{ ref('lloyd_bronze_warengruppen') }}

)

select 
    warengruppen.wg_nummer,
    warengruppen.wg_name,

    case
        when length(cast(warengruppen.wg_nummer as text)) = 2
            then 'Hauptwarengruppe'
        else 'Nebenwarengruppe'
    end as wg_typ

from warengruppen

order by warengruppen.wg_nummer