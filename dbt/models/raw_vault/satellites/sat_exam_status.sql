-- src_ldts is status_at (the actual event time) — see sat_appointment_status.sql.
{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='exam_hk',
    src_hashdiff='hd_exam_status',
    src_payload=['status'],
    src_ldts='status_at',
    src_source='record_source',
    source_model='stg_exam_status_history'
) }}
