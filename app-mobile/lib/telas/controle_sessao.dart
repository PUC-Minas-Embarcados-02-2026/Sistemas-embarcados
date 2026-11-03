import 'package:flutter/material.dart';

import '../servicos/autenticacao_service.dart';
import 'tela_cadastro.dart';
import 'tela_login.dart';

class ControleSessao extends StatefulWidget {
  const ControleSessao({
    super.key,
    required this.autenticacao,
    this.construirCadastro,
  });
  final Autenticacao autenticacao;
  final Widget Function(UsuarioAutenticado usuario)? construirCadastro;

  @override
  State<ControleSessao> createState() => _ControleSessaoState();
}

class _ControleSessaoState extends State<ControleSessao> {
  late Stream<UsuarioAutenticado?> _alteracoes;
  String? _uidRotas;
  GlobalKey<NavigatorState> _rotas = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _alteracoes = widget.autenticacao.alteracoes;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsuarioAutenticado?>(
      stream: _alteracoes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível verificar sua sessão.'),
                  TextButton(
                    onPressed: () => setState(() {
                      _alteracoes = widget.autenticacao.alteracoes;
                    }),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final usuario = snapshot.data;
        if (usuario == null) {
          _uidRotas = null;
          return TelaLogin(autenticacao: widget.autenticacao);
        }
        if (_uidRotas != usuario.uid) {
          _uidRotas = usuario.uid;
          _rotas = GlobalKey<NavigatorState>();
        }

        // Ao sair ou trocar de conta, todas as rotas privadas são descartadas.
        // Inclui câmera, validação facial e conclusão, mesmo que estejam abertas.
        return NavigatorPopHandler<Object?>(
          onPopWithResult: (resultado) => _rotas.currentState?.pop(resultado),
          child: Navigator(
            key: _rotas,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) =>
                  widget.construirCadastro?.call(usuario) ??
                  TelaCadastro(
                    usuario: usuario,
                    aoSair: widget.autenticacao.sair,
                  ),
            ),
          ),
        );
      },
    );
  }
}
