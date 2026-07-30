{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_lv_belege_positionen_id,
    rekla_grund,
    verursacher_user,
    verursacher,
    massnahme,
    begruendung

FROM {{ source('raw', 'wencke_lv_belege_positionen_reklamation') }}