{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

SELECT 

    
    ekv_kunde AS adr_nr,
    ekv_mitglied_nr AS adr_ekv_nr,
    ekv_bis AS ekv_datum,
    ekv_aktiv AS ekv_aktiv,
    mandant AS ekv_mandant

FROM {{ source('raw', 'wencke_lv_ekv') }}