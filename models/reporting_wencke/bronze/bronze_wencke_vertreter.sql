{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH vertreter AS (

   SELECT 

    distinct 
        mandant, 
        vtr_nr as ver_vertreternummer,
        vtr_name_anzeige as ver_vertretername,
        vtr_vorname,
        vtr_name,
        vtr_user_nr as vtr_user_nr,
        vtr_created_at as vtr_created_at

    FROM {{ source('raw', 'wencke_lv_vertreter') }}

)

SELECT *
FROM vertreter