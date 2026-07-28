-- See lnk_payment_appointment.sql for why this is split in two.
{{ config(materialized='incremental') }}

{{ automate_dv.link(
    src_pk='lnk_payment_hk',
    src_fk=['payment_hk', 'reference_hk'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='int_payments_for_exams'
) }}
