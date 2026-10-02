import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lancamentos/domain/lancamento.dart'
    show categoriaMovimentacaoInvestimento, categoriaTransferenciaEntreContas;
import '../domain/contas_proprias.dart';

class SupabaseContasPropriasRepository implements ContasPropriasRepository {
  SupabaseClient get _db => Supabase.instance.client;

  static const _chave = 'contas_proprias';

  @override
  Future<List<String>> listar() async {
    final lista = _db.auth.currentUser?.userMetadata?[_chave];
    if (lista is! List) return const [];
    return [
      for (final n in lista)
        if (n is String && n.trim().isNotEmpty) n,
    ];
  }

  @override
  Future<int> marcar(String nome) async {
    final limpo = nome.trim();
    final atuais = await listar();
    if (!atuais.any(
      (n) => normalizarNomeConta(n) == normalizarNomeConta(limpo),
    )) {
      // O Supabase faz merge do user_metadata (preserva o resto).
      await _db.auth.updateUser(
        UserAttributes(
          data: {
            _chave: [...atuais, limpo],
          },
        ),
      );
    }
    // Reclassifica os importados com essa contraparte no fim da descrição
    // ("Pix enviado - NOME"). ilike: escapa % e _ do nome.
    final padrao = limpo
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final alterados = await _db
        .from('lancamentos')
        .update({'categoria': categoriaTransferenciaEntreContas})
        .like('obs', 'pluggy_id:%')
        .ilike('descricao', '%$padrao')
        .neq('categoria', categoriaTransferenciaEntreContas)
        .neq('categoria', categoriaMovimentacaoInvestimento)
        .select('id');
    return alterados.length;
  }
}
