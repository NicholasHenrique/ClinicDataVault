{{ config(materialized='incremental') }}

-- Multi-source satellite: a patient known to both systems gets one row per
-- source (different record_source, and often a different hashdiff, since
-- the partner clinic doesn't send birth_date/sex/address and may have
-- drifted contact details) — see dim_patient for how Gold picks a
-- "golden record" between them.
{{ automate_dv.sat(
    src_pk='patient_hk',
    src_hashdiff='hd_patient',
    src_payload=['name', 'cpf', 'birth_date', 'sex', 'phone', 'email', 'address', 'city', 'state'],
    src_ldts='load_date',
    src_source='record_source',
    source_model='int_patients_unioned'
) }}
