{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

SELECT

    wencke_id,  
    mandant, 
    adr_nr, 
    adr_kurzname, 
    adr_kurzbez, 
    adr_suchbegriff, 
    adr_adressart, 
    adr_adresstyp, 
    adr_adressgruppe, 
    adr_parent_adr,
    adr_re_empfaenger_nr,
    adr_firmenname, 
    adr_firmenname2, 
    adr_firmenname3, 
    adr_strasse, 
    adr_plz, 
    adr_ort, 
    adr_ortszusatz, 
    adr_land, 
    adr_bundesland, 
    adr_telefon, 
    adr_telefax, 
    adr_mobil, 
    adr_email,
    adr_vertreter_nr,   
    adr_hauptvertreter_nr, 
    adr_abc_kunde,
    adr_skonto1_prozent,
    adr_sort_kz
FROM {{ source('raw', 'wencke_lv_adressen') }}