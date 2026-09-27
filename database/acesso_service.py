from firebase_config import db
from google.cloud import firestore


def registrar_acesso(usuario_id, nome, metodo, autorizado, dispositivo_id):
    documento = db.collection("acessos").add({
        "usuarioId": usuario_id,
        "nome": nome,
        "metodo": metodo,
        "autorizado": autorizado,
        "dispositivoId": dispositivo_id,
        "dataHora": firestore.SERVER_TIMESTAMP,
    })

    return documento