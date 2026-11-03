import 'package:flutter/material.dart';

import '../servicos/autenticacao_service.dart';

class BotaoSair extends StatefulWidget {
  const BotaoSair({super.key, required this.aoSair, this.habilitado = true});
  final Future<void> Function() aoSair;
  final bool habilitado;

  @override
  State<BotaoSair> createState() => _BotaoSairState();
}

class _BotaoSairState extends State<BotaoSair> {
  bool _saindo = false;

  Future<void> _sair() async {
    setState(() => _saindo = true);
    try {
      await widget.aoSair();
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensagemAutenticacao(erro))));
      }
    } finally {
      if (mounted) setState(() => _saindo = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: _saindo || !widget.habilitado ? null : _sair,
    icon: const Icon(Icons.logout),
    label: Text(_saindo ? 'Saindo...' : 'Sair da conta'),
  );
}
