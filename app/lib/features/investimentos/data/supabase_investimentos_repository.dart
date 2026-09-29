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
      'valor_investido_cents': investimento.valorInvestidoCents,
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

  @override
  Future<int> sincronizarOpenFinance(
    List<Investimento> importados, {
    required bool removerAusentes,
  }) async {
    final rows = await _db.from(_table).select().not('pluggy_id', 'is', null);
    final atuais = {
      for (final r in rows) r['pluggy_id'] as String: Investimento.fromMap(r),
    };
    var alterados = 0;
    for (final inv in importados) {
      final atual = atuais.remove(inv.pluggyId);
      if (atual == null) {
        try {
          await _db.from(_table).insert({
            ..._toDb(inv),
            'pluggy_id': inv.pluggyId,
          });
          alterados++;
        } on PostgrestException catch (e) {
          // 23505: outro aparelho importou o mesmo investimento agora.
          if (e.code != '23505') rethrow;
        }
      } else if (!_mesmaPosicao(atual, inv)) {
        await _db.from(_table).update(_toDb(inv)).eq('id', atual.id);
        alterados++;
      }
    }
    if (removerAusentes && atuais.isNotEmpty) {
      await _db
          .from(_table)
          .delete()
          .inFilter('id', atuais.values.map((i) => i.id).toList());
      alterados += atuais.length;
    }
    // Só apaga os manuais quando o Open Finance já trouxe algo para o lugar
    // deles — o Patrimônio nunca fica vazio por uma falha na Pluggy.
    if (importados.isNotEmpty) {
      final manuais = await _db
          .from(_table)
          .delete()
          .isFilter('pluggy_id', null)
          .select('id');
      alterados += manuais.length;
    }
    return alterados;
  }

  /// Evita reescrever (e disparar o realtime) quando nada mudou.
  bool _mesmaPosicao(Investimento a, Investimento b) =>
      a.nome == b.nome &&
      a.classe == b.classe &&
      a.patrimonioCents == b.patrimonioCents &&
      a.valorInvestidoCents == b.valorInvestidoCents &&
      (!a.ePorQuantidade || a.quantidade == b.quantidade);
}
