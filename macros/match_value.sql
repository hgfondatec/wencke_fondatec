{% macro match_value(field) %}

{% set nachhaltigkeit_felder = [
    'art_nachhaltiger_artikel',
    'art_nh_blauer_engel',
    'art_nh_eu_ecolabel',
    'art_nh_nordic_ecolabel',
    'art_nh_fsc',
    'art_nh_sonstiges'
] %}

{% set ist_nachhaltigkeit = field in nachhaltigkeit_felder %}

(
    WITH werte AS (

        SELECT
            {% if ist_nachhaltigkeit %}
                CASE
                    WHEN t39.art_artikelnummer IS NULL THEN NULL
                    WHEN LOWER(TRIM(t39.{{ field }}::text)) = 'true'
                        THEN 'true'
                    WHEN LOWER(TRIM(t39.{{ field }}::text)) = 'false'
                        THEN 'false'
                    ELSE 'nicht klassifiziert'
                END
            {% else %}
                NULLIF(TRIM(t39.{{ field }}::text), '')
            {% endif %} AS value

        UNION ALL

        SELECT
            {% if ist_nachhaltigkeit %}
                CASE
                    WHEN t32.art_artikelnummer IS NULL THEN NULL
                    WHEN LOWER(TRIM(t32.{{ field }}::text)) = 'true'
                        THEN 'true'
                    WHEN LOWER(TRIM(t32.{{ field }}::text)) = 'false'
                        THEN 'false'
                    ELSE 'nicht klassifiziert'
                END
            {% else %}
                NULLIF(TRIM(t32.{{ field }}::text), '')
            {% endif %}

        UNION ALL

        SELECT
            {% if ist_nachhaltigkeit %}
                CASE
                    WHEN t42.art_artikelnummer IS NULL THEN NULL
                    WHEN LOWER(TRIM(t42.{{ field }}::text)) = 'true'
                        THEN 'true'
                    WHEN LOWER(TRIM(t42.{{ field }}::text)) = 'false'
                        THEN 'false'
                    ELSE 'nicht klassifiziert'
                END
            {% else %}
                NULLIF(TRIM(t42.{{ field }}::text), '')
            {% endif %}

        UNION ALL

        SELECT
            {% if ist_nachhaltigkeit %}
                CASE
                    WHEN t36.art_artikelnummer IS NULL THEN NULL
                    WHEN LOWER(TRIM(t36.{{ field }}::text)) = 'true'
                        THEN 'true'
                    WHEN LOWER(TRIM(t36.{{ field }}::text)) = 'false'
                        THEN 'false'
                    ELSE 'nicht klassifiziert'
                END
            {% else %}
                NULLIF(TRIM(t36.{{ field }}::text), '')
            {% endif %}

    ),

    haeufigkeit AS (

        SELECT
            value,
            COUNT(*) AS score
        FROM werte
        WHERE value IS NOT NULL
        GROUP BY value

    ),

    beste_werte AS (

        SELECT
            value,
            score
        FROM haeufigkeit
        WHERE score = (
            SELECT MAX(score)
            FROM haeufigkeit
        )

    )

    SELECT
        CASE
            WHEN MAX(score) <= 1 THEN NULL

            ELSE STRING_AGG(
                CASE
                    WHEN '{{ field }}' = 'art_ek_netto'
                    THEN
                        REPLACE(
                            TO_CHAR(
                                NULLIF(
                                    REPLACE(value, ',', '.'),
                                    ''
                                )::numeric,
                                'FM999999999990D00'
                            ),
                            '.',
                            ','
                        )
                    ELSE value
                END,
                '///' ORDER BY value
            )
        END

    FROM beste_werte
)

{% endmacro %}