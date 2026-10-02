import 'package:flutter_test/flutter_test.dart';
import 'package:alerta_vecinal_app/models/alert_model.dart';

void main() {
  test('AlertModel serialization test', () {
    final alert = AlertModel(
      id: 'test_1',
      sender: 'Casa 10',
      notes: 'Prueba de alerta',
      timestamp: DateTime.now(),
      active: true,
    );

    final json = alert.toJson();
    expect(json['sender'], 'Casa 10');
    expect(json['active'], true);

    final restored = AlertModel.fromJson(json);
    expect(restored.sender, 'Casa 10');
  });
}
