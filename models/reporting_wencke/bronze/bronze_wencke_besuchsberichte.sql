{{ config(
    materialized = 'table',
    schema = 'wencke',
    tags=['besuchsberichte']
) }}


WITH source_data AS (

    SELECT
        bes_adr_nr,
        bes_bericht_nr,
        mandant,
        wencke_id,
        adr_wencke_id,
        bes_ansprechpartner_nr,
        bes_vertreter_nr,
        bes_bediener,
        bes_datum,
        bes_startzeit,
        bes_endezeit,
        bes_dauer_minuten,
        bes_besuchsgrund,
        bes_nur_anp_bericht,
        bes_erfasst_von,
        bes_geaendert_von,
        created_at,
        updated_at

    FROM {{ source('raw', 'wencke_lv_besuchsberichte') }}

)

SELECT *
FROM source_data
