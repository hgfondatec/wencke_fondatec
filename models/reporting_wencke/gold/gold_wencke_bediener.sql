{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH vertreter AS (

    SELECT DISTINCT ON (
        mandant,
        vtr_user_nr
    )

        *,

        CONCAT(
            vtr_user_nr::text,
            '-',
            ver_vertretername,
            ' ',
            vtr_vorname
        ) AS bezeichnung,

        CONCAT(
            vtr_vorname,
            ' ',
            ver_vertretername
        ) AS verursacher,

        CONCAT(
            vtr_user_nr::text,
            '_',
            mandant::text
        ) AS bediener_key

    FROM {{ ref('bronze_wencke_vertreter') }}

    WHERE vtr_user_nr IS NOT NULL
      AND vtr_user_nr <> 0

    ORDER BY
        mandant,
        vtr_user_nr,
        vtr_created_at DESC NULLS LAST

)

SELECT *
FROM vertreter