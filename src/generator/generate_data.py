"""Gera dados sintéticos do domínio de agendamento de clínica/hospital.

Simula 11 "tabelas de origem" (pacientes, profissionais, consultas, exames,
históricos de status e pagamentos particulares) e grava CSVs locais em
data/raw/<entidade>/. Use --upload para também enviar ao GCS.
"""

import argparse
import random
from datetime import datetime, timedelta
from pathlib import Path
import pandas as pd
from faker import Faker
from src.generator import domains
from src.generator.config import get_config

fake = Faker("pt_BR")

def _seed(seed: int) -> None:
    random.seed(seed)
    Faker.seed(seed)

# --------------------------------------------------------------------------
# Entidades cadastrais / de referência
# --------------------------------------------------------------------------
def generate_unidades(n: int) -> pd.DataFrame:
    rows = [
        {
            "unidade_id": i,
            "nome": f"Unidade {fake.city()}",
            "endereco": fake.street_address(),
            "cidade": fake.city(),
            "uf": fake.estado_sigla(),
            "telefone": fake.phone_number(),
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

def generate_especialidades() -> pd.DataFrame:
    rows = [{"especialidade_id": i + 1, "nome": nome} for i, nome in enumerate(domains.ESPECIALIDADES)]
    return pd.DataFrame(rows)

def generate_convenios(n: int) -> pd.DataFrame:
    rows = [
        {
            "convenio_id": i,
            "nome": f"{fake.company()} Saúde",
            "registro_ans": fake.numerify("######"),
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

def generate_tipos_exame() -> pd.DataFrame:
    rows = [
        {"exame_tipo_id": i + 1, "nome": nome, "categoria": categoria, "preco_particular": preco}
        for i, (nome, categoria, preco) in enumerate(domains.TIPOS_EXAME)
    ]
    return pd.DataFrame(rows)

def generate_profissionais(n: int, especialidades: pd.DataFrame, unidades: pd.DataFrame) -> pd.DataFrame:
    especialidade_ids = especialidades["especialidade_id"].tolist()
    unidade_ids = unidades["unidade_id"].tolist()
    rows = [
        {
            "profissional_id": i,
            "nome": f"Dr(a). {fake.name()}",
            "registro_conselho": fake.numerify(f"CRM-{fake.estado_sigla()}-######"),
            "especialidade_id": random.choice(especialidade_ids),
            "unidade_id": random.choice(unidade_ids),
            "telefone": fake.phone_number(),
            "email": fake.email(),
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

def generate_pacientes(n: int) -> pd.DataFrame:
    rows = [
        {
            "paciente_id": i,
            "nome": fake.name(),
            "cpf": fake.cpf(),
            "data_nascimento": fake.date_of_birth(minimum_age=0, maximum_age=95).isoformat(),
            "sexo": random.choice(["F", "M"]),
            "telefone": fake.phone_number(),
            "email": fake.email(),
            "endereco": fake.street_address(),
            "cidade": fake.city(),
            "uf": fake.estado_sigla(),
            "criado_em": fake.date_time_between(start_date="-3y", end_date="now").isoformat(),
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

# --------------------------------------------------------------------------
# Simulação de status (consulta e exame compartilham a mesma máquina de estados)
# --------------------------------------------------------------------------
def _build_status_history(data_agendada: datetime, now: datetime):
    """Retorna (eventos, status_final) plausíveis para uma consulta/exame.

    Respeita se a data agendada já passou ou ainda vai acontecer em relação
    a `now`, para não gerar por exemplo um "REALIZADO" no futuro.
    """
    lead_days = random.randint(1, 60)
    criado_em = data_agendada - timedelta(days=lead_days)
    if criado_em > now:
        criado_em = now - timedelta(hours=random.randint(1, 72))

    events = [("AGENDADO", criado_em)]
    is_future = data_agendada > now

    if is_future:
        outcome = random.choices(
            ["AGENDADO", "CONFIRMADO", "CANCELADO", "REAGENDADO"],
            weights=[45, 35, 12, 8],
        )[0]
    else:
        outcome = random.choices(
            ["REALIZADO", "CANCELADO", "FALTOU", "REAGENDADO"],
            weights=[70, 12, 10, 8],
        )[0]

    if outcome == "AGENDADO":
        return events, "AGENDADO"

    if outcome == "CONFIRMADO":
        events.append(("CONFIRMADO", criado_em + timedelta(days=random.randint(0, lead_days))))
        return events, "CONFIRMADO"

    if outcome == "REALIZADO":
        confirmado_em = criado_em + timedelta(days=random.randint(0, lead_days))
        events.append(("CONFIRMADO", min(confirmado_em, data_agendada)))
        events.append(("REALIZADO", data_agendada))
        return events, "REALIZADO"

    if outcome == "FALTOU":
        events.append(("FALTOU", data_agendada))
        return events, "FALTOU"

    if outcome == "CANCELADO":
        cancelado_em = criado_em + timedelta(days=random.randint(0, max(lead_days - 1, 1)))
        events.append(("CANCELADO", min(cancelado_em, data_agendada)))
        return events, "CANCELADO"

    # REAGENDADO
    reagendado_em = criado_em + timedelta(days=random.randint(0, max(lead_days - 1, 1)))
    events.append(("REAGENDADO", min(reagendado_em, data_agendada)))
    return events, "REAGENDADO"

# --------------------------------------------------------------------------
# Consultas e exames
# --------------------------------------------------------------------------
def generate_consultas(n: int, pacientes: pd.DataFrame, profissionais: pd.DataFrame, convenios: pd.DataFrame, now: datetime):
    pacientes_ids = pacientes["paciente_id"].tolist()
    profissionais_records = profissionais.to_dict("records")
    convenios_ids = convenios["convenio_id"].tolist()

    consultas_rows = []
    status_rows = []
    next_id = [1]

    def _nova_consulta(paciente_id, profissional, data_agendada, tipo_atendimento, convenio_id, origem_id=None):
        consulta_id = next_id[0]
        next_id[0] += 1
        events, status_final = _build_status_history(data_agendada, now)
        consultas_rows.append({
            "consulta_id": consulta_id,
            "consulta_origem_id": origem_id,
            "paciente_id": paciente_id,
            "profissional_id": profissional["profissional_id"],
            "especialidade_id": profissional["especialidade_id"],
            "unidade_id": profissional["unidade_id"],
            "data_agendada": data_agendada.isoformat(),
            "tipo_atendimento": tipo_atendimento,
            "convenio_id": convenio_id,
            "status_atual": status_final,
            "criado_em": events[0][1].isoformat(),
        })
        for status, ts in events:
            status_rows.append({"consulta_id": consulta_id, "status": status, "status_em": ts.isoformat()})
        return consulta_id, status_final

    for _ in range(n):
        paciente_id = random.choice(pacientes_ids)
        profissional = random.choice(profissionais_records)
        data_agendada = now + timedelta(
            days=random.randint(-150, 60),
            hours=random.choice([8, 9, 10, 11, 14, 15, 16, 17]),
        )
        tipo_atendimento = random.choices(["CONVENIO", "PARTICULAR"], weights=[65, 35])[0]
        convenio_id = random.choice(convenios_ids) if tipo_atendimento == "CONVENIO" else None

        consulta_id, status_final = _nova_consulta(
            paciente_id, profissional, data_agendada, tipo_atendimento, convenio_id
        )

        if status_final == "REAGENDADO":
            nova_data = data_agendada + timedelta(days=random.randint(3, 21))
            _nova_consulta(
                paciente_id, profissional, nova_data, tipo_atendimento, convenio_id, origem_id=consulta_id
            )

    return pd.DataFrame(consultas_rows), pd.DataFrame(status_rows)

def generate_exames(consultas: pd.DataFrame, tipos_exame: pd.DataFrame, now: datetime, taxa: float = 0.4):
    tipos_exame_ids = tipos_exame["exame_tipo_id"].tolist()
    rows = []
    status_rows = []
    exame_id = 1

    for _, consulta in consultas.iterrows():
        if random.random() > taxa:
            continue
        data_origem = datetime.fromisoformat(consulta["data_agendada"])
        data_exame = data_origem + timedelta(days=random.randint(0, 10))
        events, status_final = _build_status_history(data_exame, now)

        rows.append({
            "exame_id": exame_id,
            "consulta_origem_id": consulta["consulta_id"],
            "paciente_id": consulta["paciente_id"],
            "exame_tipo_id": random.choice(tipos_exame_ids),
            "unidade_id": consulta["unidade_id"],
            "data_agendada": data_exame.isoformat(),
            "tipo_atendimento": consulta["tipo_atendimento"],
            "convenio_id": consulta["convenio_id"],
            "status_atual": status_final,
            "criado_em": events[0][1].isoformat(),
        })
        for status, ts in events:
            status_rows.append({"exame_id": exame_id, "status": status, "status_em": ts.isoformat()})
        exame_id += 1

    return pd.DataFrame(rows), pd.DataFrame(status_rows)

# --------------------------------------------------------------------------
# Pagamentos (agendamento particular)
# --------------------------------------------------------------------------
def generate_pagamentos(consultas: pd.DataFrame, exames: pd.DataFrame, tipos_exame: pd.DataFrame):
    preco_por_exame = dict(zip(tipos_exame["exame_tipo_id"], tipos_exame["preco_particular"]))
    rows = []
    pagamento_id = 1

    def _status_pagamento(status_atual):
        if status_atual == "CANCELADO":
            return random.choices(["ESTORNADO", "CANCELADO"], weights=[70, 30])[0]
        if status_atual == "REALIZADO":
            return "PAGO"
        return random.choices(["PENDENTE", "PAGO"], weights=[60, 40])[0]

    def _add(referencia_tipo, referencia_id, status_atual, valor, referencia_data):
        nonlocal pagamento_id
        status_pagamento = _status_pagamento(status_atual)
        data_pagamento = None
        if status_pagamento in ("PAGO", "ESTORNADO"):
            data_pagamento = (referencia_data - timedelta(days=random.randint(0, 2))).isoformat()
        rows.append({
            "pagamento_id": pagamento_id,
            "referencia_tipo": referencia_tipo,
            "referencia_id": referencia_id,
            "valor": valor,
            "forma_pagamento": random.choice(domains.FORMAS_PAGAMENTO),
            "status_pagamento": status_pagamento,
            "data_pagamento": data_pagamento,
        })
        pagamento_id += 1

    for _, c in consultas[consultas["tipo_atendimento"] == "PARTICULAR"].iterrows():
        valor = round(random.uniform(150, 400), 2)
        _add("CONSULTA", c["consulta_id"], c["status_atual"], valor, datetime.fromisoformat(c["data_agendada"]))

    for _, e in exames[exames["tipo_atendimento"] == "PARTICULAR"].iterrows():
        base = preco_por_exame.get(e["exame_tipo_id"], 100.0)
        valor = round(base * random.uniform(0.9, 1.1), 2)
        _add("EXAME", e["exame_id"], e["status_atual"], valor, datetime.fromisoformat(e["data_agendada"]))

    return pd.DataFrame(rows)

# --------------------------------------------------------------------------
# Orquestração
# --------------------------------------------------------------------------
def run(cfg, out_dir: Path):
    _seed(cfg.seed)
    now = datetime.now()

    unidades = generate_unidades(cfg.n_unidades)
    especialidades = generate_especialidades()
    convenios = generate_convenios(cfg.n_convenios)
    tipos_exame = generate_tipos_exame()
    profissionais = generate_profissionais(cfg.n_profissionais, especialidades, unidades)
    pacientes = generate_pacientes(cfg.n_pacientes)
    consultas, consulta_status = generate_consultas(cfg.n_consultas, pacientes, profissionais, convenios, now)
    exames, exame_status = generate_exames(consultas, tipos_exame, now)
    pagamentos = generate_pagamentos(consultas, exames, tipos_exame)

    tables = {
        "unidades": unidades,
        "especialidades": especialidades,
        "convenios": convenios,
        "tipos_exame": tipos_exame,
        "profissionais": profissionais,
        "pacientes": pacientes,
        "consultas": consultas,
        "consulta_status_historico": consulta_status,
        "exames": exames,
        "exame_status_historico": exame_status,
        "pagamentos": pagamentos,
    }

    extraction_date = now.strftime("%Y-%m-%d")
    for nome, df in tables.items():
        entity_dir = out_dir / nome
        entity_dir.mkdir(parents=True, exist_ok=True)
        path = entity_dir / f"{nome}_{extraction_date}.csv"
        df.to_csv(path, index=False)
        print(f"[ok] {nome}: {len(df)} linhas -> {path}")

    return tables

def main():
    parser = argparse.ArgumentParser(description="Gerador de dados sintéticos - clínica/hospital")
    parser.add_argument("--upload", action="store_true", help="Envia os arquivos gerados ao GCS logo em seguida")
    args = parser.parse_args()

    cfg = get_config()
    out_dir = Path(cfg.local_output_dir)
    run(cfg, out_dir)

    if args.upload:
        from src.generator.upload_to_gcs import upload_directory
        upload_directory(out_dir, cfg.gcs_bucket_name, cfg.raw_prefix)

if __name__ == "__main__":
    main()