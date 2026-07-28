{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='facility_hk',
    src_nk='facility_id',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_facilities'
) }}
