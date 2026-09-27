import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

CAMINHO_CREDENCIAL = Path(__file__).parent / "firebase_credentials.json"

if not firebase_admin._apps:
    cred = credentials.Certificate(str(CAMINHO_CREDENCIAL))
    firebase_admin.initialize_app(cred)

db = firestore.client()