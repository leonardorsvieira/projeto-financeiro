import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/movimento_investimento.dart';
import '../domain/movimentos_investimento_repository.dart';

class SupabaseMovimentosInvestimentoRepository
    implements MovimentosInvestimentoRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _table = 'movimentos_investimento';

  List<MovimentoInvestimento> _fromRows(List<Map<String, dynamic>> rows) {
    return rows.map(MovimentoInvestimento.fromMap).toList();
  }

  @override
  Stream<List<MovimentoInvestimento>> watchPorInvestimento(
    String investimentoId,
  ) {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('investimento_id', investimentoId)
        .order('data', ascending: false)
        .map(_fromRows);
  }

  @override
  Future<MovimentoInvestimento> create(MovimentoInvestimento movimento) async {
    final resp = await _db
        .from(_table)
        .insert({
          'investimento_id': movimento.investimentoId,
          'tipo': movimento.tipo.dbValue,
          'quantidade': movimento.quantidade,
          'preco_unit_cents': movimento.precoUnitCents,
          'data': movimento.toMap()['data'],
        })
        .select()
        .single();
    return MovimentoInvestimento.fromMap(resp);
  }

  @override
  Future<void> delete(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }
}
