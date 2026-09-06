class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';

  static const String lancamentoNovo = '/lancamentos/novo';
  static const String lancamentosDetalhe = '/lancamentos/:id';

  static String lancamentoEditar(String id) => '/lancamentos/$id';
}