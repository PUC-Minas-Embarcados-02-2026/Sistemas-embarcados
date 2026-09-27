from firebase_config import db


def buscar_usuario_por_rfid(uid):
    # Padroniza o UID
    uid = uid.replace(" ", "").upper()

    resultado = (
        db.collection("usuarios")
        .where("rfid", "==", uid)
        .limit(1)
        .stream()
    )

    for documento in resultado:
        usuario = documento.to_dict()
        usuario["id"] = documento.id
        return usuario

    return None