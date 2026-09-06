import '../domain/lancamento_converter.dart';

String? validateDescricao(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Informe uma descrição.';
  if (v.length > 200) return 'Máximo de 200 caracteres.';
  return null;
}

String? validateValor(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe um valor.';
  }
  if (parseValorBRLParaCentavos(value) == null) {
    return 'Valor inválido. Use números com até 2 casas decimais (ex.: 89,90).';
  }
  return null;
}

String? validateObs(String? value) {
  final v = value?.trim() ?? '';
  if (v.length > 500) return 'Máximo de 500 caracteres.';
  return null;
}