-- appointment_id is a real business key from the source system (the clinic's
-- own encounter id), so it earns its own hub even though it also
-- participates in links (lnk_appointment, lnk_payment_appointment, ...).
{{ config(materialized='incremental') }}

{{ automate_dv.hub(
    src_pk='appointment_hk',
    src_nk='appointment_id',
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_appointments'
) }}
