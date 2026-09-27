from flask import Flask, jsonify
from rfid_service import buscar_usuario_por_rfid
from acesso_service import registrar_acesso

app = Flask(__name__)

DISPOSITIVO_ID = "entrada_01"


@app.route("/rfid/<uid>", methods=["GET"])
def verificar_rfid(uid):
    try:
        uid = uid.replace(" ", "").upper()

        usuario = buscar_usuario_por_rfid(uid)

        # RFID cadastrado
        if usuario:
            registrar_acesso(
                usuario_id=usuario["id"],
                nome=usuario["nome"],
                metodo="rfid",
                autorizado=True,
                dispositivo_id=DISPOSITIVO_ID
            )

            return jsonify({
                "autorizado": True,
                "usuarioId": usuario["id"],
                "nome": usuario["nome"],
                "rfid": uid
            }), 200

        # RFID não cadastrado
        registrar_acesso(
            usuario_id=None,
            nome=None,
            metodo="rfid",
            autorizado=False,
            dispositivo_id=DISPOSITIVO_ID
        )

        return jsonify({
            "autorizado": False,
            "rfid": uid,
            "mensagem": "RFID nao cadastrado"
        }), 404

    except Exception as erro:
        print("Erro:", erro)

        return jsonify({
            "autorizado": False,
            "mensagem": "Erro interno"
        }), 500


@app.route("/", methods=["GET"])
def inicio():
    return jsonify({
        "status": "online",
        "servico": "PUC Access API"
    })


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )