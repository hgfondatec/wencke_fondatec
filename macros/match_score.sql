{% macro match_score(field) %}

(
    select max(score)
    from (
        select
            value,
            count(*) as score
        from (

            select t39.{{ field }}::text as value
            union all
            select t32.{{ field }}::text
            union all
            select t42.{{ field }}::text
            union all
            select t36.{{ field }}::text

        ) s
        where value is not null
        group by value
    ) x
)

{% endmacro %}