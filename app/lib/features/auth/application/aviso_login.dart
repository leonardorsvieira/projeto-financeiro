import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mensagem única para a tela de login (ex.: 'Conta excluída.'). Devolve o
/// texto uma só vez e zera.
class AvisoLogin {
  AvisoLogin([this._mensagem]);

  String? _mensagem;

  String? consumir() {
    final mensagem = _mensagem;
    _mensagem = null;
    return mensagem;
  }
}

final avisoLoginProvider = Provider<AvisoLogin>((ref) => AvisoLogin());

/// Ponte entre sessões. Ao sair da conta o `main.dart` recria o
/// `ProviderContainer` inteiro, então nenhum provider sobrevive ao logout e o
/// aviso do login ("Conta excluída.") precisa atravessar essa troca por um
/// estado estático. Quem encerra a sessão chama [definir]; o `main.dart`
/// chama [consumir] ao criar o container novo e o entrega ao
/// [avisoLoginProvider] dele, de modo que só o login da sessão nova o mostra.
abstract final class AvisoProximaSessao {
  static String? _mensagem;

  static void definir(String mensagem) => _mensagem = mensagem;

  static String? consumir() {
    final mensagem = _mensagem;
    _mensagem = null;
    return mensagem;
  }
}
