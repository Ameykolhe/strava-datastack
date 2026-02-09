{% macro seconds_to_time_display(seconds_expression) %}
    case
        when {{ seconds_expression }} is null then null
        when {{ seconds_expression }} >= 3600 then
            cast({{ seconds_expression }} / 3600 as int) || ':' ||
            lpad(cast(({{ seconds_expression }} % 3600) / 60 as int)::varchar, 2, '0') || ':' ||
            lpad(cast({{ seconds_expression }} % 60 as int)::varchar, 2, '0')
        else
            cast({{ seconds_expression }} / 60 as int) || ':' ||
            lpad(cast({{ seconds_expression }} % 60 as int)::varchar, 2, '0')
    end
{% endmacro %}
