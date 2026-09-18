import 'package:flutter/material.dart';

class TelaConcluida extends StatelessWidget {
  const TelaConcluida({super.key});

  static const Color azulPrincipal = Color(0xFF0B4F8A);
  static const Color fundo = Color(0xFFF7FAFC);
  static const Color textoPrincipal = Color(0xFF1F2937);
  static const Color textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 72),

              // Ícone de sucesso
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9F7F0),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F9D62),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const Text(
                      'Cadastro finalizado\ncom sucesso',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textoPrincipal,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seu registro foi concluído e seus dados foram '
                      'vinculados ao sistema de acesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textoSecundario,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 123),

              // Botão Ir para login
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (rota) => rota.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: azulPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ir para login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botão Atualizar cadastro
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulPrincipal,
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: azulPrincipal,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Atualizar cadastro',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const SizedBox(
                width: double.infinity,
                child: Text(
                  'Você poderá atualizar seus dados novamente quando precisar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textoSecundario,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}