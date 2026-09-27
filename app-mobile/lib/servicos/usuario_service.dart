import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String categoria,
  }) async {
    final doc = await _db.collection('usuario').add({
      'nome': nome,
      'email': email,
      'senha': senha,
      'categoria': categoria,
    });

    return doc.id;
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorEmail(
    String email,
  ) async {
    final snapshot = await _db
        .collection('usuario')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return {
      'id': doc.id,
      ...doc.data(),
    };
  }
}