class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';

  static const String lancamentoNovo = '/lancamentos/novo';
  static const String lancamentoDitado = '/lancamentos/ditar';
  static const String confirmacaoDitado = '/lancamentos/ditar/confirmacao';
  static const String lancamentosDetalhe = '/lancamentos/:id';
  static const String proximosVencimentos = '/vencimentos/proximos';
  static const String metas = '/metas';
  static const String investimentos = '/investimentos';
  static const String investimentoDetalhe = '/investimentos/:id';

  static String lancamentoEditar(String id) => '/lancamentos/$id';
  static String investimentoDetalheDe(String id) => '/investimentos/$id';
}