{{ 
    config(
        materialized='table',
        tags=['belege_position']
    ) 
}}

with raw_data as (

    select *
    from {{ source('raw', 'm42bel') }}

),

cleaned as (

    select
        *,
        trim(coalesce(bel_19_10, '')) as bel_19_clean,
        trim(coalesce(bel_29_10, '')) as bel_29_clean
    from raw_data

),

parsed as (

    select
        *,

        case 
            when bel_19_clean ~ '^\d{2}\.\d{2}\.\d{4}$'
            then substring(bel_19_clean, 1, 2)::int
        end as bel_19_day,

        case 
            when bel_19_clean ~ '^\d{2}\.\d{2}\.\d{4}$'
            then substring(bel_19_clean, 4, 2)::int
        end as bel_19_month,

        case 
            when bel_19_clean ~ '^\d{2}\.\d{2}\.\d{4}$'
            then substring(bel_19_clean, 7, 4)::int
        end as bel_19_year,

        case 
            when bel_29_clean ~ '^\d{2}\.\d{2}\.\d{4}$'
            then substring(bel_29_clean, 1, 2)::int
        end as bel_29_day,

        case 
            when bel_29_clean ~ '^\d{2}\.\d{2}\.\d{4}$'
            then substring(bel_29_clean, 4, 2)::int
        end as bel_29_month,

        case 
            when bel_29_clean ~ '^\d{2}\.\d{2}\.\d{4}$'
            then substring(bel_29_clean, 7, 4)::int
        end as bel_29_year

    from cleaned

),

source_data as (

    select
        bel_1_1                          as bel_belegstatus_a_n,
        bel_2_1                          as bel_belegart,
        bel_3_8                          as bel_belegnummer,
        bel_11_8                         as bel_adressnummer,

        case
            when bel_19_clean <> '00.00.0000'
             and bel_19_year between 1 and 9999
             and bel_19_month between 1 and 12
             and bel_19_day between 1 and extract(day from (
                    date_trunc('month', make_date(bel_19_year, bel_19_month, 1)) 
                    + interval '1 month - 1 day'
                 ))
            then make_date(bel_19_year, bel_19_month, bel_19_day)
            else null
        end                              as bel_belegdatum,

        case
            when bel_29_clean <> '00.00.0000'
             and bel_29_year between 1 and 9999
             and bel_29_month between 1 and 12
             and bel_29_day between 1 and extract(day from (
                    date_trunc('month', make_date(bel_29_year, bel_29_month, 1)) 
                    + interval '1 month - 1 day'
                 ))
            then make_date(bel_29_year, bel_29_month, bel_29_day)
            else null
        end                              as bel_liefer_termindatum,

        bel_39_8                         as bel_projektnummer,
        bel_232_8                        as bel_vertreter,
        bel_245_1                        as bel_steuerart,
        bel_263_12                       as bel_nk_frachtkostenpauschale,
        bel_275_12                       as bel_nk_verpackung,
        bel_287_12                       as bel_nk_mindermengenzuschlag,
        bel_299_12                       as bel_nk_fuell_abnutzgebuehr,
        bel_311_12                       as bel_nk_gefahrgut,
        bel_393_12                       as bel_warenwertnetto,
        bel_405_12                       as bel_warenwertmwst,
        bel_429_12                       as bel_belegnetto,
        bel_441_12                       as bel_belegmwst,
        bel_574_8                        as bel_interne_belegnummer,
        bel_592_8                        as bel_lieferschein_nr,
        bel_747_8                        as bel_blfanummer,
        bel_776_8                        as bel_heim,
        bel_2040_1                       as bel_belegtyp,
        bel_2808_1                       as bel_bonusbeleg,
        bel_2712_11                      as bel_urbeleg_nr,
        bel_1893_2                       as bel_beleggruppe

    from parsed

)

select *
from source_data