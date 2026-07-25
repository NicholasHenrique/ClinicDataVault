{{ config(materialized='table') }}

with source as (
    select *
    from read_files(
        '/Volumes/clinic_dv/bronze/raw_files/insurance_providers/*.csv',
        format => 'csv',
        header => true,
        inferSchema => true
    )
)

select
    cast(insurance_provider_id as bigint)                                    as insurance_provider_id,
    name,
    ans_registration_number,
    sha2(upper(trim(cast(insurance_provider_id as string))), 256)            as insurance_provider_hk,
    current_timestamp()                                                      as load_date,
    'clinic_generator'                                                       as record_source
from source
