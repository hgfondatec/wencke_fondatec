{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT
    
    lfa.wencke_id as wencke_id,
    lfa.adr_kurzname as lieferant_kurzname,
    lfa.adr_anrede as lieferant_anrede,
    lfa.adr_vorname as lieferant_vorname,
    lfa.adr_nachname as lieferant_nachname,
    lfa.adr_name1 as lieferant_name1,
    lfa.adr_name2 as lieferant_name2,
    lfa.adr_name3 as lieferant_name3 ,
    lfa.adr_strasse as lieferant_strasse,
    lfa.adr_hausnr as lieferant_hausnr,
    lfa.adr_plz as lieferant_plz,
    lfa.adr_ort as lieferant_ort

FROM {{ ref('bronze_wencke_belege_adressen') }} lfa

WHERE adr_typ IN ('lfa')