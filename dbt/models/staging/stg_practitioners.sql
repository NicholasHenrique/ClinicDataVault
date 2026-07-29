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
    -- business key is the CRM license number (Brazil's regional medical
    -- council registration), not the internal practitioner_id: it's the
    -- real, portable identifier for this professional across any system.
    sha2(upper(trim(license_number)), 256)                                as practitioner_hk,
    sha2(concat_ws('||',
        coalesce(name, ''), coalesce(license_number, ''),
        coalesce(cast(specialty_id as string), ''), coalesce(cast(facility_id as string), ''),
        coalesce(phone, ''), coalesce(email, '')
    ), 256)                                                               as hd_practitioner,
    current_timestamp()                                                  as load_date,
    'clinic_generator'                                                   as record_source
from source
