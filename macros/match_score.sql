{% macro match_score(field) %}

(
    select max(score)
    from (
        select
            value,
            count(*) as score
        from (

            select nullif(trim(t39.{{ field }}), '') as value
            union all
            select nullif(trim(t32.{{ field }}), '')
            union all
            select nullif(trim(t42.{{ field }}), '')
            union all
            select nullif(trim(t36.{{ field }}), '')

        ) s
        where value is not null
        group by value
    ) x
)

{% endmacro %}