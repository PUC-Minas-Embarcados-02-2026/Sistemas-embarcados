import 'package:flutter_test/flutter_test.dart';
import 'package:puc_access/main.dart';

void main() {
  test('Aplicativo PUC Access é criado corretamente', () {
    const app = PucAccessApp();

    expect(app, isA<PucAccessApp>());
  });
}