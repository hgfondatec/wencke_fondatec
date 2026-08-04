{% snapshot snapshot_nw_check %}

{{
  config(
    target_schema='snapshot',
    unique_key='fact_key',
    strategy='check',
    check_cols='all'
  )
}}

select
    wg_nummer as fact_key,
    *
from {{ ref('wencke_gold_nebenwarengruppe_check') }}

{% endsnapshot %}