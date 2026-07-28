-- Core detail of the appointment itself (as opposed to its evolving status,
-- tracked separately in sat_appointment_status).
{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='appointment_hk',
    src_hashdiff='hd_appointment_detail',
    src_payload=['scheduled_at', 'created_at'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_appointments'
) }}
