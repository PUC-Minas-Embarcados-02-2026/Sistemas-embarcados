"""Testes sem credenciais, webcam ou dados pessoais."""
import sys
from pathlib import Path
from types import SimpleNamespace

import numpy as np
import pytest
from google.api_core.exceptions import FailedPrecondition
from firebase_admin import firestore

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from facial_real import normalizar, identificar, matriz_alinhamento, DESTINO, FotoInvalida
from banco_facial import analisar_documento, candidato, processar_documento, registrar_decisao


def vetor(indice=0):
    resultado = np.zeros(512, dtype=np.float32)
    resultado[indice] = 1
    return resultado


class MotorTeste:
    modelo_id = 'modelo-teste'

    def processar_foto(self, foto):
        if foto != b'foto-valida':
            raise FotoInvalida('Capture outra foto.')
        return SimpleNamespace(vetor=vetor())


def cadastro():
    return {'nome': 'Pessoa de teste', 'consentimento': True,
            'fotoRosto': b'foto-valida', 'fotoVersao': 'v1', 'facialStatus': 'pendente'}


def pronto():
    dados = cadastro()
    dados.update(analisar_documento(dados, MotorTeste()))
    return dados


def test_modelo_aceita_mesma_pessoa_e_rejeita_desconhecido():
    pessoa = {'id': 'a', 'vetor': vetor()}
    assert identificar(vetor(), [pessoa])[0] is pessoa
    assert identificar(vetor(1), [pessoa])[0] is None


def test_ambiguo_nao_libera():
    pessoas = [{'id': 'a', 'vetor': vetor()}, {'id': 'b', 'vetor': vetor()}]
    assert identificar(vetor(), pessoas)[0] is None


@pytest.mark.parametrize('entrada', [np.zeros(512), np.ones(128), np.full(512, np.nan), np.full(512, np.inf)])
def test_vetor_invalido_rejeitado(entrada):
    with pytest.raises(ValueError):
        normalizar(entrada)


def test_alinhamento_recupera_rotacao_escala_e_deslocamento():
    angulo = 0.2
    rotacao = np.array([[np.cos(angulo), -np.sin(angulo)], [np.sin(angulo), np.cos(angulo)]])
    origem = 2.3 * DESTINO @ rotacao.T + [80, 20]
    matriz = matriz_alinhamento(origem)
    resultado = np.c_[origem, np.ones(5)] @ matriz.T
    np.testing.assert_allclose(resultado, DESTINO, atol=1e-4)


def test_cadastro_valido_vira_candidato():
    dados = pronto()
    assert dados['facialStatus'] == 'pronto'
    assert dados['cadastroConcluido'] is True
    assert candidato('id-1', dados, MotorTeste.modelo_id)['id'] == 'id-1'
    assert analisar_documento(dados, MotorTeste()) is None  # sem loop do listener


def test_foto_ruim_limpa_vetor_anterior():
    dados = pronto()
    dados.update(fotoRosto=b'ruim', fotoVersao='v2', facialStatus='pendente')
    resultado = analisar_documento(dados, MotorTeste())
    assert resultado['facialStatus'] == 'erro'
    assert resultado['facialEmbedding'] is firestore.DELETE_FIELD
    assert resultado['cadastroConcluido'] is False
    dados.update(resultado)
    assert analisar_documento(dados, MotorTeste()) is None


@pytest.mark.parametrize('mudanca', [
    {'consentimento': False}, {'cadastroConcluido': False},
    {'facialStatus': 'pendente'}, {'fotoVersao': 'v2'}, {'fotoRosto': b'outra'},
    {'facialModelo': 'outro'}, {'facialEmbedding': [0] * 128},
])
def test_galeria_nao_aceita_dados_revogados_ou_desatualizados(mudanca):
    dados = pronto()
    dados.update(mudanca)
    assert candidato('id-1', dados, MotorTeste.modelo_id) is None


def test_sem_consentimento_nao_processa():
    dados = cadastro()
    dados['consentimento'] = False
    assert analisar_documento(dados, MotorTeste()) is None


def test_cadastros_antigos_sem_versao_podem_ser_processados():
    dados = cadastro()
    del dados['fotoVersao']
    dados.update(analisar_documento(dados, MotorTeste()))
    assert candidato('antigo', dados, MotorTeste.modelo_id) is not None


def test_foto_alterada_durante_inferencia_nao_sobrescreve():
    class Referencia:
        def update(self, resultado, option):
            assert option == 'versao-original'
            raise FailedPrecondition('Documento foi alterado')
    documento = SimpleNamespace(exists=True, id='id', update_time='versao-original',
                               reference=Referencia(), to_dict=cadastro)
    db = SimpleNamespace(write_option=lambda last_update_time: last_update_time)
    assert processar_documento(db, documento, MotorTeste()) is False


@pytest.mark.parametrize('revogado', [False, True])
def test_decisao_revalida_consentimento_antes_de_registrar(monkeypatch, revogado):
    dados = pronto()
    pessoa = candidato('id-1', dados, MotorTeste.modelo_id)
    if revogado:
        dados['consentimento'] = False
    gravacoes = []
    monkeypatch.setattr(firestore, 'transactional', lambda funcao: funcao)
    documento = SimpleNamespace(id='id-1', exists=True, to_dict=lambda: dados)
    referencia = SimpleNamespace(get=lambda transaction: documento)
    colecao = SimpleNamespace(document=lambda *args: referencia)
    transacao = SimpleNamespace(set=lambda referencia, dados: gravacoes.append(dados))
    db = SimpleNamespace(collection=lambda nome: colecao, transaction=lambda: transacao)
    autorizado = registrar_decisao(db, pessoa, 0.9, MotorTeste.modelo_id, 'teste')
    assert autorizado is not revogado
    assert gravacoes[0]['autorizado'] is not revogado
    assert gravacoes[0]['acionamentoFisico'] is False
    assert gravacoes[0]['usuarioId'] == (None if revogado else 'id-1')
