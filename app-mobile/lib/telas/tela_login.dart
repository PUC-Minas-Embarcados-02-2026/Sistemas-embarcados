import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../servicos/autenticacao_service.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key, required this.autenticacao});
  final Autenticacao autenticacao;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _controladorEmail = TextEditingController();
  final TextEditingController _controladorSenha = TextEditingController();

  final _formulario = GlobalKey<FormState>();
  final _controladorConfirmacao = TextEditingController();
  bool _criandoConta = false;
  bool _ocupado = false;
  bool _mostrarSenha = false;
  String? _mensagem;

  String? _validarEmail(String? valor) {
    final email = (valor ?? '').trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Digite um e-mail válido.';
    }
    return null;
  }

  Future<void> _enviar() async {
    if (_ocupado || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _mensagem = null;
    });
    try {
      if (_criandoConta) {
        await widget.autenticacao.criarConta(
          _controladorEmail.text.trim(),
          _controladorSenha.text,
        );
      } else {
        await widget.autenticacao.entrar(
          _controladorEmail.text.trim(),
          _controladorSenha.text,
        );
      }
      TextInput.finishAutofillContext();
      // ControleSessao faz a navegação somente após o Firebase autenticar.
    } catch (erro) {
      if (mounted) setState(() => _mensagem = mensagemAutenticacao(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _recuperarSenha() async {
    if (_ocupado) return;
    final erroEmail = _validarEmail(_controladorEmail.text);
    if (erroEmail != null) {
      setState(() => _mensagem = 'Preencha o e-mail para recuperar sua senha.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _mensagem = null;
    });
    try {
      await widget.autenticacao.recuperarSenha(_controladorEmail.text.trim());
      if (mounted) {
        setState(
          () => _mensagem = 'Se houver uma conta com esse e-mail, você receberá um link para redefinir a senha. Confira também o spam.',
        );
      }
    } catch (erro) {
      if (mounted) setState(() => _mensagem = mensagemAutenticacao(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  static const Color _azulPrincipal = Color(0xFF0B4F8A);
  static const Color _azulMarca = Color(0xFF083B68);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirmacao.dispose();
    super.dispose();
  }

  OutlineInputBorder _bordaCampo({
    Color cor = const Color(0xFFD6DEE8),
    double largura = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cor, width: largura),
    );
  }

  Widget _criarCampo({
    required TextEditingController controlador,
    required String dica,
    bool ocultarTexto = false,
    String? Function(String?)? validar,
    TextInputType tipoTeclado = TextInputType.text,
    TextInputAction acaoTeclado = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controlador,
      enabled: !_ocupado,
      validator: validar,
      obscureText: ocultarTexto && !_mostrarSenha,
      autocorrect: !ocultarTexto,
      enableSuggestions: !ocultarTexto,
      autofillHints: ocultarTexto
          ? [_criandoConta ? AutofillHints.newPassword : AutofillHints.password]
          : const [AutofillHints.email],
      onFieldSubmitted: acaoTeclado == TextInputAction.done
          ? (_) => _enviar()
          : null,
      keyboardType: tipoTeclado,
      textInputAction: acaoTeclado,
      cursorColor: _azulPrincipal,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: _textoPrincipal,
        height: 1.4,
      ),
      decoration: InputDecoration(
        hintText: dica,
        suffixIcon: ocultarTexto
            ? IconButton(
                tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                onPressed: _ocupado
                    ? null
                    : () => setState(() => _mostrarSenha = !_mostrarSenha),
                icon: Icon(
                  _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                ),
              )
            : null,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: _textoSecundario,
          height: 1.4,
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: _bordaCampo(),
        enabledBorder: _bordaCampo(),
        focusedBorder: _bordaCampo(cor: _azulPrincipal, largura: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 342),
              child: Form(
                key: _formulario,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FB),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Text(
                          'PUC MINAS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _azulPrincipal,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PUC Access',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _azulMarca,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 43),
                      Text(
                        _criandoConta ? 'Crie sua conta' : 'Bem-vindo(a)',
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: _textoPrincipal,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Use uma conta do PUC Access. A senha é criada neste aplicativo.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _textoSecundario,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 56),
                      Text(
                        'E-mail',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textoPrincipal,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _criarCampo(
                        controlador: _controladorEmail,
                        dica: 'seuemail@exemplo.com',
                        validar: _validarEmail,
                        tipoTeclado: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Senha',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textoPrincipal,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _criarCampo(
                        controlador: _controladorSenha,
                        dica: '••••••••',
                        ocultarTexto: true,
                        validar: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'Digite sua senha.';
                          }
                          if (_criandoConta && valor.length < 6) {
                            return 'Use pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                        acaoTeclado: _criandoConta
                            ? TextInputAction.next
                            : TextInputAction.done,
                      ),
                      const SizedBox(height: 14),
                      if (_criandoConta) ...[
                        const Text('Confirme a senha'),
                        const SizedBox(height: 7),
                        _criarCampo(
                          controlador: _controladorConfirmacao,
                          dica: 'Repita a senha',
                          ocultarTexto: true,
                          acaoTeclado: TextInputAction.done,
                          validar: (valor) => valor != _controladorSenha.text
                              ? 'As senhas não coincidem.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (!_criandoConta)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _ocupado ? null : _recuperarSenha,
                            style: TextButton.styleFrom(
                              foregroundColor: _azulPrincipal,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Esqueci minha senha',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _ocupado ? null : _enviar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _azulPrincipal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _ocupado
                                ? 'Aguarde...'
                                : (_criandoConta ? 'Criar conta' : 'Entrar'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _ocupado
                            ? null
                            : () => setState(() {
                                _formulario.currentState?.reset();
                                _criandoConta = !_criandoConta;
                                _controladorSenha.clear();
                                _controladorConfirmacao.clear();
                                _mensagem = null;
                              }),
                        child: Text(
                          _criandoConta
                              ? 'Já tenho uma conta'
                              : 'Criar uma conta',
                        ),
                      ),
                      if (_mensagem != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(_mensagem!),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
