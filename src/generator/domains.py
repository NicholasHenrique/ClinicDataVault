"""Listas de domínio (referência) usadas pelo gerador de dados sintéticos.

Estas listas correspondem, na modelagem de Data Vault que vamos construir
mais adiante, às futuras tabelas `ref_*` (reference tables).
"""

ESPECIALIDADES = [
    "Clínica Geral",
    "Cardiologia",
    "Dermatologia",
    "Ortopedia",
    "Pediatria",
    "Ginecologia e Obstetrícia",
    "Endocrinologia",
    "Neurologia",
    "Psiquiatria",
    "Oftalmologia",
    "Otorrinolaringologia",
    "Urologia"
]

# (nome, categoria, preco_particular)
TIPOS_EXAME = [
    ("Hemograma Completo", "Laboratorial", 60.0),
    ("Glicemia em Jejum", "Laboratorial", 35.0),
    ("Colesterol Total e Frações", "Laboratorial", 55.0),
    ("Raio-X de Tórax", "Imagem", 120.0),
    ("Ultrassonografia Abdominal", "Imagem", 180.0),
    ("Mamografia", "Imagem", 150.0),
    ("Densitometria Óssea", "Imagem", 140.0),
    ("Ressonância Magnética", "Imagem", 650.0),
    ("Tomografia Computadorizada", "Imagem", 480.0),
    ("Eletrocardiograma", "Cardiológico", 90.0),
    ("Teste Ergométrico", "Cardiológico", 250.0),
    ("Endoscopia Digestiva Alta", "Endoscopia", 420.0),
    ("Colonoscopia", "Endoscopia", 550.0),
]

STATUS_ATENDIMENTO = ["AGENDADO", "CONFIRMADO", "CANCELADO", "REAGENDADO", "REALIZADO", "FALTOU"]

TIPOS_ATENDIMENTO = ["PARTICULAR", "CONVENIO"]

FORMAS_PAGAMENTO = ["DINHEIRO", "CARTAO_CREDITO", "CARTAO_DEBITO", "PIX", "TRANSFERENCIA"]

STATUS_PAGAMENTO = ["PENDENTE", "PAGO", "ESTORNADO", "CANCELADO"]