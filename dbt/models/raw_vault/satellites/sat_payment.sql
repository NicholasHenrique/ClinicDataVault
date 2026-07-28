{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='payment_hk',
    src_hashdiff='hd_payment',
    src_payload=['amount', 'payment_method', 'payment_status', 'paid_at'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_payments'
) }}
