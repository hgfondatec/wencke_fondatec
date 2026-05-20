{{ config(materialized='table') }}

with belege as (

    select
        bel_adressnummer
    from {{ ref('bronze_belege') }}

),

adressen as (

    select
        adr_adressnummer,
        adr_name,
        adr_heim,
        adr_krankenkasse,
        adr_rechnungsempfaenger,
        adr_adresse,
        adr_plz,
        adr_stadt,
        adr_nummer,
        adr_adresstyp
    from {{ ref('bronze_adresse') }}

),

heim as (

    select
        heim_id,
        heim_name,
        heim_bezeichnung,
        heim_praesident_3,
        heim_praesident_2,
        heim_praesident_1
    from {{ ref('silver_heim') }}

),

krankenkasse as (

    select
        krankenkasse_id,
        krankenkasse_bezeichnung
    from {{ ref('silver_krankenkasse') }}

),

rechnungsempfaenger as (

    select
        rechnungsempfaenger_id,
        rechnungsempfaenger_bezeichnung
    from {{ ref('silver_re_empfaenger') }}

),

adressgruppe as (
    select 
        adrgruppe_id,
        adrgruppe_name
    from {{ ref('bronze_adressgruppe') }}
),

final as (

    select distinct
        b.bel_adressnummer as mapping_adressnummer,

        case 
            when a.adr_heim is null or a.adr_heim = ''
                then cast(b.bel_adressnummer as varchar(10))
            else a.adr_heim
        end as final_adressnummer,

        case 
            when a.adr_heim is null or a.adr_heim = ''
                then cast(b.bel_adressnummer as varchar(10))
                     || '-' || coalesce(a.adr_name, 'keine Bezeichnung')
            else h.heim_bezeichnung
        end as final_adress_name,

        a_heim.adr_adresse,
        a_heim.adr_plz,
        a_heim.adr_stadt,
        a_heim.adr_nummer,

        adressgruppe.adrgruppe_name,

        k.krankenkasse_id,
        k.krankenkasse_bezeichnung,

        r.rechnungsempfaenger_id,
        r.rechnungsempfaenger_bezeichnung,

        h.heim_praesident_3 as praesident_3,
        h.heim_praesident_2 as praesident_2,
        h.heim_praesident_1 as praesident_1

    from belege b

    left join adressen a
        on cast(b.bel_adressnummer as varchar(10)) = a.adr_adressnummer

    left join heim h
        on h.heim_id = a.adr_heim

    left join adressen a_heim
    on a_heim.adr_adressnummer = 
        case 
            when a.adr_heim is null or a.adr_heim = ''
                then cast(b.bel_adressnummer as varchar(10))
            else a.adr_heim
        end

    left join krankenkasse k
        on k.krankenkasse_id = a.adr_krankenkasse

    left join rechnungsempfaenger r
        on r.rechnungsempfaenger_id = a.adr_rechnungsempfaenger

    left join adressgruppe on 
        CAST(a.adr_adresstyp AS text) = CAST(adressgruppe.adrgruppe_id AS text)

)

select *
from final