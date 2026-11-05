import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../componentes/botao_sair.dart';
import '../servicos/autenticacao_service.dart';
import 'tela_camera.dart';
import 'tela_validacao_facial.dart';

/// Perfil de quem já tem cadastro: nome, foto, situação e ações.
/// Diferente da TelaConcluida, que aparece só ao terminar o primeiro cadastro.
class TelaMeuCadastro extends StatefulWidget {
  const TelaMeuCadastro({
    super.key,
    required this.usuario,
    required this.aoSair,
  });
  final UsuarioAutenticado usuario;
  final Future<void> Function() aoSair;

  @override
  State<TelaMeuCadastro> createState() => _TelaMeuCadastroState();
}

class _TelaMeuCadastroState extends State<TelaMeuCadastro> {
  static const Color _azul = Color(0xFF0B4F8A);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _borda = Color(0xFFD6DEE8);
  static const int _limiteFoto = 700 * 1024;

  late final DocumentReference<Map<String, dynamic>> _documento;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _alteracoes;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _documento = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.usuario.uid);
    _alteracoes = _documento.snapshots();
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _editarNome(String nomeAtual) async {
    final novo = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoNome(nomeAtual: nomeAtual),
    );
    if (novo == null || novo == nomeAtual || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await _documento.update({
        'nome': novo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) _aviso('Nome atualizado.');
    } catch (_) {
      if (mounted) _aviso('Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _trocarFoto(Map<String, dynamic> dados) async {
    final foto = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(builder: (_) => const TelaCamera()),
    );
    if (foto == null || foto.isEmpty || !mounted) return;
    if (foto.lengthInBytes > _limiteFoto) {
      _aviso('A foto ficou muito grande. Tente novamente.');
      return;
    }
    setState(() => _ocupado = true);
    try {
      final versao = FirebaseFirestore.instance.collection('usuarios').doc().id;
      await _documento.set({
        'uid': widget.usuario.uid,
        'email': widget.usuario.email,
        'nome': dados['nome'],
        'consentimento': true,
        'cadastroConcluido': false,
        'fotoVersao': versao,
        'facialStatus': 'pendente',
        'facialMensagem': 'Aguardando validação da foto.',
        'facialEmbedding': FieldValue.delete(),
        'facialModelo': FieldValue.delete(),
        'facialFotoHash': FieldValue.delete(),
        'facialResultadoVersao': FieldValue.delete(),
        'facialProcessadoEm': FieldValue.delete(),
        'atualizadoEm': FieldValue.serverTimestamp(),
        'fotoRosto': Blob(foto),
        'fotoTamanhoBytes': foto.lengthInBytes,
        'fotoSalvaEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TelaValidacaoFacial(
            documento: _documento,
            versaoFoto: versao,
            aoSair: widget.aoSair,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _aviso('Não foi possível salvar. Confira sua conexão e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  ({String texto, Color cor, IconData icone}) _situacao(
    Map<String, dynamic> dados,
  ) {
    final pronto =
        dados['cadastroConcluido'] == true && dados['facialStatus'] == 'pronto';
    if (pronto) {
      return (
        texto: 'Cadastro ativo',
        cor: const Color(0xFF1F9D62),
        icone: Icons.check_circle,
      );
    }
    if (dados['facialStatus'] == 'erro') {
      return (
        texto: 'Precisa de nova foto',
        cor: const Color(0xFFD97706),
        icone: Icons.info_outline,
      );
    }
    return (
      texto: 'Validando foto',
      cor: _azul,
      icone: Icons.hourglass_top_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _alteracoes,
      builder: (context, snapshot) {
        final dados = snapshot.data?.data();
        if (dados == null) {
          return Scaffold(
            appBar: AppBar(actions: [BotaoSair(aoSair: widget.aoSair)]),
            body: Center(
              child: snapshot.hasError
                  ? const Text('Não foi possível carregar seu cadastro.')
                  : const CircularProgressIndicator(),
            ),
          );
        }
        final nome = dados['nome'] as String? ?? '';
        final foto = dados['fotoRosto'];
        final bytes = foto is Blob ? foto.bytes : null;
        final situacao = _situacao(dados);
        final erro = dados['facialStatus'] == 'erro'
            ? dados['facialMensagem'] as String?
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 342),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BotaoSair(
                            aoSair: widget.aoSair,
                            habilitado: !_ocupado,
                          ),
                          Text(
                            'PERFIL',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _azul,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Meu cadastro',
                        style: GoogleFonts.inter(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: _textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE7EDF3)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 9,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 128,
                                height: 128,
                                child: bytes == null
                                    ? const ColoredBox(
                                        color: Color(0xFFE7EDF3),
                                        child: Icon(
                                          Icons.person,
                                          size: 64,
                                          color: _textoSecundario,
                                        ),
                                      )
                                    : Image.memory(
                                        bytes,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              nome,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _textoPrincipal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.usuario.email,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _textoSecundario,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: situacao.cor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    situacao.icone,
                                    size: 16,
                                    color: situacao.cor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    situacao.texto,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: situacao.cor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (erro != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                erro,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _textoSecundario,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _ocupado ? null : () => _trocarFoto(dados),
                          icon: _ocupado
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                          label: const Text('Trocar foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _azul,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _ocupado ? null : () => _editarNome(nome),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar dados'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _azul,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: _azul, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Ao trocar a foto, ela passa por uma nova validação.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialogoNome extends StatefulWidget {
  const _DialogoNome({required this.nomeAtual});
  final String nomeAtual;

  @override
  State<_DialogoNome> createState() => _DialogoNomeState();
}

class _DialogoNomeState extends State<_DialogoNome> {
  late final TextEditingController _controlador;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(text: widget.nomeAtual);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _salvar() {
    final nome = _controlador.text.trim();
    if (nome.isEmpty || nome.length > 200) {
      setState(() => _erro = 'Digite seu nome, com até 200 caracteres.');
      return;
    }
    Navigator.of(context).pop(nome);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar dados'),
      content: TextField(
        controller: _controlador,
        autofocus: true,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _salvar(),
        decoration: InputDecoration(
          labelText: 'Nome completo',
          errorText: _erro,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
