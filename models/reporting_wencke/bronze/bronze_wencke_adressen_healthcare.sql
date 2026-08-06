{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id, 
	pflegekasse,
	heim

FROM {{ source('raw', 'wencke_lv_adressen_healthcare') }}