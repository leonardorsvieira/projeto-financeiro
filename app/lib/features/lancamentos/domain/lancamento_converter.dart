import 'package:intl/intl.dart';

int? parseValorBRLParaCentavos(String texto) {
  final t = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (t.isEmpty) return null;

  final separadorDecimal = t.contains(',') ? ',' : '.';
  var parteInteira = t;
  String casasDecimais = '';
  if (separadorDecimal == ',') {
    final partes = t.split(',');
    if (partes.length > 2) return null;
    parteInteira = partes[0];
    casasDecimais = partes.length == 2 ? partes[1] : '';
  } else {
    final partes = t.split('.');
    if (partes.length > 2) return null;
    parteInteira = partes[0];
    casasDecimais = partes.length == 2 ? partes[1] : '';
  }

  if (casasDecimais.length > 2) return null;
  final inteira = parteInteira.replaceAll('.', '').replaceAll(',', '');
  if (inteira.isEmpty && casasDecimais.isEmpty) return null;
  final valida = RegExp(r'^\d+$');
  if (!valida.hasMatch(inteira)) return null;
  if (casasDecimais.isNotEmpty && !valida.hasMatch(casasDecimais)) {
    return null;
  }

  final total = int.parse(inteira) * 100 + int.parse(casasDecimais.padRight(2, '0'));
  if (total <= 0) return null;
  return total;
}

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String _two(int n) => n.toString().padLeft(2, '0');

String formatoBRL(int centavos) =>
    _brl.format(centavos / 100).replaceAll('\u00A0', ' ');

String formatoData(DateTime data) =>
    '${_two(data.day)}/${_two(data.month)}/${data.year}';

const categorias = [
  'Alimentação',
  'Transporte',
  'Moradia',
  'Saúde',
  'Lazer',
  'Educação',
  'Mercado',
  'Assinaturas',
  'Outros',
];

const formasPagamento = [
  'Pix',
  'Cartão de Crédito',
  'Cartão de Débito',
  'Dinheiro',
  'Boleto',
  'Transferência',
  'Outro',
];