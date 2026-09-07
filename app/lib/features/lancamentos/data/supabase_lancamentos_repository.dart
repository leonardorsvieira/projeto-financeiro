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
    List<LancamentoItem>? itens,
    bool fixoMensal = false,
    String? serieId,
  }) async {
    final resp = await _db.from(_table).insert({
      'descricao': descricao,
      'valor_cents': valorCents,
      'categoria': categoria,
      'forma_pagamento': formaPagamento,
      'data': data.toIso8601String().substring(0, 10),
      'vencimento': vencimento?.toIso8601String().substring(0, 10),
      'obs': obs,
      'itens': itens?.map((e) => e.toMap()).toList(),
      'fixo_mensal': fixoMensal,
      'serie_id': serieId,
    }).select().single();

    final lancamento = Lancamento.fromMap(resp);

    // Se é fixa mensal, gerar cópia do próximo mês
    if (fixoMensal) {
      await gerarProximaCopiaSeFixa(lancamento);
    }

    return lancamento;
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
    List<LancamentoItem>? itens,
    bool? fixoMensal,
    String? serieId,
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
      'itens': itens?.map((e) => e.toMap()).toList(),
      'fixo_mensal': fixoMensal ?? lancamento.fixoMensal,
      'serie_id': serieId ?? lancamento.serieId,
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

  // ===== Recorrência =====

  @override
  Future<Lancamento?> gerarProximaCopiaSeFixa(Lancamento lancamento) async {
    if (!lancamento.fixoMensal || lancamento.serieId == null) return null;

    final userId = _db.auth.currentUser?.id;
    if (userId == null) return null;

    // Verificar se já existe cópia para o próximo mês
    final proximoMes = _calcularProximoMes(lancamento.data);
    final existe = await _db
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('serie_id', lancamento.serieId!)
        .eq('data', proximoMes.toIso8601String().substring(0, 10))
        .maybeSingle();

    if (existe != null) return null; // já existe

    // Criar cópia
    final copia = Lancamento(
      id: '', // será gerado pelo banco
      descricao: lancamento.descricao,
      valorCents: lancamento.valorCents,
      categoria: lancamento.categoria,
      formaPagamento: lancamento.formaPagamento,
      data: proximoMes,
      vencimento: lancamento.vencimento != null
          ? _calcularProximoMes(lancamento.vencimento!)
          : null,
      obs: lancamento.obs,
      itens: lancamento.itens,
      fixoMensal: true,
      serieId: lancamento.serieId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final resp = await _db.from(_table).insert(copia.toMap()).select().single();
    return Lancamento.fromMap(resp);
  }

  @override
  Future<void> ensureVigenteCopies() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    final agora = DateTime.now();
    final mesAtual = DateTime(agora.year, agora.month);
    final proximoMes = DateTime(agora.year, agora.month + 1);

    // Buscar todas as séries fixas do usuário
    final series = await _db
        .from(_table)
        .select('serie_id')
        .eq('user_id', userId)
        .eq('fixo_mensal', true)
        .not('serie_id', 'is', null);

    final seriesIds = series
        .map((e) => e['serie_id'] as String)
        .toSet()
        .toList();

    for (final serieId in seriesIds) {
      // Verificar mês atual
      final atual = await _db
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('serie_id', serieId)
          .gte('data', mesAtual.toIso8601String().substring(0, 10))
          .lt('data', proximoMes.toIso8601String().substring(0, 10))
          .maybeSingle();

      if (atual == null) {
        // Buscar o último da série para usar como base
        final base = await _db
            .from(_table)
            .select()
            .eq('user_id', userId)
            .eq('serie_id', serieId)
            .order('data', ascending: false)
            .limit(1)
            .maybeSingle();
        if (base != null) {
          await gerarProximaCopiaSeFixa(Lancamento.fromMap(base));
        }
      }

      // Verificar próximo mês
      final mesSeguinte = DateTime(agora.year, agora.month + 2);
      final prox = await _db
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('serie_id', serieId)
          .gte('data', proximoMes.toIso8601String().substring(0, 10))
          .lt('data', mesSeguinte.toIso8601String().substring(0, 10))
          .maybeSingle();

      if (prox == null) {
        final base = await _db
            .from(_table)
            .select()
            .eq('user_id', userId)
            .eq('serie_id', serieId)
            .order('data', ascending: false)
            .limit(1)
            .maybeSingle();
        if (base != null) {
          await gerarProximaCopiaSeFixa(Lancamento.fromMap(base));
        }
      }
    }
  }

  @override
  Future<void> excluirSerie(String serieId) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    await _db.from(_table).delete().eq('user_id', userId).eq('serie_id', serieId);
  }

  DateTime _calcularProximoMes(DateTime data) {
    int ano = data.year;
    int mes = data.month + 1;
    if (mes > 12) {
      mes = 1;
      ano++;
    }
    int dia = data.day;
    // Ajustar se o mês não tiver o dia (ex.: 31/fev)
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    if (dia > ultimoDia) dia = ultimoDia;
    return DateTime(ano, mes, dia);
  }
}