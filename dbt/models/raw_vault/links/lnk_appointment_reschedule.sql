-- Self-referencing link: connects a rescheduled appointment to the
-- appointment it replaced. Only exists when rescheduled_from_id is set.
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_appointment_reschedule_hk',
    src_fk=['appointment_hk', 'rescheduled_from_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='int_appointments_rescheduled'
) }}
