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
    "Urology",
]

# (name, category, self_pay_price)
EXAM_TYPES = [
    ("Complete Blood Count", "Laboratory", 60.0),
    ("Fasting Blood Glucose", "Laboratory", 35.0),
    ("Total Cholesterol Panel", "Laboratory", 55.0),
    ("Chest X-Ray", "Imaging", 120.0),
    ("Abdominal Ultrasound", "Imaging", 180.0),
    ("Mammogram", "Imaging", 150.0),
    ("Bone Densitometry", "Imaging", 140.0),
    ("MRI Scan", "Imaging", 650.0),
    ("CT Scan", "Imaging", 480.0),
    ("Electrocardiogram (ECG)", "Cardiology", 90.0),
    ("Stress Test", "Cardiology", 250.0),
    ("Upper Endoscopy", "Endoscopy", 420.0),
    ("Colonoscopy", "Endoscopy", 550.0),
]

APPOINTMENT_STATUSES = ["SCHEDULED", "CONFIRMED", "CANCELLED", "RESCHEDULED", "COMPLETED", "NO_SHOW"]

VISIT_TYPES = ["SELF_PAY", "INSURANCE"]

PAYMENT_METHODS = ["CASH", "CREDIT_CARD", "DEBIT_CARD", "PIX", "BANK_TRANSFER"]

PAYMENT_STATUSES = ["PENDING", "PAID", "REFUNDED", "CANCELLED"]