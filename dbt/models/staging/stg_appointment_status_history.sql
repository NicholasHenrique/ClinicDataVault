{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/appointment_status_history/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(appointment_id as bigint)                                                as appointment_id,
    status,
    cast(status_at as timestamp)                                                  as status_at,
    sha2(upper(trim(concat('APPOINTMENT-', cast(appointment_id as string)))), 256) as appointment_hk,
    sha2(concat_ws('||', coalesce(status, '')), 256)                              as hd_appointment_status,
    current_timestamp()                                                           as load_date,
    'clinic_generator'                                                            as record_source
from source
