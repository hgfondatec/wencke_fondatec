{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH source_data AS (

    SELECT distinct
        32                          AS mandant,
        idbid0236_6_1               AS rekla_massnahme_merge_key,
        idbid0236_10_20             AS rekla_massnahme_bezeichnung
    FROM {{ source('raw', 'm32idbid0236') }}

    UNION ALL

    SELECT distinct
        36                          AS mandant,
        idbid0236_6_1               AS rekla_massnahme_merge_key,
        idbid0236_10_20             AS rekla_massnahme_bezeichnung
    FROM {{ source('raw', 'm36idbid0236') }}

    UNION ALL

    SELECT distinct
        39                          AS mandant,
        idbid0236_6_1               AS rekla_massnahme_merge_key,
        idbid0236_10_20             AS rekla_massnahme_bezeichnung
    FROM {{ source('raw', 'm39idbid0236') }}

    UNION ALL

    SELECT distinct
        42                          AS mandant,
        idbid0236_6_1               AS rekla_massnahme_merge_key,
        idbid0236_10_20             AS rekla_massnahme_bezeichnung
    FROM {{ source('raw', 'm42idbid0236') }}

)

SELECT DISTINCT *
FROM source_data