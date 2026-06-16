{{ 
    config(
        materialized='table',
        tags=['gold_facts']
    ) 
}}

with positionen AS (
    SELECT *
    FROM {{ ref('nonne_silver_rekla_positionen') }}
),

belege AS (
    SELECT *
    FROM {{ ref('nonne_prep_rekla_belege') }}
)


select *
from belege 
left join positionen
    on CAST(positionen.pos_belegnummer as varchar(12)) = belege.rekla_beleg_nr
order by belege.rekla_beleg_nr
