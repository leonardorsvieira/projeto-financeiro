import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/rendimento_investimento.dart';
import '../domain/rendimentos_investimento_repository.dart';

class SupabaseRendimentosInvestimentoRepository
    implements RendimentosInvestimentoRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _table = 'rendimentos_investimento';

  List<RendimentoInvestimento> _fromRows(List<Map<String, dynamic>> rows) {
    return rows.map(RendimentoInvestimento.fromMap).toList();
  }

  @override
  Stream<List<RendimentoInvestimento>> watchTodos() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('data', ascending: false)
        .map(_fromRows);
  }

  @override
  Future<RendimentoInvestimento> create(
    RendimentoInvestimento rendimento,
  ) async {
    final resp = await _db
        .from(_table)
        .insert({
          'investimento_id': rendimento.investimentoId,
          'tipo': rendimento.tipo.dbValue,
          'valor_cents': rendimento.valorCents,
          'data': rendimento.toMap()['data'],
        })
        .select()
        .single();
    return RendimentoInvestimento.fromMap(resp);
  }

  @override
  Future<RendimentoInvestimento> update(
    RendimentoInvestimento rendimento,
  ) async {
    final resp = await _db
        .from(_table)
        .update({
          'tipo': rendimento.tipo.dbValue,
          'valor_cents': rendimento.valorCents,
          'data': rendimento.toMap()['data'],
        })
        .eq('id', rendimento.id)
        .select()
        .single();
    return RendimentoInvestimento.fromMap(resp);
  }

  @override
  Future<void> delete(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }
}