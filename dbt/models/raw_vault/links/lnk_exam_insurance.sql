-- Only exists for INSURANCE-visit exams (never SELF_PAY).
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_exam_insurance_hk',
    src_fk=['exam_hk', 'insurance_provider_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='int_exams_with_insurance'
) }}
