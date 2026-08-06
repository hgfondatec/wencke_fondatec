{{
    config(
        materialized='table',
        tags=['besuchsberichte']
    )
}}

select *
from {{ ref('lloyd_gold_besuchsberichte') }}

union all

select *
from {{ ref('nonne_gold_besuchsberichte') }}

union all

select *
from {{ ref('glasofix_gold_besuchsberichte') }}

union all

select *
from {{ ref('vms_gold_besuchsberichte') }}