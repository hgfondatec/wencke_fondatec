{{
    config(
        materialized='table',
        tags=['lager']
    )
}}

with filiale_nonne_ref as (

    select
        lager_id::varchar(10)       as filiale_id,
        lager_name::varchar(255)    as filiale_name,
        firmenname::varchar(255)    as firmenname,
        firmenzusatz::varchar(255)  as firmenzusatz,
        filiale::varchar(255)       as filiale,
        adresse::varchar(255)       as adresse,
        plz::varchar(20)            as plz,
        ort::varchar(255)           as ort,
        lagergruppe::varchar(255)   as lagergruppe,
        -- land::varchar(10)        as land,
        '36'::varchar(10)           as mandant_id

    from {{ ref('nonne_bronze_filiale') }}

),

filiale_nonne as (

    select
        filiale_id,

        case
            when count(*) over () = 1 and filiale_id = '000'
                then 'L1'

            when filiale_id ~ '^[0-9]+$'
                then 'L' || cast(cast(filiale_id as integer) as varchar)

            else filiale_id
        end::varchar(10) as lager_id_mapping,
        filiale_name,
        firmenname,
        firmenzusatz,
        filiale,
        adresse,
        plz,
        ort,
        lagergruppe,
        -- land,
        mandant_id

    from filiale_nonne_ref

),

final as (

    select
        *,
        mandant_id || '_' || lager_id_mapping as mandant_lager_key
    from filiale_nonne

)

select *
from final