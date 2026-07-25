# Clínica DataVault

Projeto de portfólio: pipeline de dados de agendamento de clínica/hospital
(consultas, exames, status e pagamento particular), usando **arquitetura
medalhão** sobre um **Data Vault 2.0**.

## Arquitetura

```
GCS (raw)  →  Databricks Bronze  →  Silver: Raw Vault + Business Vault  →  Gold: Data Marts
Faker/Python   staging (as-is)      hub/link/sat · PIT/bridge/ref          star schema / BI
```

- **Bronze**: arquivos brutos gerados por este repositório (Python + Faker), pousados no GCS e lidos pelo Databricks via um Volume do Unity Catalog.
- **Silver — Raw Vault**: hubs, links e satélites carregados via dbt (`dbt-databricks` + `automate_dv`).
- **Silver — Business Vault**: regras de negócio, PIT e bridge tables para consulta performática.
- **Gold**: data marts (star schema) para consumo em BI.

## Domínio modelado

Pacientes, profissionais, unidades, especialidades, convênios, tipos de
exame, consultas e exames — cada um com **histórico de status**
(`AGENDADO`, `CONFIRMADO`, `CANCELADO`, `REAGENDADO`, `REALIZADO`,
`FALTOU`) e suporte a **atendimento particular** (com registro de
pagamento: forma, valor e status) além de convênio.

## Pré-requisitos (já configurados fora deste repo)

- Bucket GCS `clinic-datavault`, com service account `clinic-uploader` (permissão `storage.objectAdmin`).
- Databricks on GCP: catálogo `clinic_dv`, schemas `bronze`/`raw_vault`/`business_vault`/`gold`, Volume externo `clinic_dv.bronze.raw_files` apontando para `gs://clinic-datavault/raw`.
- SQL Warehouse ativo e um Personal Access Token gerado.

## Estrutura do repositório

```
.
├── .env.example              # modelo de variáveis de ambiente
├── requirements.txt
└── src/
    └── generator/
        ├── config.py          # leitura de configuração (.env)
        ├── domains.py         # listas de referência (status, formas de pagamento...)
        ├── generate_data.py   # gera os dados sintéticos em data/raw/
        └── upload_to_gcs.py   # envia data/raw/ para o bucket GCS
```

## Como rodar

1. Crie e ative o ambiente virtual:
   ```bash
   python -m venv .venv
   source .venv/Scripts/activate
   pip install -r requirements.txt
   ```
2. Copie `.env.example` para `.env` e ajuste os valores — em especial
   `GOOGLE_APPLICATION_CREDENTIALS`, apontando para a chave da service
   account **guardada fora deste repositório** (ex:
   `C:/Users/<usuario>/.gcp-keys/clinic-uploader-key.json`).
3. Gere os dados localmente:
   ```bash
   python -m src.generator.generate_data
   ```
   Os CSVs são gravados em `data/raw/<entidade>/` (pasta ignorada pelo Git).
4. Gere e já envie para o GCS:
   ```bash
   python -m src.generator.generate_data --upload
   ```
   Ou, se os arquivos já existem localmente, só envie:
   ```bash
   python -m src.generator.upload_to_gcs
   ```

## Roadmap

- [x] Ambiente (GCS, Databricks Unity Catalog, SQL Warehouse) configurado
- [x] Gerador de dados sintéticos (bronze / staging)
- [ ] Projeto dbt + `automate_dv` conectado ao Databricks
- [ ] Raw Vault: hubs, links, satélites
- [ ] Business Vault: PIT, bridge, regras de negócio
- [ ] Gold: data marts (star schema)
- [ ] Orquestração e testes
- [ ] Dashboard de consumo
