{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='exam_hk',
    src_nk='exam_id',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_exams'
) }}
