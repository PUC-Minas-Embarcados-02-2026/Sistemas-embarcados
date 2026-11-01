import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tela_camera.dart';
import 'tela_concluida.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final TextEditingController _controladorNome = TextEditingController();

  bool _consentimentoAutorizado = false;
  bool _salvando = false;
  bool _abrindoCamera = false;

  String? _idCadastro;
  Uint8List? _fotoRosto;

  static const Color _azulPrincipal = Color(0xFF0B4F8A);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _borda = Color(0xFFD6DEE8);

  @override
  void dispose() {
    _controladorNome.dispose();
    super.dispose();
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _capturarRosto() async {
    if (_salvando || _abrindoCamera) return;

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
        MaterialPageRoute<Uint8List>(
          builder: (context) => const TelaCamera(),
        ),
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
  if (_salvando || _abrindoCamera) return;

  FocusScope.of(context).unfocus();

  final nome = _controladorNome.text.trim();
  final foto = _fotoRosto;

  if (nome.isEmpty) {
    _mostrarAviso('Digite seu nome completo.');
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

  setState(() {
    _salvando = true;
  });

  try {
    final usuarios = FirebaseFirestore.instance.collection('usuarios');

    final dados = <String, dynamic>{
      'nome': nome,
      'consentimento': true,
      'cadastroConcluido': true,
      'fotoRosto': Blob(foto),
      'fotoTamanhoBytes': foto.lengthInBytes,
      'fotoSalvaEm': FieldValue.serverTimestamp(),
    };

    if (_idCadastro == null) {
      dados['criadoEm'] = FieldValue.serverTimestamp();

      final documento = await usuarios.add(dados);
      _idCadastro = documento.id;
    } else {
      dados['atualizadoEm'] = FieldValue.serverTimestamp();

      // Atualiza o nome e substitui a foto no mesmo documento.
      await usuarios.doc(_idCadastro!).update(dados);
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TelaConcluida(),
      ),
    );
  } catch (erro) {
    if (!mounted) return;

    _mostrarAviso('Não foi possível salvar o cadastro e a foto: $erro');
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
                      IconButton(
                        onPressed: _salvando
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.chevron_left,
                          size: 30,
                          color: _azulPrincipal,
                        ),
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
                    'Complete seu cadastro',
                    style: GoogleFonts.inter(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: _textoPrincipal,
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
                      border: Border.all(
                        color: const Color(0xFFE7EDF3),
                      ),
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