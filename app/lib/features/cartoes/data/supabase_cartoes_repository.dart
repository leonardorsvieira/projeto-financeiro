import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/cartao_credito.dart';
import '../domain/cartoes_repository.dart';

class SupabaseCartoesRepository implements CartoesRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _table = 'cartoes';

  /// Resposta à pergunta "quais cartões você usa?" no user_metadata: vale em
  /// todos os aparelhos e não some no logout.
  static const _chavePergunta = 'cartoes_perguntado';

  @override
  Future<List<CartaoCredito>> listar() async {
    final rows = await _db
        .from(_table)
        .select()
        .order('created_at', ascending: true);
    return rows.map(CartaoCredito.fromMap).toList();
  }

  @override
  Future<void> salvar(CartaoCredito cartao) async {
    if (cartao.id.isEmpty) {
      await _db.from(_table).insert(cartao.toRow());
    } else {
      await _db.from(_table).update(cartao.toRow()).eq('id', cartao.id);
    }
  }

  @override
  Future<void> excluir(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }

  @override
  Future<bool> perguntaRespondida() async {
    return _db.auth.currentUser?.userMetadata?[_chavePergunta] == true;
  }

  @override
  Future<void> marcarPerguntaRespondida() async {
    // O Supabase faz merge do user_metadata (preserva nome e aceite dos termos).
    await _db.auth.updateUser(UserAttributes(data: {_chavePergunta: true}));
  }
}
