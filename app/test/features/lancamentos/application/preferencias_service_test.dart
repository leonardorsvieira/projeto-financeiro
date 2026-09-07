import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/application/preferencias_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PreferenciasLembretes', () {
    test('padrão é 09:00, 3 dias antes', () {
      expect(PreferenciasLembretes.padrao.hora, 9);
      expect(PreferenciasLembretes.padrao.minuto, 0);
      expect(PreferenciasLembretes.padrao.diasAntes, 3);
      expect(PreferenciasLembretes.padrao.label, '09:00');
    });

    test('diasAntesNormalizado limita entre 0 e 30', () {
      expect(
        const PreferenciasLembretes(hora: 9, minuto: 0, diasAntes: -5)
            .diasAntesNormalizado,
        0,
      );
      expect(
        const PreferenciasLembretes(hora: 9, minuto: 0, diasAntes: 99)
            .diasAntesNormalizado,
        PreferenciasLembretes.diasAntesMax,
      );
      expect(
        const PreferenciasLembretes(hora: 9, minuto: 0, diasAntes: 5)
            .diasAntesNormalizado,
        5,
      );
    });

    test('label formata com zero à esquerda', () {
      const p = PreferenciasLembretes(hora: 7, minuto: 5, diasAntes: 3);
      expect(p.label, '07:05');
    });

    test('fromMap aplica padrão quando vazio', () {
      expect(PreferenciasLembretes.fromMap(const {}).hora, 9);
      expect(PreferenciasLembretes.fromMap(const {}).diasAntes, 3);
      expect(
        PreferenciasLembretes.fromMap(const {'hora': 8}).minuto,
        0,
      );
    });
  });

  group('PreferenciasService', () {
    test('carrega padrão quando nada salvo', () async {
      final prefs = await PreferenciasService().carregarLembretes();
      expect(prefs.hora, 9);
      expect(prefs.minuto, 0);
      expect(prefs.diasAntes, 3);
    });

    test('salva e recarrega', () async {
      final service = PreferenciasService();
      await service.salvarLembretes(
        const PreferenciasLembretes(hora: 15, minuto: 30, diasAntes: 5),
      );
      final carregado = await service.carregarLembretes();
      expect(carregado.hora, 15);
      expect(carregado.minuto, 30);
      expect(carregado.diasAntes, 5);
      expect(carregado.label, '15:30');
    });

    test('salva diasAntes normalizado (limites)', () async {
      final service = PreferenciasService();
      await service.salvarLembretes(
        const PreferenciasLembretes(hora: 9, minuto: 0, diasAntes: 99),
      );
      final carregado = await service.carregarLembretes();
      expect(carregado.diasAntes, PreferenciasLembretes.diasAntesMax);
    });
  });
}