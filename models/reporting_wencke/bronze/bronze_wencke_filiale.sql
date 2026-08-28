{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

with filialen as (

    select
        filiale_id,
        lager_id_mapping,
        filiale_name,
        firmenname,
        firmenzusatz,
        filiale,
        adresse,
        plz,
        ort,
        lagergruppe,
        mandant_id,
        mandant_lager_key
    from {{ ref('nonne_silver_filiale') }}

    union all

    select
        filiale_id,
        lager_id_mapping,
        filiale_name,
        firmenname,
        firmenzusatz,
        filiale,
        adresse,
        plz,
        ort,
        lagergruppe,
        mandant_id,
        mandant_lager_key
    from {{ ref('glasofix_silver_filiale') }}

    union all

    select
        filiale_id,
        lager_id_mapping,
        filiale_name,
        firmenname,
        firmenzusatz,
        filiale,
        adresse,
        plz,
        ort,
        lagergruppe,
        mandant_id,
        mandant_lager_key
    from {{ ref('lloyd_silver_filiale') }}

    union all

    select
        filiale_id,
        lager_id_mapping,
        filiale_name,
        firmenname,
        firmenzusatz,
        filiale,
        adresse,
        plz,
        ort,
        lagergruppe,
        mandant_id,
        mandant_lager_key
    from {{ ref('vms_silver_filiale') }}

    union all

    select
        filiale_id,
        lager_id_mapping,
        filiale_name,
        firmenname,
        firmenzusatz,
        filiale,
        adresse,
        plz,
        ort,
        lagergruppe,
        mandant_id,
        mandant_lager_key
    from {{ ref('kernreich_silver_filiale') }}

)

select *
from filialen