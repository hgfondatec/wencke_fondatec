{{
    config(
        materialized='table',
        tags=['besuchsberichte']
    )
}}

select *
from {{ ref('m32_silver_besuchsberichte') }}

union all

select *
from {{ ref('m36_silver_besuchsberichte') }}

union all

select *
from {{ ref('m39_silver_besuchsberichte') }}

union all

select *
from {{ ref('m42_silver_besuchsberichte') }}