{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='insurance_provider_hk',
    src_nk='ans_registration_number',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_insurance_providers'
) }}
