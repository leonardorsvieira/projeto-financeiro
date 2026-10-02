import '../../privacidade/domain/controlador.dart';
import 'acesso.dart';

/// Quantos dias uma renovação soma à validade.
const diasRenovacao = 30;

/// Com quantos dias (ou menos) para vencer o Resumo passa a avisar.
const diasAvisoVencimento = 5;

/// Contato de quem vende o acesso (o mesmo canal da central de privacidade).
const emailVendedor = emailPrivacidade;

/// E-mail como a tabela `acessos` guarda: sem espaços nas pontas, minúsculo.
String normalizarEmail(String bruto) => bruto.trim().toLowerCase();

final _padraoEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool emailValido(String email) => _padraoEmail.hasMatch(email);

/// Só a data (sem hora).
DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Dias de calendário de [hoje] até [validoAte] (negativo = já venceu). Passa
/// por UTC para não sofrer com horário de verão nem com a hora do dia.
int diasAte(DateTime validoAte, DateTime hoje) {
  final v = DateTime.utc(validoAte.year, validoAte.month, validoAte.day);
  final h = DateTime.utc(hoje.year, hoje.month, hoje.day);
  return v.difference(h).inDays;
}

/// Validade depois de uma renovação: soma [dias] ao maior entre hoje e a
/// validade atual. Renovar uma conta "sem prazo" passa a contar a partir de
/// hoje (é assim que o dono converte uma conta antiga em mensal).
DateTime novaValidade(
  DateTime? validoAte,
  DateTime hoje, {
  int dias = diasRenovacao,
}) {
  final h = soData(hoje);
  final base = (validoAte == null || soData(validoAte).isBefore(h))
      ? h
      : soData(validoAte);
  return DateTime(base.year, base.month, base.day + dias);
}

/// Validade que bloqueia na hora: ontem.
DateTime validadeDeBloqueio(DateTime hoje) =>
    DateTime(hoje.year, hoje.month, hoje.day - 1);

enum SituacaoAcesso { semPrazo, ativo, venceEmBreve, vencido }

SituacaoAcesso situacaoAcesso(DateTime? validoAte, DateTime hoje) {
  if (validoAte == null) return SituacaoAcesso.semPrazo;
  final dias = diasAte(validoAte, hoje);
  if (dias < 0) return SituacaoAcesso.vencido;
  if (dias <= diasAvisoVencimento) return SituacaoAcesso.venceEmBreve;
  return SituacaoAcesso.ativo;
}

String rotuloSituacao(DateTime? validoAte, DateTime hoje) {
  if (validoAte == null) return 'Sem prazo';
  final dias = diasAte(validoAte, hoje);
  if (dias < 0) return 'Vencido';
  if (dias == 0) return 'Vence hoje';
  if (dias == 1) return 'Vence em 1 dia';
  if (dias <= diasAvisoVencimento) return 'Vence em $dias dias';
  return 'Ativo';
}

/// Aviso do Resumo para quem está perto de vencer, ou null (admin, sem prazo,
/// já vencido ou ainda longe).
String? textoAvisoVencimento(StatusAcesso status, DateTime hoje) {
  final validoAte = status.validoAte;
  if (status.admin || validoAte == null) return null;
  final dias = diasAte(validoAte, hoje);
  if (dias < 0 || dias > diasAvisoVencimento) return null;
  if (dias == 0) return 'Seu acesso vence hoje.';
  final quando = formatarDiaMes(validoAte);
  if (dias == 1) return 'Seu acesso vence em 1 dia ($quando).';
  return 'Seu acesso vence em $dias dias ($quando).';
}

String _dois(int n) => n.toString().padLeft(2, '0');

/// dd/MM/aaaa
String formatarData(DateTime d) =>
    '${_dois(d.day)}/${_dois(d.month)}/${d.year.toString().padLeft(4, '0')}';

/// dd/MM
String formatarDiaMes(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}';

/// aaaa-MM-dd (coluna `date` do Postgres).
String dataIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_dois(d.month)}-${_dois(d.day)}';
