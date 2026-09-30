/// Saudação por período do dia: "Bom dia, Ana." ou "Bom dia." sem nome.
String saudacaoPara(DateTime agora, String? primeiroNome) {
  final base = agora.hour < 12
      ? 'Bom dia'
      : agora.hour < 18
          ? 'Boa tarde'
          : 'Boa noite';
  final nome = primeiroNome?.trim() ?? '';
  return nome.isEmpty ? '$base.' : '$base, $nome.';
}

const _diasSemana = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Data por extenso: "Terça-feira, 30 de setembro" (sem depender de locale).
String dataPorExtenso(DateTime data) {
  return '${_diasSemana[data.weekday - 1]}, ${data.day} de '
      '${_meses[data.month - 1]}';
}
