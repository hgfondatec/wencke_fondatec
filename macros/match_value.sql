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

        {% for alias in ['t39', 't32', 't42', 't36'] %}

            {% if not loop.first %}
                UNION ALL
            {% endif %}

            SELECT
                {% if ist_nachhaltigkeit %}
                    CASE
                        WHEN {{ alias }}.art_artikelnummer IS NULL
                            THEN NULL

                        WHEN LOWER(TRIM({{ alias }}.{{ field }}::text)) = 'true'
                            THEN 'true'

                        WHEN LOWER(TRIM({{ alias }}.{{ field }}::text)) = 'false'
                            THEN 'false'

                        ELSE 'nicht klassifiziert'
                    END
                {% else %}
                    NULLIF(
                        TRIM({{ alias }}.{{ field }}::text),
                        ''
                    )
                {% endif %} AS value

        {% endfor %}

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
            WHEN MAX(score) <= 1
                THEN NULL

            ELSE STRING_AGG(
                {% if field == 'art_ek_netto' %}
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
                {% else %}
                    value
                {% endif %},
                '///' ORDER BY value
            )
        END

    FROM beste_werte
)

{% endmacro %}