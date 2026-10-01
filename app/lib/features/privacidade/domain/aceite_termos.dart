import 'controlador.dart';

/// Metadados gravados no usuário (Supabase `user_metadata`) como evidência do
/// aceite da Política de Privacidade e dos Termos de Uso: a versão aceita e o
/// momento do aceite em ISO 8601 UTC.
Map<String, String> metadadosDeAceite({
  String versao = versaoDocumentos,
  DateTime? agora,
}) {
  return {
    'termos_versao': versao,
    'termos_aceitos_em': (agora ?? DateTime.now()).toUtc().toIso8601String(),
  };
}

/// O aceite vale só se for da versão vigente dos documentos.
bool termosEmDia(String? versaoAceita) => versaoAceita == versaoDocumentos;
