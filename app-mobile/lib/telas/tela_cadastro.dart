import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicos/autenticacao_service.dart';
import '../componentes/botao_sair.dart';
import 'tela_autorizacao_nfc.dart';
import 'tela_camera.dart';
import 'tela_meu_cadastro.dart';
import 'tela_validacao_facial.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key, required this.usuario, required this.aoSair});
  final UsuarioAutenticado usuario;
  final Future<void> Function() aoSair;

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final TextEditingController _controladorNome = TextEditingController();

  bool _consentimentoAutorizado = false;
  bool _salvando = false;

  /// Escolha sobre usar o celular como cartão NFC (null = ainda não decidiu).
  bool? _escolhaNfc;
  bool _abrindoCamera = false;

  bool _carregando = true;
  bool _erroAoCarregar = false;
  bool _criacaoConfirmada = false;

  /// Já existe um documento para esta conta: mostra "Meu cadastro".
  bool _jaCadastrado = false;
  Uint8List? _fotoRosto;

  static const Color _azulPrincipal = Color(0xFF0B4F8A);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _borda = Color(0xFFD6DEE8);

  @override
  void initState() {
    super.initState();
    _carregarCadastro();
  }

  Future<void> _carregarCadastro() async {
    setState(() {
      _carregando = true;
      _erroAoCarregar = false;
    });
    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuario.uid)
          .get();
      if (!mounted) return;
      final dados = documento.data();
      setState(() {
        _criacaoConfirmada = documento.exists;
        _controladorNome.text = dados?['nome'] as String? ?? '';
        _consentimentoAutorizado = dados?['consentimento'] == true;
        final foto = dados?['fotoRosto'];
        _fotoRosto = foto is Blob ? foto.bytes : null;
        // Quem já tem cadastro vê o perfil ao entrar de novo, sem repetir
        // o processo. O formulário fica só para o primeiro cadastro.
        _jaCadastrado = documento.exists;
      });
    } catch (_) {
      if (mounted) setState(() => _erroAoCarregar = true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    super.dispose();
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _capturarRosto() async {
    if (_salvando || _abrindoCamera || _carregando || _erroAoCarregar) return;

    if (!_consentimentoAutorizado) {
      _mostrarAviso(
        'Marque a autorização de uso da imagem antes de abrir a câmera.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _abrindoCamera = true;
    });

    try {
      final foto = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(builder: (context) => const TelaCamera()),
      );

      if (!mounted || foto == null) return;

      setState(() {
        _fotoRosto = foto;
      });
    } finally {
      if (mounted) {
        setState(() {
          _abrindoCamera = false;
        });
      }
    }
  }

  Future<void> _finalizarCadastro() async {
    if (_salvando || _abrindoCamera || _carregando || _erroAoCarregar) return;

    FocusScope.of(context).unfocus();

    final nome = _controladorNome.text.trim();
    final foto = _fotoRosto;

    if (nome.isEmpty || nome.length > 200) {
      _mostrarAviso('Digite seu nome completo, com até 200 caracteres.');
      return;
    }

    if (!_consentimentoAutorizado) {
      _mostrarAviso('Autorize o uso do nome e imagem facial.');
      return;
    }

    if (foto == null || foto.isEmpty) {
      _mostrarAviso('Capture uma foto antes de finalizar.');
      return;
    }

    // Mantém a foto abaixo do limite de tamanho do documento.
    const limiteFoto = 700 * 1024;

    if (foto.lengthInBytes > limiteFoto) {
      _mostrarAviso(
        'A foto ficou muito grande. '
        'Precisamos reduzir a resolução antes de salvar.',
      );
      return;
    }

    // Pergunta sobre o uso do celular como cartão de acesso (NFC) uma vez.
    if (_escolhaNfc == null) {
      final escolha = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const TelaAutorizacaoNfc()),
      );
      // Voltou sem decidir: não finaliza o cadastro.
      if (escolha == null || !mounted) return;
      _escolhaNfc = escolha;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final usuarios = FirebaseFirestore.instance.collection('usuarios');

      final documento = usuarios.doc(widget.usuario.uid);
      final versaoFoto = usuarios.doc().id;

      final dados = <String, dynamic>{
        'uid': widget.usuario.uid,
        'email': widget.usuario.email,
        'nome': nome,
        'consentimento': true,
        'cadastroConcluido': false,
        'fotoVersao': versaoFoto,
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
      };

      if (!_criacaoConfirmada) {
        dados['criadoEm'] = FieldValue.serverTimestamp();
        dados['nfcAutorizado'] = _escolhaNfc ?? false;
        dados['nfcDecididoEm'] = FieldValue.serverTimestamp();
      }
      // O ID é mantido mesmo em uma tentativa que falhe, evitando duplicação.
      await documento.set(dados, SetOptions(merge: true));
      _criacaoConfirmada = true;

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TelaValidacaoFacial(
            documento: documento,
            versaoFoto: versaoFoto,
            aoSair: widget.aoSair,
          ),
        ),
      );

      // Ao voltar da validação, recarrega: com cadastro salvo, abre
      // "Meu cadastro" em vez de repetir o formulário.
      if (mounted) await _carregarCadastro();
    } catch (erro) {
      if (!mounted) return;

      _mostrarAviso(
        'Não foi possível salvar. Confira sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = _fotoRosto;
    if (!_carregando && !_erroAoCarregar && _jaCadastrado) {
      return TelaMeuCadastro(usuario: widget.usuario, aoSair: widget.aoSair);
    }
    if (_carregando || _erroAoCarregar) {
      return Scaffold(
        appBar: AppBar(actions: [BotaoSair(aoSair: widget.aoSair)]),
        body: Center(
          child: _carregando
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Não foi possível carregar seu cadastro.'),
                    TextButton(
                      onPressed: _carregarCadastro,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
        ),
      );
    }

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
                        habilitado: !_salvando && !_abrindoCamera,
                      ),
                      Text(
                        'CADASTRO',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _azulPrincipal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _criacaoConfirmada
                        ? 'Seu cadastro'
                        : 'Complete seu cadastro',
                    style: GoogleFonts.inter(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: _textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.usuario.email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Informe seu nome e capture uma foto do rosto.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nome completo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _controladorNome,
                    enabled: !_salvando,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    cursorColor: _azulPrincipal,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _textoPrincipal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Digite seu nome completo',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(15),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borda),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _azulPrincipal,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  CheckboxListTile(
                    value: _consentimentoAutorizado,
                    onChanged: _salvando
                        ? null
                        : (valor) {
                            setState(() {
                              _consentimentoAutorizado = valor ?? false;

                              if (!_consentimentoAutorizado) {
                                _fotoRosto = null;
                              }
                            });
                          },
                    activeColor: _azulPrincipal,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Autorizo o uso do meu nome e imagem facial '
                      'para autenticação de acesso.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textoSecundario,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
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
                        Text(
                          'Registro facial',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          foto == null
                              ? 'Abra a câmera para tirar sua foto.'
                              : 'Confira sua foto ou capture novamente.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 220,
                          child: foto == null
                              ? Image.asset(
                                  'assets/imagens/guia_rosto.png',
                                  fit: BoxFit.contain,
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    foto,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _salvando || _abrindoCamera
                                ? null
                                : _capturarRosto,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(
                              foto == null
                                  ? 'Capturar rosto'
                                  : 'Tirar outra foto',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _azulPrincipal,
                              side: const BorderSide(
                                color: _azulPrincipal,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A foto será enviada ao finalizar o cadastro.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _salvando || _abrindoCamera
                          ? null
                          : _finalizarCadastro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _azulPrincipal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Finalizar cadastro',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
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
  }
}
