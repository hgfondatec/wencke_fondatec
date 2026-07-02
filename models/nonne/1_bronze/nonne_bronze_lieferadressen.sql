{{ 
    config(
        materialized='table',
        tags=['lager']
    ) 
}}

with source_data as (

    select distinct
        lfa_intern_index, 
        lfa_nr,
        lfa_debitor,
        lfa_name1, 
        lfa_name2, 
        lfa_name3,
        lfa_strasse, 
        lfa_land, 
        lfa_plz, 
        lfa_ort, 
        lfa_telefon, 
        lfa_fax, 
        lfa_gesperrt, 
        lfa_sammelrechnung_kz, 
        lfa_vtr_nr, 
        lfa_ecolab_nr, 
        lfa_liefzeit_von, 
        lfa_liefzeit_bis, 
        lfa_tour_nr, 
        lfa_interne_bez,
        lfa_liefzeit2_von,
        lfa_liefzeit2_bis, 
        lfa_letzte_orderliste, 
        lfa_rollcontainer, 
        lfa_drumcontainer, 
        lfa_umgesetzt_nach, 
        lfa_fp_deaktiviert, 
        lfa_anp_nr, 
        lfa_om_komm1, 
        lfa_om_komm2, 
        lfa_om_komm3, 
        lfa_mobil_nr, 
        lfa_latitude,
        lfa_longitude, 
        lfa_filiale, 
        lfa_gln, 
        lfa_daom_komm1, 
        lfa_daom_komm2, 
        lfa_daom_komm3, 
        lfa_steuer_landesart, 
        lfa_steuer_berechnung, 
        lfa_steuer_erloeszuordn, 
        lfa_ust_id
    from {{ source('raw', 'm36id0208') }}

)

select
    *
from source_data