{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='patient_hk',
    src_nk='patient_id',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_patients'
) }}
