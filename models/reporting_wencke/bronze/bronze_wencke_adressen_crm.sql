{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id, 
	besuchsberichte_soll,
	besuch_ist,
    letzter_besuch,
    abc_manuell

FROM {{ source('raw', 'wencke_lv_adressen_crm') }}