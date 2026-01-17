{% macro safe_column(column_name, data_type='varchar', default_value='null', table_ref=none) %}
    {%- if table_ref -%}
        {%- set relation = table_ref -%}
    {%- else -%}
        {%- set relation = this -%}
    {%- endif -%}

    {%- set cols = adapter.get_columns_in_relation(relation) -%}
    {%- set col_names = cols | map(attribute='name') | list -%}

    {%- if column_name.lower() in col_names | map('lower') | list -%}
        {{ column_name }}
    {%- else -%}
        cast({{ default_value }} as {{ data_type }})
    {%- endif -%}
{% endmacro %}