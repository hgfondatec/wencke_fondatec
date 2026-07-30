{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH belege_positionen_reklamation AS (

    SELECT
        b.internal_id,
        b.wencke_id,
        b.mandant,
        b.bel_status,
        b.bel_nr,
        b.bel_steuer_art,
        b.bel_art,
        b.bel_beleg_gruppe,
        b.bg_beleggruppe,
        b.bel_final_adr_nr,
        b.bel_vertreter_nr,
        b.bel_date,
        b.bel_project_nr,
        b.bel_oe_5,
        b.ur_reklamation_index,

        p.pos_artikel_nr,
        p.pos_rekla_grund,
        p.pos_verursacher_user,
        p.pos_verursacher,
        p.pos_massnahme,
        p.pos_begruendung,

        rg.rekla_grund_bezeichnung,
        rm.rekla_massnahme_bezeichnung



    FROM {{ ref('silver_wencke_belege_reklamation') }} b

    INNER JOIN {{ ref('silver_wencke_belege_positionen_gesamt') }} p
        ON b.internal_id = p.wencke_lv_belege_id

    LEFT JOIN {{ ref('bronze_wencke_reklamation_grund') }} rg
        ON rg.rekla_grund_id = p.pos_rekla_grund
        and rg.mandant = b.mandant

    LEFT JOIN {{ ref('bronze_wencke_reklamation_massnahme') }} rm
        ON rm.rekla_massnahme_merge_key = p.pos_massnahme
        AND rm.mandant = b.mandant

    where rg.rekla_grund_bezeichnung is not null
)

SELECT
    *,

    CONCAT(
        COALESCE(bel_final_adr_nr::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS adress_key,

    CONCAT(
        COALESCE(pos_verursacher_user::text, ''),
        '_',
        COALESCE(mandant::text, '')
    ) AS bediener_key

FROM belege_positionen_reklamation