{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='facility_hk',
    src_hashdiff='hd_facility',
    src_payload=['name', 'address', 'city', 'state', 'phone'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_facilities'
) }}
