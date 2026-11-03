import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puc_access/componentes/botao_sair.dart';
import 'package:puc_access/servicos/autenticacao_service.dart';
import 'package:puc_access/telas/controle_sessao.dart';
import 'package:puc_access/telas/tela_login.dart';

class AutenticacaoFalsa implements Autenticacao {
  final eventos = StreamController<UsuarioAutenticado?>.broadcast();
  Object? erro;
  Completer<void>? pendente;
  int entradas = 0;
  int criacoes = 0;
  int recuperacoes = 0;
  String? ultimoEmail;
  String? ultimaSenha;

  @override
  Stream<UsuarioAutenticado?> get alteracoes => eventos.stream;

  @override
  Future<void> entrar(String email, String senha) async {
    entradas++;
    ultimoEmail = email;
    ultimaSenha = senha;
    if (erro != null) throw erro!;
    if (pendente != null) await pendente!.future;
  }

  @override
  Future<void> criarConta(String email, String senha) async {
    criacoes++;
    ultimoEmail = email;
    ultimaSenha = senha;
    if (erro != null) throw erro!;
  }

  @override
  Future<void> recuperarSenha(String email) async {
    recuperacoes++;
    ultimoEmail = email;
    if (erro != null) throw erro!;
  }

  @override
  Future<void> sair() async {
    if (erro != null) throw erro!;
    eventos.add(null);
  }
}

Future<void> tocar(WidgetTester tester, String texto) async {
  final alvo = find.text(texto);
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    // Fontes substituídas pelo motor de teste, sem acesso à rede.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (mensagem) async {
          final nome = const StringCodec().decodeMessage(mensagem);
          if (nome == 'AssetManifest.bin') {
            return const StandardMessageCodec().encodeMessage({
              for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold'])
                'assets/Inter-$peso.ttf': [
                  {'asset': 'assets/Inter-$peso.ttf'},
                ],
            });
          }
          if (nome?.startsWith('assets/Inter-') ?? false) return ByteData(0);
          return null;
        });
  });

  Future<AutenticacaoFalsa> abrirLogin(WidgetTester tester) async {
    final auth = AutenticacaoFalsa();
    addTearDown(auth.eventos.close);
    await tester.pumpWidget(MaterialApp(home: TelaLogin(autenticacao: auth)));
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('campos inválidos não chamam autenticação', (tester) async {
    final auth = await abrirLogin(tester);
    await tocar(tester, 'Entrar');
    expect(auth.entradas, 0);
    expect(find.text('Digite um e-mail válido.'), findsOneWidget);
    expect(find.text('Digite sua senha.'), findsOneWidget);
  });

  testWidgets('senha incorreta mantém login e apresenta mensagem', (
    tester,
  ) async {
    final auth = await abrirLogin(tester);
    auth.erro = FirebaseAuthException(code: 'invalid-credential');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      '  teste@example.com  ',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      ' senha sem trim ',
    );
    await tocar(tester, 'Entrar');
    expect(auth.ultimoEmail, 'teste@example.com');
    expect(auth.ultimaSenha, ' senha sem trim ');
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.byType(TelaLogin), findsOneWidget);
  });

  testWidgets('bloqueia envios duplicados durante login', (tester) async {
    final auth = await abrirLogin(tester);
    auth.pendente = Completer<void>();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'teste@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tocar(tester, 'Entrar');
    await tocar(tester, 'Aguarde...');
    expect(auth.entradas, 1);
    auth.pendente!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('criação exige confirmação e usa operação de criar conta', (
    tester,
  ) async {
    final auth = await abrirLogin(tester);
    await tocar(tester, 'Criar uma conta');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'nova@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha123');
    await tester.enterText(find.byType(TextFormField).at(2), 'outrasenha');
    await tocar(tester, 'Criar conta');
    expect(auth.criacoes, 0);
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), 'senha123');
    await tocar(tester, 'Criar conta');
    expect(auth.criacoes, 1);
    expect(auth.entradas, 0);
  });

  testWidgets('recuperação valida e-mail e não exige senha', (tester) async {
    final auth = await abrirLogin(tester);
    await tocar(tester, 'Esqueci minha senha');
    expect(auth.recuperacoes, 0);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'teste@example.com',
    );
    await tocar(tester, 'Esqueci minha senha');
    expect(auth.recuperacoes, 1);
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
  });

  testWidgets(
    'sessão restaurada abre cadastro; sair remove todas as rotas privadas',
    (tester) async {
      final auth = AutenticacaoFalsa();
      addTearDown(auth.eventos.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ControleSessao(
            autenticacao: auth,
            construirCadastro: (usuario) => Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: Column(
                          children: [
                            const Text('Validação privada'),
                            BotaoSair(aoSair: auth.sair),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: Text('Cadastro ${usuario.uid}'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      auth.eventos.add(
        const UsuarioAutenticado(uid: 'a', email: 'a@example.com'),
      );
      await tester.pumpAndSettle();
      await tocar(tester, 'Cadastro a');
      expect(find.text('Validação privada'), findsOneWidget);
      await tocar(tester, 'Sair da conta');
      expect(find.byType(TelaLogin), findsOneWidget);
      expect(find.text('Validação privada'), findsNothing);
      expect(find.text('Cadastro a', skipOffstage: false), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TelaLogin), findsOneWidget);
      auth.eventos.add(
        const UsuarioAutenticado(uid: 'b', email: 'b@example.com'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cadastro b'), findsOneWidget);
      expect(find.text('Cadastro a', skipOffstage: false), findsNothing);
    },
  );

  testWidgets('falha ao sair permanece na tela e informa erro', (tester) async {
    final auth = AutenticacaoFalsa()
      ..erro = FirebaseAuthException(code: 'network-request-failed');
    addTearDown(auth.eventos.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BotaoSair(aoSair: auth.sair)),
      ),
    );
    await tocar(tester, 'Sair da conta');
    expect(find.textContaining('Confira sua conexão'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });
}
