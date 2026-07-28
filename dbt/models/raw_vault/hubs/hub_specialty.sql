{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='specialty_hk',
    src_nk='specialty_id',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_specialties'
) }}
