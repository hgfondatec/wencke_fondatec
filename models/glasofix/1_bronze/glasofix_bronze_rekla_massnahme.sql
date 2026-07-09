{{ config(materialized='table') }}

with source_data as (

    select
        idbid0236_0_6           as rekla_massnahme_id,
        idbid0236_6_1           as rekla_massnahme_merge_key,
        idbid0236_7_3           as rekla_massnahme_id_2,
        idbid0236_10_20         as rekla_massnahme_bezeichnung
        
    from {{ source('raw', 'm39idbid0236') }}

)

select *
from source_data