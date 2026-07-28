-- Core detail of the exam itself (as opposed to its evolving status,
-- tracked separately in sat_exam_status).
{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='exam_hk',
    src_hashdiff='hd_exam_detail',
    src_payload=['scheduled_at', 'created_at'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_exams'
) }}
