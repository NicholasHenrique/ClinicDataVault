"""Configuração central do gerador, lida a partir de variáveis de ambiente (.env)."""

import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

@dataclass
class Config:
    gcp_project_id: str
    gcs_bucket_name: str
    raw_prefix: str
    local_output_dir: str
    seed: int
    n_pacientes: int
    n_profissionais: int
    n_unidades: int
    n_convenios: int
    n_consultas: int

def get_config() -> Config:
    return Config(
        gcp_project_id=os.getenv("GCP_PROJECT_ID", ""),
        gcs_bucket_name=os.getenv("GCS_BUCKET_NAME", "clinic-datavault"),
        raw_prefix=os.getenv("RAW_PREFIX", "raw"),
        local_output_dir=os.getenv("LOCAL_OUTPUT_DIR", "data/raw"),
        seed=int(os.getenv("SEED", "42")),
        n_pacientes=int(os.getenv("N_PACIENTES", "300")),
        n_profissionais=int(os.getenv("N_PROFISSIONAIS", "40")),
        n_unidades=int(os.getenv("N_UNIDADES", "5")),
        n_convenios=int(os.getenv("N_CONVENIOS", "15")),
        n_consultas=int(os.getenv("N_CONSULTAS", "1500")),
    )