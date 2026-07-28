{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/exam_status_history/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(exam_id as bigint)                                                as exam_id,
    status,
    cast(status_at as timestamp)                                           as status_at,
    sha2(upper(trim(concat('EXAM-', cast(exam_id as string)))), 256)        as exam_hk,
    sha2(concat_ws('||', coalesce(status, '')), 256)                        as hd_exam_status,
    current_timestamp()                                                    as load_date,
    'clinic_generator'                                                     as record_source
from source
