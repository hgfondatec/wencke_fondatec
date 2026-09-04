{% snapshot snapshot_gold_adressen %}
 
{{
  config(
    target_schema='snapshot',
    unique_key='beleg_adress_key',
    strategy='check',
    check_cols='all'
  )
}}
 
SELECT
    *
from {{ ref('gold_wencke_adressen') }}
 
{% endsnapshot %}