{% snapshot snapshot_artikel_check %}

{{
  config(
    target_schema='snapshot',
    unique_key='fact_key',
    strategy='check',
    check_cols='all'
  )
}}

select
    art_artikelnummer as fact_key,
    *
from {{ ref('wencke_gold_artikel_check') }}

{% endsnapshot %}