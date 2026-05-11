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
        bel_19_10 as bel_belegdatum,
        bel_29_10 as bel_liefer_termindatum,
        bel_39_8 as bel_projektnummer,
        bel_232_8 as bel_vertreter,
        bel_393_12 as bel_warenwertnetto,
        bel_405_12 as bel_warenwertmwst,
        bel_429_12 as bel_belegnetto,
        bel_441_12 as bel_belegmwst,
        bel_574_10 as bel_interne_belegnummer,
        bel_592_8 as bel_lieferschein_nr,
        bel_747_8 as bel_blfanummer,
        bel_2040_1 as bel_belegtyp,
        bel_2257_60 as bel_kostenstelle,
        bel_2451_8 as bel_praesident3,
        bel_2461_8 as bel_praesident2,
        bel_2469_8 as bel_praesident1,
        bel_2966_10 as bel_gvsbelegnummer
    from {{ source('raw', 'm36bel') }}

)

select *
from source_data