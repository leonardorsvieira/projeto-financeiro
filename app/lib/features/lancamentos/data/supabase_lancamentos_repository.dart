import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/lancamento.dart';
import '../domain/lancamentos_repository.dart';

class SupabaseLancamentosRepository implements LancamentosRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _table = 'lancamentos';

  List<Lancamento> _fromRows(List<Map<String, dynamic>> rows) {
    return rows.map(Lancamento.fromMap).toList();
  }

  @override
  Stream<List<Lancamento>> watch() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('data', ascending: false)
        .map(_fromRows);
  }

  @override
  Future<Lancamento> create({
    required String descricao,
    required int valorCents,
    required String categoria,
    required String formaPagamento,
    required DateTime data,
    DateTime? vencimento,
    String? obs,
  }) async {
    final resp = await _db.from(_table).insert({
      'descricao': descricao,
      'valor_cents': valorCents,
      'categoria': categoria,
      'forma_pagamento': formaPagamento,
      'data': data.toIso8601String().substring(0, 10),
      'vencimento': vencimento?.toIso8601String().substring(0, 10),
      'obs': obs,
    }).select().single();

    return Lancamento.fromMap(resp);
  }

  @override
  Future<Lancamento> update(
    Lancamento lancamento, {
    required String descricao,
    required int valorCents,
    required String categoria,
    required String formaPagamento,
    required DateTime data,
    DateTime? vencimento,
    String? obs,
  }) async {
    final resp = await _db
        .from(_table)
        .update({
          'descricao': descricao,
          'valor_cents': valorCents,
          'categoria': categoria,
          'forma_pagamento': formaPagamento,
          'data': data.toIso8601String().substring(0, 10),
          'vencimento': vencimento?.toIso8601String().substring(0, 10),
          'obs': obs,
        })
        .eq('id', lancamento.id)
        .select()
        .single();

    return Lancamento.fromMap(resp);
  }

  @override
  Future<void> delete(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }

  @override
  Future<Lancamento?> findById(String id) async {
    final resp = await _db
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    return resp == null ? null : Lancamento.fromMap(resp);
  }
}