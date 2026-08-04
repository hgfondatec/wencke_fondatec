{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    
    *

FROM {{ ref('bronze_wencke_belege_adressen') }} b

WHERE adr_typ IN ('lfa')