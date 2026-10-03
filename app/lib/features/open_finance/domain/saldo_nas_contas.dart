import 'conta_bancaria_conectada.dart';

/// Saldo das contas (corrente/poupança) de uma conexão.
class SaldoBanco {
  const SaldoBanco({required this.nomeBanco, required this.saldoCents});

  final String nomeBanco;
  final int saldoCents;
}

/// Quanto o usuário tem nas contas dos bancos conectados, como os bancos
/// informaram na última sincronização — o número que ele compara com o app do
/// banco (o saldo do mês é só o que entrou e saiu no mês).
class SaldoNasContas {
  const SaldoNasContas({required this.porBanco, required this.atualizadoEm});

  final List<SaldoBanco> porBanco;

  /// Atualização mais antiga entre os bancos: o total só vale até ela.
  final DateTime atualizadoEm;

  int get totalCents => porBanco.fold(0, (s, b) => s + b.saldoCents);
}

/// Null se nenhum banco conectado informou saldo.
SaldoNasContas? saldoNasContas(List<ContaBancariaConectada> contas) {
  final comSaldo = contas.where((c) => c.saldoContasCents != null).toList();
  if (comSaldo.isEmpty) return null;
  return SaldoNasContas(
    porBanco: [
      for (final c in comSaldo)
        SaldoBanco(nomeBanco: c.nomeBanco, saldoCents: c.saldoContasCents!),
    ],
    atualizadoEm: comSaldo
        .map((c) => c.ultimoSync)
        .reduce((a, b) => a.isBefore(b) ? a : b),
  );
}
