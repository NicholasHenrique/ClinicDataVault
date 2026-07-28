{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='payment_hk',
    src_nk='payment_id',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_payments'
) }}
