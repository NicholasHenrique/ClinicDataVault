{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/practitioners/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(practitioner_id as bigint)                                     as practitioner_id,
    name,
    license_number,
    cast(specialty_id as bigint)                                        as specialty_id,
    cast(facility_id as bigint)                                         as facility_id,
    phone,
    email,
    sha2(upper(trim(cast(practitioner_id as string))), 256)              as practitioner_hk,
    sha2(upper(trim(cast(specialty_id as string))), 256)                 as specialty_hk,
    sha2(upper(trim(cast(facility_id as string))), 256)                  as facility_hk,
    current_timestamp()                                                  as load_date,
    'clinic_generator'                                                   as record_source
from source
