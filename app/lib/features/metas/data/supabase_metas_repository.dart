import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/meta.dart';
import '../domain/metas_repository.dart';

class SupabaseMetasRepository implements MetasRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _table = 'metas';

  List<Meta> _fromRows(List<Map<String, dynamic>> rows) {
    return rows.map(Meta.fromMap).toList();
  }

  @override
  Stream<List<Meta>> watch() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map(_fromRows);
  }

  @override
  Future<Meta> create({
    required String categoria,
    required int valorLimiteCents,
  }) async {
    final resp = await _db
        .from(_table)
        .insert({
          'categoria': categoria,
          'valor_limite_cents': valorLimiteCents,
        })
        .select()
        .single();
    return Meta.fromMap(resp);
  }

  @override
  Future<Meta> update(
    Meta meta, {
    required String categoria,
    required int valorLimiteCents,
  }) async {
    final resp = await _db
        .from(_table)
        .update({
          'categoria': categoria,
          'valor_limite_cents': valorLimiteCents,
        })
        .eq('id', meta.id)
        .select()
        .single();
    return Meta.fromMap(resp);
  }

  @override
  Future<void> delete(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }
}