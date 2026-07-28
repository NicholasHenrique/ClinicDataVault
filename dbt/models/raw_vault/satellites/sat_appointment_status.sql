-- src_ldts is status_at (the actual event time), not the generic load_date
-- column, so the history reconstructs the real status timeline instead of
-- collapsing every event onto whenever dbt happened to run.
{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='appointment_hk',
    src_hashdiff='hd_appointment_status',
    src_payload=['status'],
    src_ldts='status_at',
    src_source='record_source',
    source_model='stg_appointment_status_history'
) }}
