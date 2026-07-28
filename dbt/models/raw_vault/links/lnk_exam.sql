-- Core relationship of every exam: always present (every exam originates
-- from an appointment in this generator, so source_appointment_hk is never null).
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_exam_hk',
    src_fk=['exam_hk', 'patient_hk', 'exam_type_hk', 'facility_hk', 'source_appointment_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_exams'
) }}
