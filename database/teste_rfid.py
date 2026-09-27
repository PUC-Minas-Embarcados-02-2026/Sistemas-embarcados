from rfid_service import buscar_usuario_por_rfid

uid = "B79F1415"

usuario = buscar_usuario_por_rfid(uid)

if usuario:
    print("ACESSO AUTORIZADO")
    print("ID:", usuario["id"])
    print("Nome:", usuario["nome"])
    print("RFID:", usuario["rfid"])
else:
    print("ACESSO NEGADO")