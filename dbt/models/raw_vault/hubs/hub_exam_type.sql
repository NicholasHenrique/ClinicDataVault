{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='exam_type_hk',
    src_nk='tuss_code',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_exam_types'
) }}
