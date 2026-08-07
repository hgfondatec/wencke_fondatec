{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH vertreter AS (

    SELECT DISTINCT

        32                                                  AS mandant,
        TRIM(vtr_2_8)                                       AS ver_vertreternummer,
        vtr_20_30                                           AS ver_vertretername

    from {{ source('raw', 'm32vtr') }}

    UNION ALL

    SELECT DISTINCT

        36                                                  AS mandant,
        TRIM(vtr_2_8)                                       AS ver_vertreternummer,
        vtr_20_30                                           AS ver_vertretername

    from {{ source('raw', 'm36vtr') }}

    UNION ALL

    SELECT DISTINCT

        38                                                  AS mandant,
        TRIM(vtr_2_8)                                       AS ver_vertreternummer,
        vtr_20_30                                           AS ver_vertretername

    from {{ source('raw', 'm38adr_vtr') }}

    UNION ALL

    SELECT DISTINCT

        39                                                  AS mandant,
        TRIM(vtr_2_8)                                       AS ver_vertreternummer,
        vtr_20_30                                           AS ver_vertretername

    from {{ source('raw', 'm39vtr') }}

    UNION ALL

    SELECT DISTINCT

        42                                                  AS mandant,
        TRIM(vtr_2_8)                                       AS ver_vertreternummer,
        vtr_20_30                                           AS ver_vertretername

    from {{ source('raw', 'm42vtr') }}

)

SELECT *
FROM vertreter