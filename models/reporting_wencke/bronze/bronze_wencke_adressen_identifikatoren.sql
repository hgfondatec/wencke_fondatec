{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id, 
    gln, 
    gln_wencke, 
    leitwegs_id_grob, 
    leitwegs_id_fein, 
    leitwegs_id_pruefziffer, 
    zugferd_empfaenger_id, 
    filial_id, 
    id_traeger, 
    ident_quis, 
    kundennr_einkaufsgenossenschaft, 
    kundennr_ecolab, 
    filiale2_nr_lieferant, 
    filiale4_nr_lieferant, 
    filiale5_nr_lieferant, 
    topserv_statistik_nr, 
    topserv_lieferanten_nr

FROM {{ source('raw', 'wencke_lv_adressen_identifikatoren') }}