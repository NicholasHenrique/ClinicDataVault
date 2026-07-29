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
    -- business key is the ANS registration number (the Brazilian health
    -- insurance regulator's own identifier for this operator), not the
    -- internal insurance_provider_id.
    sha2(upper(trim(ans_registration_number)), 256)                          as insurance_provider_hk,
    sha2(concat_ws('||', coalesce(name, ''), coalesce(ans_registration_number, '')), 256) as hd_insurance_provider,
    current_timestamp()                                                      as load_date,
    'clinic_generator'                                                       as record_source
from source
