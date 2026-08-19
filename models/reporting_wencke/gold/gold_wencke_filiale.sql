{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH filiale AS (

    SELECT 

    *

    FROM {{ ref('bronze_wencke_filiale') }} AS a

)

SELECT

    f.*,
    CONCAT(f.mandant_id,'_',f.filiale_id) as mandant_filial_key

FROM filiale AS f