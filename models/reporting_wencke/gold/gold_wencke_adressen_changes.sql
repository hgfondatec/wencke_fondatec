{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH snapshot_base AS (

    SELECT
        beleg_adress_key,
        adr_text,

        adr_vertreter_nr AS vertreter,

        NULLIF(TRIM(praesident_ebene_1_bezeichnung), '-') AS p1,
        NULLIF(TRIM(praesident_ebene_2_bezeichnung), '-') AS p2,
        NULLIF(TRIM(praesident_ebene_3_bezeichnung), '-') AS p3,

        dbt_valid_from,
        dbt_valid_to

    FROM snapshot.snapshot_gold_adressen

),

snapshot_history AS (

    SELECT
        *,

        LAG(adr_text) OVER (
            PARTITION BY beleg_adress_key
            ORDER BY dbt_valid_from
        ) AS adr_text_letzter_wert,

        LAG(vertreter) OVER (
            PARTITION BY beleg_adress_key
            ORDER BY dbt_valid_from
        ) AS vertreter_letzter_wert,

        LAG(p1) OVER (
            PARTITION BY beleg_adress_key
            ORDER BY dbt_valid_from
        ) AS p1_letzter_wert,

        LAG(p2) OVER (
            PARTITION BY beleg_adress_key
            ORDER BY dbt_valid_from
        ) AS p2_letzter_wert,

        LAG(p3) OVER (
            PARTITION BY beleg_adress_key
            ORDER BY dbt_valid_from
        ) AS p3_letzter_wert

    FROM snapshot_base

),

current_state AS (

    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY beleg_adress_key
            ORDER BY dbt_valid_from DESC
        ) AS rn

    FROM snapshot_history

)

SELECT
    beleg_adress_key,
    adr_text,

    vertreter,
    p1,
    p2,
    p3,

    dbt_valid_from AS letzter_stand,

    CASE
        WHEN adr_text IS DISTINCT FROM adr_text_letzter_wert
             AND adr_text_letzter_wert IS NOT NULL
        THEN 1
        ELSE 0
    END AS adr_text_änderung,

    CASE
        WHEN vertreter IS DISTINCT FROM vertreter_letzter_wert
             AND vertreter_letzter_wert IS NOT NULL
        THEN 1
        ELSE 0
    END AS vertreter_änderung,

    CASE
        WHEN p1 IS DISTINCT FROM p1_letzter_wert
             AND p1_letzter_wert IS NOT NULL
        THEN 1
        ELSE 0
    END AS p1_änderung,

    CASE
        WHEN p2 IS DISTINCT FROM p2_letzter_wert
             AND p2_letzter_wert IS NOT NULL
        THEN 1
        ELSE 0
    END AS p2_änderung,

    CASE
        WHEN p3 IS DISTINCT FROM p3_letzter_wert
             AND p3_letzter_wert IS NOT NULL
        THEN 1
        ELSE 0
    END AS p3_änderung,

    adr_text_letzter_wert,
    vertreter_letzter_wert,
    p1_letzter_wert,
    p2_letzter_wert,
    p3_letzter_wert

FROM current_state

WHERE rn = 1