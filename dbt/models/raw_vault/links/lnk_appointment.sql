-- Core relationship of every appointment: always present.
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_appointment_hk',
    src_fk=['appointment_hk', 'patient_hk', 'practitioner_hk', 'facility_hk', 'specialty_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_appointments'
) }}
