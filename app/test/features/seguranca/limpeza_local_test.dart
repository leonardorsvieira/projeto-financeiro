import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/seguranca/application/limpeza_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('limparDadosLocais apaga contas, cartões e credenciais legadas', () async {
    SharedPreferences.setMockInitialValues({
      'open_finance_contas_v1': '[{"id":"item_1"}]',
      'open_finance_pluggy_creds_v1': '{"client_secret":"x"}',
      'cartoes_v1': '[]',
      'biometria_ativa': true,
    });

    await limparDadosLocais();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
