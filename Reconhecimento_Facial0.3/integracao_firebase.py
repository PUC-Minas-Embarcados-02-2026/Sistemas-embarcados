"""Escuta fotos do app e prepara os cadastros. Execute antes de cadastrar no app."""
import argparse
from queue import Queue, Empty

from banco_facial import conectar, processar_documento
from facial_real import MotorFacial


def main():
    argumentos = argparse.ArgumentParser(description=__doc__)
    argumentos.add_argument('--uma-vez', action='store_true', help='Processar os cadastros atuais e sair.')
    args = argumentos.parse_args()
    motor = MotorFacial()
    db = None
    observador = None
    try:
        db = conectar()
        if args.uma_vez:
            for documento in db.collection('usuarios').stream():
                processar_documento(db, documento, motor)
            return
        fila = Queue()

        def receber(documentos, alteracoes, horario):
            for alteracao in alteracoes:
                if alteracao.type.name != 'REMOVED':
                    fila.put(alteracao.document)

        observador = db.collection('usuarios').on_snapshot(receber)
        print('Integração ativa. Cadastre uma foto no app. Ctrl+C para encerrar.')
        while True:
            try:
                documento = fila.get(timeout=1)
            except Empty:
                continue
            processar_documento(db, documento, motor)
    except KeyboardInterrupt:
        print('\nIntegração encerrada.')
    finally:
        if observador:
            observador.unsubscribe()
        if db:
            db.close()
        motor.fechar()


if __name__ == '__main__':
    main()
