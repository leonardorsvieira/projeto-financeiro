import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências dos lembretes de vencimento (padrão 09:00, 3 dias antes).
class PreferenciasLembretes {
  const PreferenciasLembretes({
    required this.hora,
    required this.minuto,
    required this.diasAntes,
  });

  final int hora;
  final int minuto;

  /// Quantos dias antes do vencimento avisar (0 = só no dia).
  final int diasAntes;

  static const int diasAntesMin = 0;
  static const int diasAntesMax = 30;

  static const PreferenciasLembretes padrao =
      PreferenciasLembretes(hora: 9, minuto: 0, diasAntes: 3);

  String get label =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  int get diasAntesNormalizado =>
      diasAntes.clamp(diasAntesMin, diasAntesMax);

  Map<String, dynamic> toMap() =>
      {'hora': hora, 'minuto': minuto, 'diasAntes': diasAntes};

  factory PreferenciasLembretes.fromMap(Map<String, dynamic> map) =>
      PreferenciasLembretes(
        hora: (map['hora'] as num?)?.toInt() ?? padrao.hora,
        minuto: (map['minuto'] as num?)?.toInt() ?? padrao.minuto,
        diasAntes: (map['diasAntes'] as num?)?.toInt() ?? padrao.diasAntes,
      );
}

class PreferenciasService {
  Future<PreferenciasLembretes> carregarLembretes() async {
    final prefs = await SharedPreferences.getInstance();
    final hora = prefs.getInt('lembretes_hora');
    final minuto = prefs.getInt('lembretes_minuto');
    final diasAntes = prefs.getInt('lembretes_dias_antes');
    if (hora == null || minuto == null || diasAntes == null) {
      return PreferenciasLembretes.padrao;
    }
    return PreferenciasLembretes(
      hora: hora,
      minuto: minuto,
      diasAntes: diasAntes,
    );
  }

  Future<void> salvarLembretes(PreferenciasLembretes prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('lembretes_hora', prefs.hora);
    await sp.setInt('lembretes_minuto', prefs.minuto);
    await sp.setInt('lembretes_dias_antes', prefs.diasAntesNormalizado);
  }
}

final preferenciasServiceProviderProvider = Provider<PreferenciasService>(
  (ref) => PreferenciasService(),
);

final preferenciasLembretesProvider =
    FutureProvider<PreferenciasLembretes>((ref) {
  return ref.watch(preferenciasServiceProviderProvider).carregarLembretes();
});