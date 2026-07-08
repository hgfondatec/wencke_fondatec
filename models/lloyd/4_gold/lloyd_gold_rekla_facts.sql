{{ 
    config(
        materialized='table',
        tags=['gold_facts']
    ) 
}}

with positionen AS (
    SELECT *
    FROM {{ ref('lloyd_silver_rekla_positionen') }}
),

belege AS (
    SELECT *
    FROM {{ ref('lloyd_prep_rekla_belege') }}
),

rekla_grund AS (
    SELECT *
    FROM {{ ref('lloyd_bronze_rekla_grund') }}
),

rekla_massnahme AS (
    SELECT 
        distinct rekla_massnahme_merge_key,
        rekla_massnahme_bezeichnung
    FROM {{ ref('lloyd_bronze_rekla_massnahme') }}
)


select 
    belege.rekla_beleg_nr,
    belege.rekla_urbeleg_nr,
    belege.rekla_bel_datum,
    CASE
        WHEN COALESCE(TRIM(belege.rekla_projektnummer), '') <> ''
        THEN TRIM(belege.rekla_heim)
     ELSE TRIM(belege.rekla_adressnummer)
    END AS rekla_adress_nr,
    concat(belege.rekla_belegart,belege.rekla_beleggruppe) as rekla_belegart,
    positionen.pos_artikelnummer as rekla_artikel_nr,
    positionen.pos_artikeltext as rekla_artikeltext,
    positionen.pos_rekla_verursacher as rekla_verursacher,
    rekla_grund.rekla_grund_bezeichnung as rekla_grund,
    rekla_massnahme.rekla_massnahme_bezeichnung as rekla_massnahme

from belege 
left join positionen
    on TRIM(positionen.pos_belegnummer) = TRIM(belege.rekla_beleg_nr)
left join rekla_grund
    on CAST(rekla_grund.rekla_grund_id as varchar(5)) = positionen.pos_rekla_grund
left join rekla_massnahme
    on rekla_massnahme.rekla_massnahme_merge_key  = positionen.pos_rekla_massnahme
order by belege.rekla_beleg_nr
