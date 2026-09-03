{% snapshot snapshot_vertreter_kunde_mapping %}
 
{{
  config(
    target_schema='snapshot',
    unique_key='adress_key',
    strategy='check',
    check_cols='all'
  )
}}
 
SELECT
    distinct
    CONCAT(adr_nr,'_',mandant) adress_key,
    adr_nr,
    mandant,
    adr_vertreter_nr
FROM {{ source('raw', 'wencke_lv_adressen') }}
 
{% endsnapshot %}