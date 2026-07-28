-- reference_hk is built the same way as appointment_hk / exam_hk
-- (type prefix + id), so it joins correctly to whichever hub applies
-- depending on reference_type ('APPOINTMENT' or 'EXAM').
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/payments/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(payment_id as bigint)                                                          as payment_id,
    reference_type,
    cast(reference_id as bigint)                                                        as reference_id,
    cast(amount as decimal(10, 2))                                                      as amount,
    payment_method,
    payment_status,
    cast(paid_at as timestamp)                                                          as paid_at,
    sha2(upper(trim(cast(payment_id as string))), 256)                                   as payment_hk,
    sha2(upper(trim(concat(reference_type, '-', cast(reference_id as string)))), 256)     as reference_hk,
    -- link hash key: one payment always references exactly one appointment OR
    -- one exam (never both), so this single column feeds both filtered links
    -- below (lnk_payment_appointment / lnk_payment_exam).
    sha2(upper(trim(concat_ws('-', cast(payment_id as string), reference_type, cast(reference_id as string)))), 256) as lnk_payment_hk,
    current_timestamp()                                                                  as load_date,
    'clinic_generator'                                                                   as record_source
from source
