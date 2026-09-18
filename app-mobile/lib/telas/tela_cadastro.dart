import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tela_concluida.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final TextEditingController _controladorNome = TextEditingController();

  bool _consentimentoAutorizado = false;

  static const Color _azulPrincipal = Color(0xFF0B4F8A);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _borda = Color(0xFFD6DEE8);

  @override
  void dispose() {
    _controladorNome.dispose();
    super.dispose();
  }

  void _avisarProximaEtapa() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A câmera será configurada na próxima etapa.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(
                    height: 32,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(16),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.chevron_left,
                              size: 30,
                              color: _azulPrincipal,
                            ),
                          ),
                        ),
                        Text(
                          'CADASTRO',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _azulPrincipal,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Complete seu cadastro',
                    style: GoogleFonts.inter(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: _textoPrincipal,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Informe seu nome e faça o registro facial para habilitar seu acesso.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _textoSecundario,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Nome completo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textoPrincipal,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 52,
                    child: TextField(
                      controller: _controladorNome,
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
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: _textoSecundario,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
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
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 366,
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
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Posicione seu rosto dentro da moldura.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _textoSecundario,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Image.asset(
                          'assets/imagens/guia_rosto.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _avisarProximaEtapa,
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
                            child: Text(
                              'Capturar rosto',
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
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 62,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _consentimentoAutorizado =
                                  !_consentimentoAutorizado;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _consentimentoAutorizado
                                  ? _azulPrincipal
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _consentimentoAutorizado
                                    ? _azulPrincipal
                                    : _borda,
                                width: 1.5,
                              ),
                            ),
                            child: _consentimentoAutorizado
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Autorizo o uso do meu nome e imagem facial para autenticação de acesso.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _textoSecundario,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TelaConcluida(),
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