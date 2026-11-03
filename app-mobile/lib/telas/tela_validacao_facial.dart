import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../componentes/botao_sair.dart';
import 'tela_concluida.dart';

/// A foto salva ainda precisa ser validada pelo processador no computador.
class TelaValidacaoFacial extends StatefulWidget {
  const TelaValidacaoFacial({
    super.key,
    required this.documento,
    required this.versaoFoto,
    required this.aoSair,
  });

  final DocumentReference<Map<String, dynamic>> documento;
  final String versaoFoto;
  final Future<void> Function() aoSair;

  @override
  State<TelaValidacaoFacial> createState() => _TelaValidacaoFacialState();
}

class _TelaValidacaoFacialState extends State<TelaValidacaoFacial> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _alteracoes;
  Timer? _temporizador;
  bool _demorando = false;

  @override
  void initState() {
    super.initState();
    _alteracoes = widget.documento.snapshots(includeMetadataChanges: true);
    _temporizador = Timer(const Duration(seconds: 45), () {
      if (mounted) setState(() => _demorando = true);
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Validação do rosto'),
        actions: [BotaoSair(aoSair: widget.aoSair)],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _alteracoes,
        builder: (context, snapshot) {
          final documento = snapshot.data;
          final dados = documento?.data();
          final atual =
              dados?['fotoVersao'] == widget.versaoFoto &&
              dados?['facialResultadoVersao'] == widget.versaoFoto;
          final confirmado =
              documento != null &&
              !documento.metadata.hasPendingWrites &&
              !documento.metadata.isFromCache;
          final pronto =
              atual &&
              confirmado &&
              dados?['facialStatus'] == 'pronto' &&
              dados?['cadastroConcluido'] == true;
          final rejeitado =
              atual && confirmado && dados?['facialStatus'] == 'erro';
          final removido = documento != null && confirmado && !documento.exists;
          final substituido =
              confirmado &&
              dados != null &&
              dados['fotoVersao'] != widget.versaoFoto;

          var titulo = 'Validando sua foto';
          var mensagem =
              'Aguarde enquanto preparamos seu rosto para o reconhecimento.';
          if (pronto) {
            titulo = 'Rosto pronto';
            mensagem =
                'Seu cadastro facial está disponível no sistema de acesso.';
          } else if (rejeitado) {
            titulo = 'Precisamos de outra foto';
            mensagem =
                dados?['facialMensagem'] as String? ?? 'Capture uma nova foto.';
          } else if (snapshot.hasError) {
            titulo = 'Não foi possível acompanhar a validação';
            mensagem = 'Confira a conexão com a internet e tente novamente.';
          } else if (removido || substituido) {
            titulo = 'Cadastro alterado';
            mensagem = 'Volte ao cadastro para enviar uma nova foto.';
          } else if (_demorando) {
            titulo = 'A validação está demorando';
            mensagem =
                'Sua foto foi enviada. Verifique se o serviço de reconhecimento '
                'está aberto no computador e conectado à internet. '
                'Você pode continuar aguardando nesta tela.';
          }

          final falha =
              rejeitado || snapshot.hasError || removido || substituido;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pronto)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 72,
                      )
                    else if (falha)
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 72,
                      )
                    else
                      const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(mensagem, textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    if (pronto)
                      FilledButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TelaConcluida(aoSair: widget.aoSair),
                          ),
                        ),
                        child: const Text('Continuar'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        rejeitado ? 'Tirar outra foto' : 'Voltar ao cadastro',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
