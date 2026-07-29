{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='feedback_hk',
    src_hashdiff='hd_feedback',
    src_payload=['rating', 'comments'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_patient_feedback'
) }}
