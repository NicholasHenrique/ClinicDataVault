-- Connects a feedback submission to both the patient (resolved via CPF,
-- since that's all the survey tool knows) and the appointment it was
-- about (resolved via the id we passed to the survey tool).
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_feedback_hk',
    src_fk=['feedback_hk', 'patient_hk', 'appointment_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_patient_feedback'
) }}
