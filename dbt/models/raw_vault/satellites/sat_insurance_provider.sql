{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='insurance_provider_hk',
    src_hashdiff='hd_insurance_provider',
    src_payload=['name', 'ans_registration_number'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_insurance_providers'
) }}
