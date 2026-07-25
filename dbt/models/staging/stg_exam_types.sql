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
    sha2(upper(trim(cast(exam_type_id as string))), 256)             as exam_type_hk,
    current_timestamp()                                              as load_date,
    'clinic_generator'                                               as record_source
from source
