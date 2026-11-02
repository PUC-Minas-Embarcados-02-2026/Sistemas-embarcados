"""Contrato Firebase comum ao processador de cadastro e à catraca."""
from hashlib import sha256
from pathlib import Path
import os

import firebase_admin
from firebase_admin import credentials, firestore
from google.api_core.exceptions import FailedPrecondition, NotFound

from facial_real import FotoInvalida, normalizar


def conectar():
    caminho = Path(os.environ.get('GOOGLE_APPLICATION_CREDENTIALS') or
                   Path(__file__).resolve().parents[1] / 'database' / 'firebase_credentials.json')
    if not caminho.is_file():
        raise FileNotFoundError(
            'Credencial Firebase Admin ausente. Configure GOOGLE_APPLICATION_CREDENTIALS '
            'ou coloque o arquivo em database/firebase_credentials.json. Não envie a chave ao GitHub.')
    try:
        app = firebase_admin.get_app('facial')
    except ValueError:
        app = firebase_admin.initialize_app(credentials.Certificate(str(caminho)), name='facial')
    print(f'Projeto Firebase: {app.project_id}')
    return firestore.client(app=app)


def assinatura_foto(dados):
    foto = dados.get('fotoRosto')
    return sha256(foto).hexdigest() if isinstance(foto, bytes) else ''


def versao_foto(dados):
    # Compatível com fotos já cadastradas antes desta integração.
    return dados.get('fotoVersao') or assinatura_foto(dados)


def analisar_documento(dados, motor):
    if dados.get('consentimento') is not True:
        return None
    assinatura = assinatura_foto(dados)
    versao = versao_foto(dados)
    if (dados.get('facialFotoHash') == assinatura and
            dados.get('facialResultadoVersao') == versao and
            dados.get('facialModelo') == motor.modelo_id and
            dados.get('facialStatus') in ('pronto', 'erro')):
        return None
    resultado = {
        'facialModelo': motor.modelo_id,
        'facialFotoHash': assinatura,
        'facialResultadoVersao': versao,
        'facialProcessadoEm': firestore.SERVER_TIMESTAMP,
    }
    try:
        rosto = motor.processar_foto(dados.get('fotoRosto'))
        resultado.update(facialStatus='pronto', facialMensagem='Rosto pronto para reconhecimento.',
                         facialEmbedding=normalizar(rosto.vetor).tolist(), cadastroConcluido=True)
    except FotoInvalida as erro:
        resultado.update(facialStatus='erro', facialMensagem=str(erro),
                         facialEmbedding=firestore.DELETE_FIELD, cadastroConcluido=False)
    return resultado


def processar_documento(db, documento, motor):
    if not documento.exists:
        return False
    resultado = analisar_documento(documento.to_dict(), motor)
    if resultado is None:
        return False
    try:
        # Se houve nova foto, edição ou exclusão durante a inferência, o resultado
        # antigo não pode sobrescrever o cadastro mais recente.
        documento.reference.update(resultado, option=db.write_option(
            last_update_time=documento.update_time))
    except (FailedPrecondition, NotFound):
        return False
    print(f"Cadastro {documento.id}: {resultado['facialStatus']}")
    return True


def candidato(documento_id, dados, modelo_id):
    if not (dados.get('consentimento') is True and
            dados.get('cadastroConcluido') is True and
            dados.get('facialStatus') == 'pronto' and
            dados.get('facialModelo') == modelo_id and
            dados.get('facialResultadoVersao') == versao_foto(dados) and
            dados.get('facialFotoHash') == assinatura_foto(dados)):
        return None
    try:
        vetor = normalizar(dados.get('facialEmbedding'))
    except (ValueError, TypeError):
        return None
    return {'id': documento_id, 'nome': dados.get('nome', 'Usuário'), 'vetor': vetor,
            'versao': versao_foto(dados), 'hash': assinatura_foto(dados)}


def registrar_decisao(db, usuario, nota, modelo_id, dispositivo_id):
    """Revalida cadastro antes de liberar, registra sem armazenar foto da webcam."""
    @firestore.transactional
    def gravar(transacao):
        autorizado = False
        atual = None
        if usuario:
            doc = db.collection('usuarios').document(usuario['id']).get(transaction=transacao)
            atual = candidato(doc.id, doc.to_dict() or {}, modelo_id) if doc.exists else None
            autorizado = bool(atual and atual['versao'] == usuario['versao'] and
                              atual['hash'] == usuario['hash'])
        transacao.set(db.collection('acessos').document(), {
            'usuarioId': atual['id'] if autorizado else None,
            'nome': atual['nome'] if autorizado else None,
            'metodo': 'facial', 'autorizado': autorizado,
            'similaridade': float(nota), 'modelo': modelo_id,
            'dispositivoId': dispositivo_id, 'dataHora': firestore.SERVER_TIMESTAMP,
            'modo': 'demonstracao', 'acionamentoFisico': False,
        })
        return autorizado
    return gravar(db.transaction())
