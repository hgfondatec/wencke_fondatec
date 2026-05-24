{% snapshot snapshot_gold_facts %}

{{
  config(
    target_schema='snapshot',
    unique_key='fact_key',
    strategy='check',
    check_cols='all'
  )
}}

select
    concat_ws(
        '-',
        rechnung_beleg_nr,
        rechnnung_bel_datum,
        rechnung_artikel_nr,
        rechnung_positionsnummer
    ) as fact_key,
    *
from {{ ref('gold_facts') }}

{% endsnapshot %}