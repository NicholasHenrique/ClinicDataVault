{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='practitioner_hk',
    src_nk='license_number',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_practitioners'
) }}
