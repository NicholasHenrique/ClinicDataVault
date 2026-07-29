{{ config(materialized='incremental') }}

-- Multi-source hub: integrates our own patients with the partner clinic's
-- registry (see stg_partner_patients), both keyed on the same normalized
-- CPF hash — this is the payoff of using a universal business key.
{{ automate_dv.hub(
    src_pk='patient_hk',
    src_nk='cpf',
    src_ldts='load_date',
    src_source='record_source',
    source_model=['stg_patients', 'stg_partner_patients']
) }}
