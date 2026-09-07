import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Horário dos lembretes de vencimento (padrão 09:00).
class PreferenciasLembretes {
  const PreferenciasLembretes({required this.hora, required this.minuto});

  final int hora;
  final int minuto;

  static const PreferenciasLembretes padrao =
      PreferenciasLembretes(hora: 9, minuto: 0);

  String get label =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {'hora': hora, 'minuto': minuto};

  factory PreferenciasLembretes.fromMap(Map<String, dynamic> map) =>
      PreferenciasLembretes(
        hora: (map['hora'] as num?)?.toInt() ?? padrao.hora,
        minuto: (map['minuto'] as num?)?.toInt() ?? padrao.minuto,
      );
}

class PreferenciasService {
  Future<PreferenciasLembretes> carregarLembretes() async {
    final prefs = await SharedPreferences.getInstance();
    final hora = prefs.getInt('lembretes_hora');
    final minuto = prefs.getInt('lembretes_minuto');
    if (hora == null || minuto == null) return PreferenciasLembretes.padrao;
    return PreferenciasLembretes(hora: hora, minuto: minuto);
  }

  Future<void> salvarLembretes(PreferenciasLembretes prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('lembretes_hora', prefs.hora);
    await sp.setInt('lembretes_minuto', prefs.minuto);
  }
}

final preferenciasServiceProviderProvider = Provider<PreferenciasService>(
  (ref) => PreferenciasService(),
);

final preferenciasLembretesProvider =
    FutureProvider<PreferenciasLembretes>((ref) {
  return ref.watch(preferenciasServiceProviderProvider).carregarLembretes();
});