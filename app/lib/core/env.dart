class AppEnv {
  AppEnv._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  // Não adicione chaves secretas aqui: todo --dart-define vai para o bundle
  // web público. Segredos ficam nas Edge Functions (supabase secrets set).
}