"""Envia os arquivos locais de data/raw/ para o bucket GCS, mantendo a estrutura de pastas."""

from pathlib import Path
from google.cloud import storage
from src.generator.config import get_config

def upload_directory(local_dir: Path, bucket_name: str, raw_prefix: str) -> None:
    client = storage.Client()
    bucket = client.bucket(bucket_name)

    local_dir = Path(local_dir)
    files = list(local_dir.rglob("*.csv"))
    if not files:
        print(f"[aviso] nenhum arquivo .csv encontrado em {local_dir}")
        return

    for file_path in files:
        relative_path = file_path.relative_to(local_dir)
        blob_path = f"{raw_prefix}/{relative_path.as_posix()}"
        blob = bucket.blob(blob_path)
        blob.upload_from_filename(str(file_path))
        print(f"[ok] {file_path} -> gs://{bucket_name}/{blob_path}")

def main():
    cfg = get_config()
    upload_directory(Path(cfg.local_output_dir), cfg.gcs_bucket_name, cfg.raw_prefix)

if __name__ == "__main__":
    main()