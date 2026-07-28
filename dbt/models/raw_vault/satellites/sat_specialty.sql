{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='specialty_hk',
    src_hashdiff='hd_specialty',
    src_payload=['name'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_specialties'
) }}
