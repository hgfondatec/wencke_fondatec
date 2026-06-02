{{ config(materialized='table') }}

with beleggruppe as (
    select *
    from {{ ref('nonne_bronze_beleggruppe') }}
),

beleggruppe_mapping as (
    select *
    from {{ ref('raw_beleg_gruppe') }}
),

silver_beleggruppe  as (

    select *

    from beleggruppe _beleggruppe
    left join beleggruppe_mapping _beleggruppe_mapping
        on _beleggruppe_mapping."A_Belegart" = _beleggruppe.bg_beleggruppe
)
select *
from silver_beleggruppe 