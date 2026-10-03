/// O que o cliente quer com o dinheiro.
enum ObjetivoInvestimento {
  reserva('Montar minha reserva de emergência'),
  aposentadoria('Aposentadoria / independência financeira'),
  bem('Comprar um bem (casa, carro, viagem)'),
  renda('Ter uma renda extra com os investimentos'),
  crescer('Fazer o patrimônio crescer');

  const ObjetivoInvestimento(this.rotulo);

  final String rotulo;
}

/// Quando o cliente pretende usar o dinheiro.
enum PrazoInvestimento {
  curto('Até 2 anos'),
  medio('De 2 a 5 anos'),
  longo('Mais de 5 anos');

  const PrazoInvestimento(this.rotulo);

  final String rotulo;
}

/// Quanto de oscilação o cliente aceita.
enum ToleranciaRisco {
  conservador('Conservador', 'Não aceito ver meu dinheiro diminuir'),
  moderado('Moderado', 'Aceito oscilações para ganhar um pouco mais'),
  arrojado(
    'Arrojado',
    'Aceito perdas no curto prazo em busca de mais retorno',
  );

  const ToleranciaRisco(this.rotulo, this.descricao);

  final String rotulo;
  final String descricao;
}

/// Perfil que o cliente informa antes de gerar o guia. Sem os três campos o
/// guia não é gerado (a orientação depende deles).
class PerfilInvestidor {
  const PerfilInvestidor({
    this.objetivo,
    this.prazo,
    this.risco,
    this.observacao = '',
  });

  static const int maxObservacao = 300;

  final ObjetivoInvestimento? objetivo;
  final PrazoInvestimento? prazo;
  final ToleranciaRisco? risco;

  /// Comentário livre do cliente (ex.: "quero trocar de carro em 2028").
  final String observacao;

  bool get completo => objetivo != null && prazo != null && risco != null;

  PerfilInvestidor copyWith({
    ObjetivoInvestimento? objetivo,
    PrazoInvestimento? prazo,
    ToleranciaRisco? risco,
    String? observacao,
  }) {
    return PerfilInvestidor(
      objetivo: objetivo ?? this.objetivo,
      prazo: prazo ?? this.prazo,
      risco: risco ?? this.risco,
      observacao: observacao ?? this.observacao,
    );
  }

  /// Texto do perfil para o prompt; a observação é cortada no limite.
  String paraPrompt() {
    final obs = observacao.trim();
    final obsCurta = obs.length > maxObservacao
        ? obs.substring(0, maxObservacao)
        : obs;
    return [
      'Objetivo principal: ${objetivo?.rotulo ?? 'não informado'}',
      'Prazo para usar o dinheiro: ${prazo?.rotulo ?? 'não informado'}',
      'Tolerância a risco: '
          '${risco == null ? 'não informada' : '${risco!.rotulo} '
              '(${risco!.descricao.toLowerCase()})'}',
      if (obsCurta.isNotEmpty) 'Observação do cliente: "$obsCurta"',
    ].join('\n');
  }
}
