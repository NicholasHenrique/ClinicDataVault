-- Only exists for INSURANCE-visit appointments (never SELF_PAY).
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_appointment_insurance_hk',
    src_fk=['appointment_hk', 'insurance_provider_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='int_appointments_with_insurance'
) }}
