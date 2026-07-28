{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='exam_type_hk',
    src_hashdiff='hd_exam_type',
    src_payload=['name', 'category', 'self_pay_price'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_exam_types'
) }}
