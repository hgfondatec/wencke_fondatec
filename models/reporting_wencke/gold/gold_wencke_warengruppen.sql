{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH source_data AS (

    SELECT
        wencke_id,
        mandant,
        wg_nr

    FROM {{ ref('bronze_wencke_warengruppen') }}

),

deduplicated AS (

    SELECT
        wencke_id,
        mandant,
        wg_nr,
        ROW_NUMBER() OVER (
            PARTITION BY wencke_id
            ORDER BY mandant, wg_nr
        ) AS row_num

    FROM source_data

)

SELECT
    wencke_id,
    mandant,
    wg_nr

FROM deduplicated

WHERE row_num = 1