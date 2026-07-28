-- A payment can reference either an appointment or an exam, never both.
-- Split into two links instead of one polymorphic link so each connects
-- to a single, well-defined hub (see stg_payments.reference_hk).
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_payment_hk',
    src_fk=['payment_hk', 'reference_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='int_payments_for_appointments'
) }}
