"""Reference domain lists used by the synthetic data generator.

In the Data Vault model we build later, these lists correspond to the
future `ref_*` (reference) tables.
"""

SPECIALTIES = [
    "General Practice",
    "Cardiology",
    "Dermatology",
    "Orthopedics",
    "Pediatrics",
    "Obstetrics and Gynecology",
    "Endocrinology",
    "Neurology",
    "Psychiatry",
    "Ophthalmology",
    "Otolaryngology (ENT)",
    "Urology"
]

# (name, category, self_pay_price, tuss_code)
# tuss_code follows the real TUSS (Terminologia Unificada da Saude Suplementar)
# 8-digit format used across Brazilian insurers/clinics to bill procedures —
# illustrative codes, not the official published table.
EXAM_TYPES = [
    ("Complete Blood Count", "Laboratory", 60.0, "40304361"),
    ("Fasting Blood Glucose", "Laboratory", 35.0, "40302199"),
    ("Total Cholesterol Panel", "Laboratory", 55.0, "40301157"),
    ("Chest X-Ray", "Imaging", 120.0, "40901079"),
    ("Abdominal Ultrasound", "Imaging", 180.0, "40801385"),
    ("Mammogram", "Imaging", 150.0, "40901087"),
    ("Bone Densitometry", "Imaging", 140.0, "41101010"),
    ("MRI Scan", "Imaging", 650.0, "41001015"),
    ("CT Scan", "Imaging", 480.0, "41002011"),
    ("Electrocardiogram (ECG)", "Cardiology", 90.0, "40301010"),
    ("Stress Test", "Cardiology", 250.0, "40302016"),
    ("Upper Endoscopy", "Endoscopy", 420.0, "40901010"),
    ("Colonoscopy", "Endoscopy", 550.0, "40901028")
]

APPOINTMENT_STATUSES = ["SCHEDULED", "CONFIRMED", "CANCELLED", "RESCHEDULED", "COMPLETED", "NO_SHOW"]

VISIT_TYPES = ["SELF_PAY", "INSURANCE"]

PAYMENT_METHODS = ["CASH", "CREDIT_CARD", "DEBIT_CARD", "PIX", "BANK_TRANSFER"]

PAYMENT_STATUSES = ["PENDING", "PAID", "REFUNDED", "CANCELLED"]