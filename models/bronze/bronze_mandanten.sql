{{ config(materialized='table') }}

with source_data as (

    select
        distinct idbid0202_0_2           as mandant_id,
        idbid0202_2_30                   as mandant_name,
        idbid0202_32_30                  as mandant_zusatzinfo,
        idbid0202_92_30                  as mandant_strasse,
        idbid0202_122_5                  as mandant_plz,
        idbid0202_127_30                 as mandant_stadt
    from {{ source('raw', 'm00id0202') }}
    order by idbid0202_0_2

)

select *
from source_data