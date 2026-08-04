{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    wencke_id,
    roh_vor_bonus,
    bonus_erledigt,
    bonus_betrag_endgueltig,
    bonus_betrag_vorlaeufig

FROM {{ source('raw', 'wencke_lv_belege_positionen_bonus') }}