{{ 
    config(
        materialized='table',
        tags=['artikel']
    ) 
}}

with warengruppen as (

    select 
        *
    from {{ ref('kernreich_prep_warengruppen') }}

)

select 
    warengruppen.wg_nummer,
    warengruppen.wg_name
from warengruppen

where warengruppen.wg_typ = 'Nebenwarengruppe'

order by warengruppen.wg_nummer