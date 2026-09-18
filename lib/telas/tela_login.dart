import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tela_cadastro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _controladorEmail = TextEditingController();
  final TextEditingController _controladorSenha = TextEditingController();

  static const Color _azulPrincipal = Color(0xFF0B4F8A);
  static const Color _azulMarca = Color(0xFF083B68);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
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
    TextInputType tipoTeclado = TextInputType.text,
    TextInputAction acaoTeclado = TextInputAction.next,
  }) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controlador,
        obscureText: ocultarTexto,
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
          focusedBorder: _bordaCampo(
            cor: _azulPrincipal,
            largura: 1.5,
          ),
        ),
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
                    'Bem-vindo(a)',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: _textoPrincipal,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Entre com sua conta institucional para continuar.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _textoSecundario,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 56),
                  Text(
                    'E-mail Institucional',
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
                    dica: 'codpessoa@pucminas.edu.br',
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
                    acaoTeclado: TextInputAction.done,
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
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
                      onPressed: () {
                        FocusScope.of(context).unfocus();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TelaCadastro(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _azulPrincipal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
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