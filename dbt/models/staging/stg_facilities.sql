-- Hash key convention: sha2(upper(trim(business_key)), 256) — see README "dbt project" section.
{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/facilities/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(facility_id as bigint)                                    as facility_id,
    name,
    address,
    city,
    state,
    phone,
    sha2(upper(trim(cast(facility_id as string))), 256)             as facility_hk,
    sha2(concat_ws('||',
        coalesce(name, ''), coalesce(address, ''), coalesce(city, ''),
        coalesce(state, ''), coalesce(phone, '')
    ), 256)                                                          as hd_facility,
    current_timestamp()                                             as load_date,
    'clinic_generator'                                              as record_source
from source
