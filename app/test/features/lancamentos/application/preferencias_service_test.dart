import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/application/preferencias_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PreferenciasLembretes', () {
    test('padrão é 09:00', () {
      expect(PreferenciasLembretes.padrao.hora, 9);
      expect(PreferenciasLembretes.padrao.minuto, 0);
      expect(PreferenciasLembretes.padrao.label, '09:00');
    });

    test('label formata com zero à esquerda', () {
      const p = PreferenciasLembretes(hora: 7, minuto: 5);
      expect(p.label, '07:05');
    });

    test('fromMap aplica padrão quando vazio', () {
      expect(PreferenciasLembretes.fromMap(const {}).hora, 9);
      expect(PreferenciasLembretes.fromMap(const {'hora': 8}).minuto, 0);
    });
  });

  group('PreferenciasService', () {
    test('carrega padrão quando nada salvo', () async {
      final prefs = await PreferenciasService().carregarLembretes();
      expect(prefs.hora, 9);
      expect(prefs.minuto, 0);
    });

    test('salva e recarrega', () async {
      final service = PreferenciasService();
      await service.salvarLembretes(
        const PreferenciasLembretes(hora: 15, minuto: 30),
      );
      final carregado = await service.carregarLembretes();
      expect(carregado.hora, 15);
      expect(carregado.minuto, 30);
      expect(carregado.label, '15:30');
    });
  });
}