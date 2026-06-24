{{ 
    config(
        materialized='table',
        tags=['lager']
    ) 
}}

with source_data as (

    select distinct
    idbse0005_0_3    as lager_id,
    idbse0005_3_60   as lager_name,
    idbse0005_63_30  as firmenname,
    idbse0005_93_30  as firmenzusatz,
    idbse0005_123_30 as filiale,
    idbse0005_153_30 as adresse,
    idbse0005_183_10 as plz,
    idbse0005_193_30 as ort,
    idbse0005_354_20 as lagergruppe
    --idbse0005_331_3  as land

from {{ source('raw', 'm42fil') }}
)

select
    *
from source_data