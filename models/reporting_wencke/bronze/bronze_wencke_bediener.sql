{{ config(
    materialized = 'table',
    schema = 'wencke'
) }}

WITH bediener AS (

    SELECT

        mandant          AS mandant,
        wencke_id        AS wencke_id,
        bed_personal_nr  AS bed_personal_nr,
        bed_nr           AS bed_nr,
        bed_username     AS bed_username,
        bed_mail_sender  AS bed_mail_sender,
        bed_created_at   AS bed_created_at

    FROM {{ source('raw', 'wencke_lv_bw_user') }}


)

SELECT *
FROM bediener