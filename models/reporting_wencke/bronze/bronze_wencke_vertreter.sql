{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH vertreter AS (

   SELECT 

    distinct 
        mandant, 
        vtr_nr as ver_vertreternummer,
        vtr_name_anzeige as ver_vertretername

    FROM {{ source('raw', 'wencke_lv_vertreter') }}

)

SELECT *
FROM vertreter