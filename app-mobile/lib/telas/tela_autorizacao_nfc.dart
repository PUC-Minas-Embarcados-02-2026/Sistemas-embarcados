import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pede autorização para usar o celular como cartão de acesso (NFC/RFID).
/// Fecha devolvendo `true` (permitiu), `false` (agora não) ou `null`
/// (voltou sem decidir).
class TelaAutorizacaoNfc extends StatelessWidget {
  const TelaAutorizacaoNfc({super.key});

  static const Color _azul = Color(0xFF0B4F8A);
  static const Color _textoPrincipal = Color(0xFF1F2937);
  static const Color _textoSecundario = Color(0xFF6B7280);

  static const List<({IconData icone, String texto})> _pontos = [
    (
      icone: Icons.contactless_outlined,
      texto: 'Você aproxima o celular do leitor da catraca, como se fosse '
          'um cartão.',
    ),
    (
      icone: Icons.privacy_tip_outlined,
      texto: 'Apenas um identificador do seu cadastro será usado. Sua foto '
          'e seu e-mail não são enviados ao leitor.',
    ),
    (
      icone: Icons.tune,
      texto: 'Você pode mudar de ideia quando quiser, na tela Meu cadastro.',
    ),
    (
      icone: Icons.android,
      texto: 'Disponível em celulares Android com NFC.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Acesso por NFC'),
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
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _azul.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.nfc, size: 36, color: _azul),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Usar o celular como cartão de acesso?',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Além do reconhecimento facial, você pode abrir a '
                          'porta aproximando o celular do leitor.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 22),
                        for (final ponto in _pontos)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(ponto.icone, size: 22, color: _azul),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ponto.texto,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: _textoPrincipal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF5FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'O uso do NFC na catraca será liberado em uma '
                            'próxima versão. Sua escolha já fica registrada.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _textoSecundario,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _azul,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Permitir'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Agora não'),
                        ),
                      ),
                    ],
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
