import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/investimento.dart';
import '../domain/investimentos_repository.dart';

class SupabaseInvestimentosRepository implements InvestimentosRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _table = 'investimentos';

  List<Investimento> _fromRows(List<Map<String, dynamic>> rows) {
    return rows.map(Investimento.fromMap).toList();
  }

  Map<String, dynamic> _toDb(Investimento investimento) {
    final map = <String, dynamic>{
      'nome': investimento.nome,
      'classe': investimento.classe.dbValue,
    };
    if (investimento.ePorQuantidade) {
      map['quantidade'] = investimento.quantidade;
      map['preco_atual_cents'] = investimento.precoAtualCents;
      map['saldo_cents'] = 0;
    } else {
      map['saldo_cents'] = investimento.saldoCents;
      map['quantidade'] = 0;
      map['preco_atual_cents'] = 0;
    }
    return map;
  }

  @override
  Stream<List<Investimento>> watch() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('nome', ascending: true)
        .map(_fromRows);
  }

  @override
  Future<Investimento> create(Investimento investimento) async {
    final resp = await _db
        .from(_table)
        .insert(_toDb(investimento))
        .select()
        .single();
    return Investimento.fromMap(resp);
  }

  @override
  Future<Investimento> update(Investimento investimento) async {
    final resp = await _db
        .from(_table)
        .update(_toDb(investimento))
        .eq('id', investimento.id)
        .select()
        .single();
    return Investimento.fromMap(resp);
  }

  @override
  Future<void> delete(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }
}
