import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Tamanho máximo da foto salva no Firestore (o documento aceita ~1 MB).
const int limiteFotoBytes = 700 * 1024;

/// Devolve a foto como veio se ela couber no limite. Caso contrário,
/// reduz as dimensões e a qualidade (JPEG) até caber, sem travar a tela.
Future<Uint8List> reduzirFotoSeNecessario(
  Uint8List bytes, {
  int limite = limiteFotoBytes,
}) {
  if (bytes.lengthInBytes <= limite) return Future.value(bytes);
  return compute(_reduzir, <Object>[bytes, limite]);
}

Uint8List _reduzir(List<Object> argumentos) {
  final bytes = argumentos[0] as Uint8List;
  final limite = argumentos[1] as int;

  final decodificada = img.decodeImage(bytes);
  if (decodificada == null) return bytes;

  // Aplica a rotação gravada pela câmera (EXIF) para a foto não ficar de lado.
  final base = img.bakeOrientation(decodificada);
  final maiorLado = base.width >= base.height ? base.width : base.height;

  Uint8List? menor;
  for (final lado in const [1280, 1024, 800, 640]) {
    final img.Image candidata;
    if (maiorLado <= lado) {
      candidata = base;
    } else if (base.width >= base.height) {
      candidata = img.copyResize(base, width: lado);
    } else {
      candidata = img.copyResize(base, height: lado);
    }

    for (final qualidade in const [85, 75, 65, 55]) {
      final jpg = Uint8List.fromList(
        img.encodeJpg(candidata, quality: qualidade),
      );
      if (jpg.lengthInBytes <= limite) return jpg;
      if (menor == null || jpg.lengthInBytes < menor.lengthInBytes) {
        menor = jpg;
      }
    }
  }
  return menor ?? bytes;
}
