"""Central configuration, read from environment variables (.env)."""

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
    n_patients: int
    n_practitioners: int
    n_facilities: int
    n_insurance_providers: int
    n_appointments: int

def get_config() -> Config:
    return Config(
        gcp_project_id=os.getenv("GCP_PROJECT_ID", ""),
        gcs_bucket_name=os.getenv("GCS_BUCKET_NAME", "clinic-datavault"),
        raw_prefix=os.getenv("RAW_PREFIX", "raw"),
        local_output_dir=os.getenv("LOCAL_OUTPUT_DIR", "data/raw"),
        seed=int(os.getenv("SEED", "42")),
        n_patients=int(os.getenv("N_PATIENTS", "300")),
        n_practitioners=int(os.getenv("N_PRACTITIONERS", "40")),
        n_facilities=int(os.getenv("N_FACILITIES", "5")),
        n_insurance_providers=int(os.getenv("N_INSURANCE_PROVIDERS", "15")),
        n_appointments=int(os.getenv("N_APPOINTMENTS", "1500")),
    )