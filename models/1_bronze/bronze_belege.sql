{{ 
    config(
        materialized='table',
        tags=['belege_position']
    ) 
}}

with source_data as (

    select
        bel_1_1 as bel_belegstatus_a_n,
        bel_2_1 as bel_belegart,
        bel_3_8 as bel_belegnummer,
        bel_11_8 as bel_adressnummer,
        to_date(bel_19_10, 'DD.MM.YYYY') as bel_belegdatum,
        to_date(bel_29_10, 'DD.MM.YYYY') as bel_liefer_termindatum,
        bel_39_8 as bel_projektnummer,
        bel_232_8 as bel_vertreter,
        bel_245_1 as bel_steuerart,
        bel_263_12 as bel_nk_frachtkostenpauschale,
        bel_275_12 as bel_nk_verpackung,
        bel_287_12 as bel_nk_mindermengenzuschlag,
        bel_299_12 as bel_nk_fuell_abnutzgebuehr,
        bel_311_12 as bel_nk_gefahrgut,
        bel_393_12 as bel_warenwertnetto,
        bel_405_12 as bel_warenwertmwst,
        bel_429_12 as bel_belegnetto,
        bel_441_12 as bel_belegmwst,
        bel_574_8 as bel_interne_belegnummer,
        bel_592_8 as bel_lieferschein_nr,
        bel_747_8 as bel_blfanummer,
        bel_2040_1 as bel_belegtyp,
        --bel_2808_1 as bel_bonusbeleg,
        beleggruppe as bel_beleggruppe
    from {{ source('raw', 'm36bel') }}

)

select *
from source_data