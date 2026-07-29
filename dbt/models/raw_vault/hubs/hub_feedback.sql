-- Transactional hub, like appointment/exam/payment: a specific feedback
-- submission is tied to whichever survey tool captured it.
{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='feedback_hk',
    src_nk='feedback_id',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_patient_feedback'
) }}
