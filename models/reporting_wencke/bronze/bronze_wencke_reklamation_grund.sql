{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH rekla_grund AS (

    SELECT
        32                                              AS mandant,
        idbid0234_0_3                                   AS rekla_grund_id,
        idbid0234_3_30                                  AS rekla_grund_bezeichnung
    FROM {{ source('raw', 'm32idbid0234') }}

    UNION ALL

    SELECT
        36                                              AS mandant,
        idbid0234_0_3                                   AS rekla_grund_id,
        idbid0234_3_30                                  AS rekla_grund_bezeichnung
    FROM {{ source('raw', 'm36idbid0234') }}

    UNION ALL

    SELECT
        39                                              AS mandant,
        idbid0234_0_3                                   AS rekla_grund_id,
        idbid0234_3_30                                  AS rekla_grund_bezeichnung
    FROM {{ source('raw', 'm39idbid0234') }}

    UNION ALL

    SELECT
        42                                              AS mandant,
        idbid0234_0_3                                   AS rekla_grund_id,
        idbid0234_3_30                                  AS rekla_grund_bezeichnung
    FROM {{ source('raw', 'm42idbid0234') }}

)

SELECT *
FROM rekla_grund