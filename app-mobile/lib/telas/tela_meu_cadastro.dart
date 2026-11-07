import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../componentes/botao_sair.dart';
import '../servicos/autenticacao_service.dart';
import 'tela_autorizacao_nfc.dart';
import 'tela_camera.dart';
import 'tela_validacao_facial.dart';

/// Perfil de quem já tem cadastro: nome, foto, situação e ações.
/// O cartão do perfil vira (flip) e mostra o cartão de acesso por NFC.
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

class _TelaMeuCadastroState extends State<TelaMeuCadastro>
    with SingleTickerProviderStateMixin {
  static const Color _azul = Color(0xFF0B4F8A);
  static const Color _azulClaro = Color(0xFF1B7BC4);
  static const Color _verde = Color(0xFF1F9D62);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const int _limiteFoto = 700 * 1024;
  static const double _alturaCartao = 290;

  late final DocumentReference<Map<String, dynamic>> _documento;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _alteracoes;
  late final AnimationController _giro;
  late final Animation<double> _giroCurva;
  bool _ocupado = false;
  bool _virado = false;

  @override
  void initState() {
    super.initState();
    _documento = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.usuario.uid);
    _alteracoes = _documento.snapshots();
    _giro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _giroCurva = CurvedAnimation(parent: _giro, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // ---------- Cartão de acesso (NFC) ----------

  void _virarCartao() {
    if (_virado) {
      _giro.reverse();
    } else {
      _giro.forward();
    }
    setState(() => _virado = !_virado);
  }

  Future<void> _aoTocarCartao({
    required bool autorizado,
    required bool pronto,
  }) async {
    if (_ocupado) return;
    if (!autorizado) {
      await _permitirNfc(pronto: pronto);
      return;
    }
    if (!pronto) {
      _aviso('O cartão fica disponível quando o cadastro estiver ativo.');
      return;
    }
    _virarCartao();
  }

  Future<void> _permitirNfc({required bool pronto}) async {
    final escolha = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const TelaAutorizacaoNfc()),
    );
    if (escolha != true || !mounted) return;
    final salvou = await _salvarNfc(true);
    if (salvou && pronto && !_virado && mounted) _virarCartao();
  }

  Future<void> _desativarNfc() async {
    final salvou = await _salvarNfc(false);
    if (salvou && _virado && mounted) _virarCartao();
  }

  Future<bool> _salvarNfc(bool autorizado) async {
    setState(() => _ocupado = true);
    try {
      await _documento.update({
        'nfcAutorizado': autorizado,
        'nfcDecididoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _aviso(
          autorizado
              ? 'Acesso por NFC permitido.'
              : 'Acesso por NFC desativado.',
        );
      }
      return true;
    } catch (_) {
      if (mounted) _aviso('Não foi possível salvar. Tente novamente.');
      return false;
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ---------- Nome e foto ----------

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
        _aviso(
          'Não foi possível salvar. Confira sua conexão e tente novamente.',
        );
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
      return (texto: 'Cadastro ativo', cor: _verde, icone: Icons.check_circle);
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

  // ---------- Faces do cartão ----------

  Widget _foto(Uint8List? bytes, {required double tamanho}) {
    if (bytes == null) {
      return ColoredBox(
        color: const Color(0xFFE7EDF3),
        child: Icon(Icons.person, size: tamanho / 2, color: _textoSecundario),
      );
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      width: tamanho,
      height: tamanho,
    );
  }

  Widget _frente({
    required String nome,
    required Uint8List? bytes,
    required ({String texto, Color cor, IconData icone}) situacao,
    required bool autorizado,
  }) {
    final corSelo = autorizado ? _azul : _textoSecundario;
    return Container(
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
              child: Column(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: _foto(bytes, tamanho: 112),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Selo(
                    icone: situacao.icone,
                    texto: situacao.texto,
                    cor: situacao.cor,
                    tamanhoTexto: 12,
                  ),
                ],
              ),
            ),
          ),
          // Indica que o cartão vira para o acesso por NFC.
          Positioned(
            top: 12,
            right: 12,
            child: _Selo(
              icone: Icons.nfc,
              texto: autorizado ? 'Cartão de acesso' : 'NFC desativado',
              cor: corSelo,
              tamanhoTexto: 11,
              iconeFinal: Icons.flip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verso({
    required String nome,
    required Uint8List? bytes,
    required ({String texto, Color cor, IconData icone}) situacao,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_azul, _azulClaro],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B4F8A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CARTÃO DE ACESSO',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              const Icon(Icons.nfc, color: Colors.white),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 104,
                  child: _foto(bytes, tamanho: 104),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.usuario.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            situacao.texto,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.contactless_outlined,
                size: 18,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                'Aproxime o celular do leitor',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
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
        final pronto =
            dados['cadastroConcluido'] == true &&
            dados['facialStatus'] == 'pronto';
        final autorizado = dados['nfcAutorizado'] == true;
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
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Meu perfil',
                        style: GoogleFonts.inter(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: _textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: _alturaCartao,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _aoTocarCartao(
                            autorizado: autorizado,
                            pronto: pronto,
                          ),
                          child: _CartaoGiratorio(
                            animacao: _giroCurva,
                            frente: _frente(
                              nome: nome,
                              bytes: bytes,
                              situacao: situacao,
                              autorizado: autorizado,
                            ),
                            verso: _verso(
                              nome: nome,
                              bytes: bytes,
                              situacao: situacao,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          !autorizado
                              ? 'Toque no cartão para permitir o acesso por NFC.'
                              : _virado
                              ? 'Toque no cartão para voltar ao perfil.'
                              : 'Toque no cartão para ver seu acesso por NFC.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _textoSecundario,
                          ),
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
                      const SizedBox(height: 20),
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
                      if (!autorizado)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.tonalIcon(
                            onPressed: _ocupado
                                ? null
                                : () => _permitirNfc(pronto: pronto),
                            icon: const Icon(Icons.nfc),
                            label: const Text('Permitir acesso por NFC'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _ocupado ? null : _desativarNfc,
                            child: const Text('Desativar acesso por NFC'),
                          ),
                        ),
                      const SizedBox(height: 8),
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

/// Vira o cartão em torno do eixo vertical (efeito de flip 3D).
class _CartaoGiratorio extends StatelessWidget {
  const _CartaoGiratorio({
    required this.animacao,
    required this.frente,
    required this.verso,
  });
  final Animation<double> animacao;
  final Widget frente;
  final Widget verso;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacao,
      builder: (context, _) {
        final angulo = animacao.value * math.pi;
        final mostrandoVerso = angulo > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angulo),
          child: mostrandoVerso
              // O verso começa espelhado; desvira para ficar legível.
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: verso,
                )
              : frente,
        );
      },
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({
    required this.icone,
    required this.texto,
    required this.cor,
    required this.tamanhoTexto,
    this.iconeFinal,
  });
  final IconData icone;
  final String texto;
  final Color cor;
  final double tamanhoTexto;
  final IconData? iconeFinal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 6),
          Text(
            texto,
            style: GoogleFonts.inter(
              fontSize: tamanhoTexto,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
          if (iconeFinal != null) ...[
            const SizedBox(width: 6),
            Icon(iconeFinal, size: 14, color: cor),
          ],
        ],
      ),
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
