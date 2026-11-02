"""Demonstração: webcam -> modelo real -> Firebase -> liberação simulada."""
import argparse
import os
from threading import Lock
import time

import cv2

from banco_facial import conectar, candidato, registrar_decisao
from facial_real import MotorFacial, FotoInvalida, identificar


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--camera', type=int, default=0)
    parser.add_argument('--limiar', type=float, default=0.60)
    parser.add_argument('--margem', type=float, default=0.08)
    parser.add_argument('--dispositivo', default='notebook_demo')
    args = parser.parse_args()
    if not 0 < args.limiar <= 1 or not 0 <= args.margem <= 2:
        parser.error('Limiar deve estar entre 0 e 1; margem entre 0 e 2.')
    motor = MotorFacial()
    db = observador = cap = None
    galeria = {}
    trava = Lock()
    try:
        db = conectar()

        def receber(documentos, alteracoes, horario):
            novos = {}
            for doc in documentos:
                pessoa = candidato(doc.id, doc.to_dict(), motor.modelo_id)
                if pessoa:
                    novos[doc.id] = pessoa
            with trava:
                galeria.clear()
                galeria.update(novos)

        observador = db.collection('usuarios').on_snapshot(receber)
        cap = cv2.VideoCapture(args.camera, cv2.CAP_DSHOW) if os.name == 'nt' else cv2.VideoCapture(args.camera)
        if not cap.isOpened():
            raise RuntimeError('Não foi possível abrir a webcam. Feche outros apps ou tente --camera 1.')
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        anterior, consecutivos, proximo_evento = None, 0, 0.0
        ultima_identidade, ultima_mensagem, ultima_cor = None, '', (0, 180, 255)
        print('Webcam ativa. Q encerra. Liberação apenas simulada; servo não conectado.')
        while True:
            ok, frame = cap.read()
            if not ok:
                raise RuntimeError('A câmera parou de fornecer imagens.')
            cor = (0, 180, 255)
            with trava:
                pessoas = list(galeria.values())
            try:
                rosto = motor.processar(frame)
                usuario, nota = identificar(rosto.vetor, pessoas, args.limiar, args.margem)
                identidade = usuario['id'] if usuario else None
                consecutivos = min(3, consecutivos + 1) if identidade and identidade == anterior else (1 if identidade else 0)
                anterior = identidade
                mensagem = 'Rosto nao cadastrado' if pessoas else 'Aguardando cadastros prontos no Firebase'
                if usuario:
                    mensagem = f"Confirmando {usuario['nome']} ({consecutivos}/3)"
                agora = time.monotonic()
                if (consecutivos >= 3 or (pessoas and usuario is None)) and agora >= proximo_evento:
                    try:
                        liberado = registrar_decisao(db, usuario, nota, motor.modelo_id, args.dispositivo)
                    except Exception as erro:
                        # Sem confirmar o registro atual no servidor, nunca liberar.
                        mensagem = 'Falha de conexao com Firebase: acesso nao liberado'
                        print(f'Falha Firebase ({type(erro).__name__}); acesso não liberado.')
                        consecutivos, anterior = 0, None
                    else:
                        mensagem = f"Bem-vindo, {usuario['nome']}! LIBERACAO SIMULADA" if liberado else 'ACESSO NEGADO'
                        cor = (0, 200, 0) if liberado else (0, 0, 255)
                        print(f"{mensagem} | similaridade={nota:.3f}")
                    proximo_evento = agora + 8
                    ultima_identidade, ultima_mensagem, ultima_cor = identidade, mensagem, cor
                elif usuario and consecutivos >= 3:
                    if identidade == ultima_identidade:
                        mensagem, cor = ultima_mensagem, ultima_cor
                    else:
                        mensagem = 'Aguarde para registrar o proximo acesso'
                x1, y1, x2, y2 = rosto.bbox
                cv2.rectangle(frame, (x1, y1), (x2, y2), cor, 2)
            except FotoInvalida as erro:
                anterior, consecutivos = None, 0
                mensagem = str(erro)
            # OpenCV usa fonte ASCII; mantém a mensagem legível na janela.
            import unicodedata
            mensagem = unicodedata.normalize('NFKD', mensagem).encode('ascii', 'ignore').decode()
            cv2.putText(frame, mensagem[:85], (10, 28), cv2.FONT_HERSHEY_SIMPLEX, 0.52, cor, 2)
            cv2.putText(frame, f'DEMO | {len(pessoas)} cadastros prontos | Q: sair',
                        (10, frame.shape[0] - 15), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
            cv2.imshow('PUC Access - Reconhecimento integrado', frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    except KeyboardInterrupt:
        pass
    finally:
        if cap is not None:
            cap.release()
        cv2.destroyAllWindows()
        if observador:
            observador.unsubscribe()
        if db:
            db.close()
        motor.fechar()


if __name__ == '__main__':
    main()
