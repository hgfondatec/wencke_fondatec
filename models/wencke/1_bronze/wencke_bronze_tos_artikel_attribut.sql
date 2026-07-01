{{ config(materialized='table') }}

with source_data as (

    select
        distinct ar_nr              as ar_nr,
        art                         as ar_art,
        text                        as ar_text
    from {{ source('raw', 'tos_artikel_attribut') }}

)

select *
from source_data