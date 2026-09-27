print("1 - Iniciando teste")

from firebase_config import db

print("2 - Firebase conectado")

usuarios = db.collection("usuarios").stream()

print("3 - Buscando usuários")

for usuario in usuarios:
    print(usuario.id, "=>", usuario.to_dict())

print("4 - Teste finalizado")