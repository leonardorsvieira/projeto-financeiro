class AppEnv {
  AppEnv._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}