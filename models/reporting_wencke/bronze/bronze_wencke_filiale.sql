{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}


WITH source_data AS (

    -- Lloyd (32)
    SELECT DISTINCT
        idbse0005_0_3,
        idbse0005_3_60,
        idbse0005_63_30,
        idbse0005_93_30,
        idbse0005_123_30,
        idbse0005_153_30,
        idbse0005_183_10,
        idbse0005_193_30,
        idbse0005_354_20,
        '32'::varchar(10) AS mandant_id
    FROM {{ source('raw', 'm32fil') }}

    UNION ALL

    -- Nonne (36)
    SELECT DISTINCT
        idbse0005_0_3,
        idbse0005_3_60,
        idbse0005_63_30,
        idbse0005_93_30,
        idbse0005_123_30,
        idbse0005_153_30,
        idbse0005_183_10,
        idbse0005_193_30,
        idbse0005_354_20,
        '36'::varchar(10) AS mandant_id
    FROM {{ source('raw', 'm36fil') }}

    UNION ALL

    -- Kernreich (38)
    SELECT DISTINCT
        idbse0005_0_3,
        idbse0005_3_60,
        idbse0005_63_30,
        idbse0005_93_30,
        idbse0005_123_30,
        idbse0005_153_30,
        idbse0005_183_10,
        idbse0005_193_30,
        idbse0005_354_20,
        '38'::varchar(10) AS mandant_id
    FROM {{ source('raw', 'm38fil') }}

    UNION ALL

    -- Glasofix (39)
    SELECT DISTINCT
        idbse0005_0_3,
        idbse0005_3_60,
        idbse0005_63_30,
        idbse0005_93_30,
        idbse0005_123_30,
        idbse0005_153_30,
        idbse0005_183_10,
        idbse0005_193_30,
        idbse0005_354_20,
        '39'::varchar(10) AS mandant_id
    FROM {{ source('raw', 'm39fil') }}

    UNION ALL

    -- VMS (42)
    SELECT DISTINCT
        idbse0005_0_3,
        idbse0005_3_60,
        idbse0005_63_30,
        idbse0005_93_30,
        idbse0005_123_30,
        idbse0005_153_30,
        idbse0005_183_10,
        idbse0005_193_30,
        idbse0005_354_20,
        '42'::varchar(10) AS mandant_id
    FROM {{ source('raw', 'm42fil') }}

),

filiale_mapping AS (

    SELECT
        idbse0005_0_3::varchar(10)      AS filiale_id,
        'L' || CAST(idbse0005_0_3 AS INTEGER)::varchar AS lager_id_mapping,
        idbse0005_3_60::varchar(255)    AS filiale_name,
        idbse0005_63_30::varchar(255)   AS firmenname,
        idbse0005_93_30::varchar(255)   AS firmenzusatz,
        idbse0005_123_30::varchar(255)  AS filiale,
        idbse0005_153_30::varchar(255)  AS adresse,
        idbse0005_183_10::varchar(20)   AS plz,
        idbse0005_193_30::varchar(255)  AS ort,
        idbse0005_354_20::varchar(255)  AS lagergruppe,
        mandant_id

    FROM source_data

),

final AS (

    SELECT
        *,
        mandant_id || '_' || lager_id_mapping AS mandant_lager_key

    FROM filiale_mapping

)

SELECT *
FROM final