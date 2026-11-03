import 'package:firebase_auth/firebase_auth.dart';

class UsuarioAutenticado {
  const UsuarioAutenticado({required this.uid, required this.email});
  final String uid;
  final String email;
}

abstract class Autenticacao {
  Stream<UsuarioAutenticado?> get alteracoes;
  Future<void> entrar(String email, String senha);
  Future<void> criarConta(String email, String senha);
  Future<void> recuperarSenha(String email);
  Future<void> sair();
}

class AutenticacaoService implements Autenticacao {
  AutenticacaoService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  @override
  Stream<UsuarioAutenticado?> get alteracoes => _auth.authStateChanges().map(
    (usuario) => usuario == null
        ? null
        : UsuarioAutenticado(uid: usuario.uid, email: usuario.email ?? ''),
  );

  @override
  Future<void> entrar(String email, String senha) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  @override
  Future<void> criarConta(String email, String senha) async {
    // Senhas são enviadas apenas ao Authentication, nunca ao Firestore.
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  @override
  Future<void> recuperarSenha(String email) async {
    await _auth.setLanguageCode('pt-BR');
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (erro) {
      // Não revelamos se um endereço possui uma conta.
      if (erro.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> sair() => _auth.signOut();
}

String mensagemAutenticacao(Object erro) {
  if (erro is! FirebaseAuthException) {
    return 'Não foi possível concluir. Tente novamente.';
  }
  return switch (erro.code) {
    'invalid-credential' ||
    'invalid-login-credentials' ||
    'wrong-password' ||
    'user-not-found' => 'E-mail ou senha incorretos.',
    'invalid-email' => 'Digite um e-mail válido.',
    'email-already-in-use' =>
      'Este e-mail já tem uma conta. Entre ou recupere sua senha.',
    'weak-password' || 'password-does-not-meet-requirements' =>
      'A senha não atende aos requisitos. Use uma senha mais forte.',
    'network-request-failed' =>
      'Confira sua conexão com a internet e tente novamente.',
    'too-many-requests' =>
      'Muitas tentativas. Aguarde um pouco e tente novamente.',
    'user-disabled' =>
      'Esta conta está desativada. Procure o responsável pelo projeto.',
    'operation-not-allowed' =>
      'O login por e-mail ainda não foi habilitado no projeto.',
    _ => 'Não foi possível concluir. Tente novamente.',
  };
}
