{{ config(materialized='incremental') }}

{{ automate_dv.sat(
    src_pk='patient_hk',
    src_hashdiff='hd_patient',
    src_payload=['name', 'cpf', 'birth_date', 'sex', 'phone', 'email', 'address', 'city', 'state'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='stg_patients'
) }}
