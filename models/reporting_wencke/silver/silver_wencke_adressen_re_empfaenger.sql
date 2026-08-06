{{
    config(
        materialized = 'table',
        schema = 'wencke'
    )
}}

WITH re_empfaenger AS (

    SELECT DISTINCT
        adr_re_empfaenger_nr,
        mandant
    FROM {{ ref('bronze_wencke_adressen') }}
    WHERE adr_re_empfaenger_nr IS NOT NULL

),

adresse AS (

    SELECT
        adr.wencke_id,
        re.mandant,
        adr.adr_nr,
        adr.adr_firmenname,
        CONCAT(
            adr.adr_nr,
            '-',
            COALESCE(adr.adr_firmenname, 'keine Bezeichnung'),
            ' ',
            COALESCE(adr.adr_firmenname2, '')
        ) AS re_empfaenger_firmenname,
        adr.adr_parent_adr
    FROM re_empfaenger AS re
    LEFT JOIN {{ ref('bronze_wencke_adressen') }} AS adr
        ON re.adr_re_empfaenger_nr = adr.adr_nr
        AND re.mandant = adr.mandant

)

SELECT *
FROM adresse