import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/acesso.dart';
import '../domain/acesso_repository.dart';
import '../domain/regras_acesso.dart';

/// Acessos no Supabase: `acessos`, `administradores` e as funções
/// `acesso_ativo()` / `eh_admin()` (migration de controle de acesso). O RLS é
/// quem garante que só administrador escreve; aqui só se traduz o resultado.
class SupabaseAcessoRepository implements AcessoRepository {
  SupabaseAcessoRepository({DateTime Function()? agora})
    : _agora = agora ?? DateTime.now;

  static const _limiteDeEspera = Duration(seconds: 10);
  static const _naoEstaNaLista = 'Este e-mail não está na lista.';
  static const _falhaAoSalvar =
      'Não foi possível salvar agora. Verifique a conexão e tente novamente.';
  static const _falhaAoCarregar =
      'Não foi possível carregar a lista agora. Verifique a conexão e tente '
      'novamente.';

  final DateTime Function() _agora;

  SupabaseClient get _db => Supabase.instance.client;

  Future<T> _comLimite<T>(Future<T> consulta) =>
      consulta.timeout(_limiteDeEspera);

  /// Troca falha de rede/servidor por uma mensagem que a tela mostra como está.
  Future<T> _traduzindo<T>(Future<T> Function() acao, String mensagem) async {
    try {
      return await acao();
    } on AcessoException {
      rethrow;
    } on PostgrestException {
      throw AcessoException(mensagem);
    } on TimeoutException {
      throw AcessoException(mensagem);
    }
  }

  @override
  Future<StatusAcesso> status() async {
    final email = _db.auth.currentUser?.email;
    final temEmail = email != null && email.isNotEmpty;
    final resultados = await Future.wait<dynamic>([
      _comLimite(_db.rpc('acesso_ativo')),
      _comLimite(_db.rpc('eh_admin')),
      if (temEmail)
        _comLimite(
          _db
              .from('acessos')
              .select('valido_ate')
              .eq('email', normalizarEmail(email))
              .maybeSingle(),
        ),
    ]);
    DateTime? validoAte;
    if (temEmail) {
      final linha = resultados[2] as Map<String, dynamic>?;
      final bruto = linha?['valido_ate'];
      if (bruto is String) validoAte = soData(DateTime.parse(bruto));
    }
    return StatusAcesso(
      ativo: resultados[0] == true,
      admin: resultados[1] == true,
      validoAte: validoAte,
    );
  }

  @override
  Future<List<Acesso>> listar() => _traduzindo(() async {
    final linhas = await _comLimite(
      _db
          .from('acessos')
          .select('email, valido_ate, observacao, atualizado_em')
          .order('email'),
    );
    return [for (final l in linhas) Acesso.fromMap(l)];
  }, _falhaAoCarregar);

  @override
  Future<void> salvar(String email, DateTime? validoAte, String? observacao) =>
      _traduzindo(() async {
        final chave = normalizarEmail(email);
        if (!emailValido(chave)) {
          throw const AcessoException('Informe um e-mail válido.');
        }
        final obs = observacao?.trim();
        await _comLimite(
          _db.from('acessos').upsert({
            'email': chave,
            'valido_ate': validoAte == null ? null : dataIso(validoAte),
            'observacao': (obs == null || obs.isEmpty) ? null : obs,
            'atualizado_em': _agora().toUtc().toIso8601String(),
          }, onConflict: 'email'),
        );
      }, _falhaAoSalvar);

  @override
  Future<void> renovar(String email, {int dias = diasRenovacao}) =>
      _traduzindo(() async {
        final chave = normalizarEmail(email);
        final linha = await _comLimite(
          _db
              .from('acessos')
              .select('valido_ate')
              .eq('email', chave)
              .maybeSingle(),
        );
        if (linha == null) throw const AcessoException(_naoEstaNaLista);
        final bruto = linha['valido_ate'];
        final atual = bruto is String ? soData(DateTime.parse(bruto)) : null;
        final agora = _agora();
        await _atualizarValidade(chave, novaValidade(atual, agora, dias: dias));
      }, _falhaAoSalvar);

  @override
  Future<void> bloquear(String email) => _traduzindo(
    () => _atualizarValidade(
      normalizarEmail(email),
      validadeDeBloqueio(_agora()),
    ),
    _falhaAoSalvar,
  );

  Future<void> _atualizarValidade(String email, DateTime validoAte) async {
    // O RLS filtra em silêncio: lista vazia = não existe (ou sem permissão).
    final alteradas = await _comLimite(
      _db
          .from('acessos')
          .update({
            'valido_ate': dataIso(validoAte),
            'atualizado_em': _agora().toUtc().toIso8601String(),
          })
          .eq('email', email)
          .select('email'),
    );
    if (alteradas.isEmpty) throw const AcessoException(_naoEstaNaLista);
  }

  @override
  Future<void> remover(String email) => _traduzindo(() async {
    final removidas = await _comLimite(
      _db
          .from('acessos')
          .delete()
          .eq('email', normalizarEmail(email))
          .select('email'),
    );
    if (removidas.isEmpty) throw const AcessoException(_naoEstaNaLista);
  }, _falhaAoSalvar);
}
