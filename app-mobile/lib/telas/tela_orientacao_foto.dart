import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aviso mostrado antes de abrir a câmera, com o que atrapalha o
/// reconhecimento do rosto.
class TelaOrientacaoFoto extends StatelessWidget {
  const TelaOrientacaoFoto({super.key, required this.aoContinuar});
  final VoidCallback aoContinuar;

  static const Color _azul = Color(0xFF0B4F8A);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);

  static const List<({IconData icone, String titulo, String texto})> _dicas = [
    (
      icone: Icons.visibility_off_outlined,
      titulo: 'Retire óculos, boné e máscara',
      texto: 'Óculos (principalmente escuros), boné, chapéu, touca e máscara '
          'escondem partes do rosto.',
    ),
    (
      icone: Icons.wb_sunny_outlined,
      titulo: 'Escolha um local bem iluminado',
      texto: 'A luz deve vir de frente. Evite janelas ou lâmpadas atrás de você.',
    ),
    (
      icone: Icons.face_outlined,
      titulo: 'Olhe de frente para a câmera',
      texto: 'Rosto inteiro visível, expressão neutra e cabelo fora dos olhos.',
    ),
    (
      icone: Icons.person_outline,
      titulo: 'Apenas você na imagem',
      texto: 'Sem outras pessoas, fotos ou telas aparecendo ao fundo.',
    ),
    (
      icone: Icons.stay_current_portrait,
      titulo: 'Celular na vertical',
      texto: 'Segure na altura dos olhos e sem usar filtros.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Capturar rosto'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antes de tirar a foto',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Algumas coisas atrapalham o reconhecimento facial. '
                          'Confira antes de continuar:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final dica in _dicas)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _azul.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(dica.icone, color: _azul),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dica.titulo,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _textoPrincipal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dica.texto,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: _textoSecundario,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          'Vai cadastrar outra pessoa? Na câmera, toque no '
                          'ícone de trocar câmera para usar a traseira.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: aoContinuar,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Entendi, abrir câmera'),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
