{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/exam_types/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(exam_type_id as bigint)                                    as exam_type_id,
    name,
    category,
    cast(self_pay_price as decimal(10, 2))                          as self_pay_price,
    tuss_code,
    -- business key is the TUSS code (the standard procedure code Brazilian
    -- insurers/clinics bill against), not the internal exam_type_id.
    sha2(upper(trim(tuss_code)), 256)                                as exam_type_hk,
    sha2(concat_ws('||',
        coalesce(name, ''), coalesce(category, ''), coalesce(cast(self_pay_price as string), '')
    ), 256)                                                           as hd_exam_type,
    current_timestamp()                                              as load_date,
    'clinic_generator'                                               as record_source
from source
