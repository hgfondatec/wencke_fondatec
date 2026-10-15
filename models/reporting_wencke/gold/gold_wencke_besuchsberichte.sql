
{{
    config(
        materialized = 'table',
        schema = 'wencke',
        tags = ['besuchsberichte']
    )
}}
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
    bes_besuchsgrund,
    bes_nur_anp_bericht,
    bes_adr_nr::text || '_' || mandant::text
        AS mapping_adressnummer

FROM {{ ref('bronze_wencke_besuchsberichte') }}
