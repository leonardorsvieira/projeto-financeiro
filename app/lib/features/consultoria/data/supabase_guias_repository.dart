import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/guia_investimentos.dart';
import '../domain/perfil_investidor.dart';

/// Tabela `guias_investimento`: uma linha por usuário (RLS por `user_id`).
class SupabaseGuiasRepository implements GuiasRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _table = 'guias_investimento';

  @override
  Future<GuiaSalvo> carregar() async {
    final row = await _db
        .from(_table)
        .select('perfil, guia')
        .maybeSingle();
    if (row == null) return const GuiaSalvo();
    return GuiaSalvo(
      perfil: PerfilInvestidor.fromJson(row['perfil']),
      guia: GuiaInvestimentos.fromJson(row['guia']),
    );
  }

  /// Upsert só das colunas enviadas: salvar o perfil não apaga o guia e
  /// vice-versa.
  Future<void> _salvar(Map<String, dynamic> colunas) async {
    final usuario = _db.auth.currentUser;
    if (usuario == null) throw StateError('Sem sessão.');
    await _db.from(_table).upsert({
      'user_id': usuario.id,
      ...colunas,
      'atualizado_em': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  @override
  Future<void> salvarPerfil(PerfilInvestidor perfil) =>
      _salvar({'perfil': perfil.toJson()});

  @override
  Future<void> salvarGuia(GuiaInvestimentos guia) =>
      _salvar({'guia': guia.toJson()});
}
