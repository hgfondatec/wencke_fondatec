{% macro match_value(field) %}

(
    select
        case
            when max(score) <= 1 then null
            else string_agg(
                case
                    when '{{ field }}' = 'art_ek_netto'
                    then
                        replace(
                            to_char(
                                nullif(
                                    replace(
                                        replace(value, '.', ''),
                                        ',', '.'
                                    ),
                                    ''
                                )::numeric,
                                'FM999999999990D00'
                            ),
                            '.',
                            ','
                        )
                    else
                        value
                end,
                '/' order by value
            )
        end
    from (
        select
            value,
            count(*) as score
        from (
            select nullif(trim(t39.{{ field }}::text), '') as value
            union all
            select nullif(trim(t32.{{ field }}::text), '')
            union all
            select nullif(trim(t42.{{ field }}::text), '')
            union all
            select nullif(trim(t36.{{ field }}::text), '')
        ) s
        where value is not null
        group by value
    ) x
    where score = (
        select max(score)
        from (
            select
                value,
                count(*) as score
            from (
                select nullif(trim(t39.{{ field }}::text), '') as value
                union all
                select nullif(trim(t32.{{ field }}::text), '')
                union all
                select nullif(trim(t42.{{ field }}::text), '')
                union all
                select nullif(trim(t36.{{ field }}::text), '')
            ) s
            where value is not null
            group by value
        ) m
    )
)

{% endmacro %}