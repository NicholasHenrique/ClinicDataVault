"""Generate synthetic data for a clinic/hospital scheduling domain.

Simulates 11 "source tables" (patients, practitioners, appointments, exams,
status histories and self-pay payment records) and writes bronze-layer CSVs
locally under data/raw/. Use --upload to also push them to GCS.
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
# Reference / master data entities
# --------------------------------------------------------------------------

def generate_facilities(n: int) -> pd.DataFrame:
    rows = [
        {
            "facility_id": i,
            # CNES is Brazil's national registry code for any healthcare
            # facility (public or private) — a real, source-independent
            # identifier, unlike an internal facility_id or the facility name.
            "cnes_code": fake.numerify("#######"),
            "name": f"{fake.city()} Facility",
            "address": fake.street_address(),
            "city": fake.city(),
            "state": fake.estado_sigla(),
            "phone": fake.phone_number()
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

def generate_specialties() -> pd.DataFrame:
    rows = [{"specialty_id": i + 1, "name": name} for i, name in enumerate(domains.SPECIALTIES)]
    return pd.DataFrame(rows)

def generate_insurance_providers(n: int) -> pd.DataFrame:
    rows = [
        {
            "insurance_provider_id": i,
            "name": f"{fake.company()} Health",
            "ans_registration_number": fake.numerify("######")
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

def generate_exam_types() -> pd.DataFrame:
    rows = [
        {
            "exam_type_id": i + 1,
            "name": name,
            "category": category,
            "self_pay_price": price,
            "tuss_code": tuss_code
        }
        for i, (name, category, price, tuss_code) in enumerate(domains.EXAM_TYPES)
    ]
    return pd.DataFrame(rows)

def generate_practitioners(n: int, specialties: pd.DataFrame, facilities: pd.DataFrame) -> pd.DataFrame:
    specialty_ids = specialties["specialty_id"].tolist()
    facility_ids = facilities["facility_id"].tolist()
    rows = [
        {
            "practitioner_id": i,
            "name": f"Dr. {fake.name()}",
            # CRM is Brazil's regional medical council registration number
            "license_number": fake.numerify(f"CRM-{fake.estado_sigla()}-######"),
            "specialty_id": random.choice(specialty_ids),
            "facility_id": random.choice(facility_ids),
            "phone": fake.phone_number(),
            "email": fake.email()
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

def generate_patients(n: int) -> pd.DataFrame:
    rows = [
        {
            "patient_id": i,
            "name": fake.name(),
            "cpf": fake.cpf(),
            "birth_date": fake.date_of_birth(minimum_age=0, maximum_age=95).isoformat(),
            "sex": random.choice(["F", "M"]),
            "phone": fake.phone_number(),
            "email": fake.email(),
            "address": fake.street_address(),
            "city": fake.city(),
            "state": fake.estado_sigla(),
            "created_at": fake.date_time_between(start_date="-3y", end_date="now").isoformat()
        }
        for i in range(1, n + 1)
    ]
    return pd.DataFrame(rows)

def generate_partner_patients(patients: pd.DataFrame, n_new: int, overlap_rate: float) -> pd.DataFrame:
    """Simulates a second source system: a partner clinic with its own
    patient registry. Some rows describe people we already know (same CPF,
    a different internal id, and contact details that may have drifted —
    exactly the multi-source integration/survivorship problem a hub with a
    universal business key is meant to solve); the rest are patients only
    the partner clinic has ever seen. Note this feed never sends
    birth_date/sex/address — a different source, a different schema.
    """
    patient_records = patients.to_dict("records")
    n_overlap = int(len(patient_records) * overlap_rate)
    overlapping = random.sample(patient_records, min(n_overlap, len(patient_records)))

    rows = []
    partner_patient_id = 1

    for p in overlapping:
        rows.append({
            "partner_patient_id": partner_patient_id,
            "cpf": p["cpf"],
            "name": p["name"],
            "phone": p["phone"] if random.random() > 0.3 else fake.phone_number(),
            "email": p["email"] if random.random() > 0.3 else fake.email(),
            "city": p["city"],
            "state": p["state"],
            "registered_at": fake.date_time_between(start_date="-2y", end_date="now").isoformat()
        })
        partner_patient_id += 1

    for _ in range(n_new):
        rows.append({
            "partner_patient_id": partner_patient_id,
            "cpf": fake.cpf(),
            "name": fake.name(),
            "phone": fake.phone_number(),
            "email": fake.email(),
            "city": fake.city(),
            "state": fake.estado_sigla(),
            "registered_at": fake.date_time_between(start_date="-2y", end_date="now").isoformat()
        })
        partner_patient_id += 1

    return pd.DataFrame(rows)

# --------------------------------------------------------------------------
# Status simulation (appointments and exams share the same state machine)
# --------------------------------------------------------------------------
def _build_status_history(scheduled_at: datetime, now: datetime):
    """Return a plausible (events, final_status) pair for an appointment/exam.

    Respects whether the scheduled date has already passed relative to
    `now`, so we never generate e.g. a "COMPLETED" event in the future.
    """
    lead_days = random.randint(1, 60)
    created_at = scheduled_at - timedelta(days=lead_days)
    if created_at > now:
        created_at = now - timedelta(hours=random.randint(1, 72))

    events = [("SCHEDULED", created_at)]
    is_future = scheduled_at > now

    if is_future:
        outcome = random.choices(
            ["SCHEDULED", "CONFIRMED", "CANCELLED", "RESCHEDULED"],
            weights=[45, 35, 12, 8]
        )[0]
    else:
        outcome = random.choices(
            ["COMPLETED", "CANCELLED", "NO_SHOW", "RESCHEDULED"],
            weights=[70, 12, 10, 8]
        )[0]

    if outcome == "SCHEDULED":
        return events, "SCHEDULED"

    if outcome == "CONFIRMED":
        events.append(("CONFIRMED", created_at + timedelta(days=random.randint(0, lead_days))))
        return events, "CONFIRMED"

    if outcome == "COMPLETED":
        confirmed_at = created_at + timedelta(days=random.randint(0, lead_days))
        events.append(("CONFIRMED", min(confirmed_at, scheduled_at)))
        events.append(("COMPLETED", scheduled_at))
        return events, "COMPLETED"

    if outcome == "NO_SHOW":
        events.append(("NO_SHOW", scheduled_at))
        return events, "NO_SHOW"

    if outcome == "CANCELLED":
        cancelled_at = created_at + timedelta(days=random.randint(0, max(lead_days - 1, 1)))
        events.append(("CANCELLED", min(cancelled_at, scheduled_at)))
        return events, "CANCELLED"

    # RESCHEDULED
    rescheduled_at = created_at + timedelta(days=random.randint(0, max(lead_days - 1, 1)))
    events.append(("RESCHEDULED", min(rescheduled_at, scheduled_at)))
    return events, "RESCHEDULED"

# --------------------------------------------------------------------------
# Appointments and exams
# --------------------------------------------------------------------------
def generate_appointments(n: int, patients: pd.DataFrame, practitioners: pd.DataFrame, insurance_providers: pd.DataFrame, now: datetime):
    patient_ids = patients["patient_id"].tolist()
    practitioner_records = practitioners.to_dict("records")
    insurance_provider_ids = insurance_providers["insurance_provider_id"].tolist()

    appointment_rows = []
    status_rows = []
    next_id = [1]

    def _new_appointment(patient_id, practitioner, scheduled_at, visit_type, insurance_provider_id, rescheduled_from_id=None):
        appointment_id = next_id[0]
        next_id[0] += 1
        events, final_status = _build_status_history(scheduled_at, now)
        appointment_rows.append({
            "appointment_id": appointment_id,
            "rescheduled_from_id": rescheduled_from_id,
            "patient_id": patient_id,
            "practitioner_id": practitioner["practitioner_id"],
            "specialty_id": practitioner["specialty_id"],
            "facility_id": practitioner["facility_id"],
            "scheduled_at": scheduled_at.isoformat(),
            "visit_type": visit_type,
            "insurance_provider_id": insurance_provider_id,
            "current_status": final_status,
            "created_at": events[0][1].isoformat()
        })
        for status, ts in events:
            status_rows.append({"appointment_id": appointment_id, "status": status, "status_at": ts.isoformat()})
        return appointment_id, final_status

    for _ in range(n):
        patient_id = random.choice(patient_ids)
        practitioner = random.choice(practitioner_records)
        scheduled_at = now + timedelta(
            days=random.randint(-150, 60),
            hours=random.choice([8, 9, 10, 11, 14, 15, 16, 17])
        )
        visit_type = random.choices(["INSURANCE", "SELF_PAY"], weights=[65, 35])[0]
        insurance_provider_id = random.choice(insurance_provider_ids) if visit_type == "INSURANCE" else None

        appointment_id, final_status = _new_appointment(
            patient_id, practitioner, scheduled_at, visit_type, insurance_provider_id
        )

        if final_status == "RESCHEDULED":
            new_scheduled_at = scheduled_at + timedelta(days=random.randint(3, 21))
            _new_appointment(
                patient_id, practitioner, new_scheduled_at, visit_type, insurance_provider_id,
                rescheduled_from_id=appointment_id
            )

    return pd.DataFrame(appointment_rows), pd.DataFrame(status_rows)

def generate_exams(appointments: pd.DataFrame, exam_types: pd.DataFrame, now: datetime, rate: float = 0.4):
    exam_type_ids = exam_types["exam_type_id"].tolist()
    rows = []
    status_rows = []
    exam_id = 1

    for _, appointment in appointments.iterrows():
        if random.random() > rate:
            continue
        source_scheduled_at = datetime.fromisoformat(appointment["scheduled_at"])
        scheduled_at = source_scheduled_at + timedelta(days=random.randint(0, 10))
        events, final_status = _build_status_history(scheduled_at, now)

        rows.append({
            "exam_id": exam_id,
            "source_appointment_id": appointment["appointment_id"],
            "patient_id": appointment["patient_id"],
            "exam_type_id": random.choice(exam_type_ids),
            "facility_id": appointment["facility_id"],
            "scheduled_at": scheduled_at.isoformat(),
            "visit_type": appointment["visit_type"],
            "insurance_provider_id": appointment["insurance_provider_id"],
            "current_status": final_status,
            "created_at": events[0][1].isoformat()
        })
        for status, ts in events:
            status_rows.append({"exam_id": exam_id, "status": status, "status_at": ts.isoformat()})
        exam_id += 1

    return pd.DataFrame(rows), pd.DataFrame(status_rows)

# --------------------------------------------------------------------------
# Payments (self-pay appointments/exams)
# --------------------------------------------------------------------------
def generate_payments(appointments: pd.DataFrame, exams: pd.DataFrame, exam_types: pd.DataFrame):
    price_by_exam_type = dict(zip(exam_types["exam_type_id"], exam_types["self_pay_price"]))
    rows = []
    payment_id = 1

    def _payment_status(current_status):
        if current_status == "CANCELLED":
            return random.choices(["REFUNDED", "CANCELLED"], weights=[70, 30])[0]
        if current_status == "COMPLETED":
            return "PAID"
        return random.choices(["PENDING", "PAID"], weights=[60, 40])[0]

    def _add(reference_type, reference_id, current_status, amount, reference_date):
        nonlocal payment_id
        payment_status = _payment_status(current_status)
        paid_at = None
        if payment_status in ("PAID", "REFUNDED"):
            paid_at = (reference_date - timedelta(days=random.randint(0, 2))).isoformat()
        rows.append({
            "payment_id": payment_id,
            "reference_type": reference_type,
            "reference_id": reference_id,
            "amount": amount,
            "payment_method": random.choice(domains.PAYMENT_METHODS),
            "payment_status": payment_status,
            "paid_at": paid_at
        })
        payment_id += 1

    for _, a in appointments[appointments["visit_type"] == "SELF_PAY"].iterrows():
        amount = round(random.uniform(150, 400), 2)
        _add("APPOINTMENT", a["appointment_id"], a["current_status"], amount, datetime.fromisoformat(a["scheduled_at"]))

    for _, e in exams[exams["visit_type"] == "SELF_PAY"].iterrows():
        base_price = price_by_exam_type.get(e["exam_type_id"], 100.0)
        amount = round(base_price * random.uniform(0.9, 1.1), 2)
        _add("EXAM", e["exam_id"], e["current_status"], amount, datetime.fromisoformat(e["scheduled_at"]))

    return pd.DataFrame(rows)

# --------------------------------------------------------------------------
# Patient feedback (a third source system: an external satisfaction survey
# tool, identifying patients by CPF since it serves many clinics, not by
# our internal patient_id)
# --------------------------------------------------------------------------
def generate_patient_feedback(appointments: pd.DataFrame, patients: pd.DataFrame, rate: float = 0.3):
    cpf_by_patient_id = dict(zip(patients["patient_id"], patients["cpf"]))
    completed = appointments[appointments["current_status"] == "COMPLETED"]

    comment_by_rating = {
        5: "Excellent service, highly recommend.",
        4: "Good visit, professional staff.",
        3: "Average experience, nothing special.",
        2: "Long wait, could be better.",
        1: "Poor experience, would not recommend.",
    }

    rows = []
    feedback_id = 1
    for _, appointment in completed.iterrows():
        if random.random() > rate:
            continue
        rating = random.choices([5, 4, 3, 2, 1], weights=[35, 30, 20, 10, 5])[0]
        submitted_at = datetime.fromisoformat(appointment["scheduled_at"]) + timedelta(days=random.randint(1, 5))
        rows.append({
            "feedback_id": feedback_id,
            "appointment_id": appointment["appointment_id"],
            "cpf": cpf_by_patient_id.get(appointment["patient_id"]),
            "rating": rating,
            "comments": comment_by_rating[rating],
            "submitted_at": submitted_at.isoformat(),
        })
        feedback_id += 1

    return pd.DataFrame(rows)

# --------------------------------------------------------------------------
# Orchestration
# --------------------------------------------------------------------------
def run(cfg, out_dir: Path):
    _seed(cfg.seed)
    now = datetime.now()

    facilities = generate_facilities(cfg.n_facilities)
    specialties = generate_specialties()
    insurance_providers = generate_insurance_providers(cfg.n_insurance_providers)
    exam_types = generate_exam_types()
    practitioners = generate_practitioners(cfg.n_practitioners, specialties, facilities)
    patients = generate_patients(cfg.n_patients)
    partner_patients = generate_partner_patients(patients, cfg.n_partner_patients_new, cfg.partner_overlap_rate)
    appointments, appointment_status_history = generate_appointments(
        cfg.n_appointments, patients, practitioners, insurance_providers, now
    )
    exams, exam_status_history = generate_exams(appointments, exam_types, now)
    payments = generate_payments(appointments, exams, exam_types)
    patient_feedback = generate_patient_feedback(appointments, patients, cfg.feedback_rate)

    tables = {
        "facilities": facilities,
        "specialties": specialties,
        "insurance_providers": insurance_providers,
        "exam_types": exam_types,
        "practitioners": practitioners,
        "patients": patients,
        "partner_patients": partner_patients,
        "appointments": appointments,
        "appointment_status_history": appointment_status_history,
        "exams": exams,
        "exam_status_history": exam_status_history,
        "payments": payments,
        "patient_feedback": patient_feedback
    }

    extraction_date = now.strftime("%Y-%m-%d")
    for name, df in tables.items():
        entity_dir = out_dir / name
        entity_dir.mkdir(parents=True, exist_ok=True)
        path = entity_dir / f"{name}_{extraction_date}.csv"
        df.to_csv(path, index=False)
        print(f"[ok] {name}: {len(df)} rows -> {path}")

    return tables

def main():
    parser = argparse.ArgumentParser(description="Synthetic data generator for the clinic/hospital scheduling domain")
    parser.add_argument("--upload", action="store_true", help="Upload the generated files to GCS right after generating them")
    args = parser.parse_args()

    cfg = get_config()
    out_dir = Path(cfg.local_output_dir)
    run(cfg, out_dir)

    if args.upload:
        from src.generator.upload_to_gcs import upload_directory
        upload_directory(out_dir, cfg.gcs_bucket_name, cfg.raw_prefix)

if __name__ == "__main__":
    main()