{#
    Override dbt's default behavior of concatenating the connection's schema
    with a model's custom +schema (e.g. "bronze_raw_vault"). Each layer
    (raw_vault, business_vault, gold) needs an exact schema name.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
