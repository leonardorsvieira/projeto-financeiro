import 'package:meubolso/features/seguranca/application/biometria_service.dart';

class FakeBiometriaRepository implements BiometriaRepository {
  FakeBiometriaRepository({
    this.available = true,
    this.authResult = true,
    this.ativoInicial = false,
  }) : _ativo = ativoInicial;

  final bool available;
  final bool authResult;
  final bool ativoInicial;

  bool _ativo;
  int authCalls = 0;

  @override
  Future<bool> isBiometricsAvailable() async => available;

  @override
  Future<bool> autenticar({String motivo = ''}) async {
    authCalls++;
    return authResult;
  }

  @override
  Future<bool> isBloqueioAtivo() async => _ativo;

  @override
  Future<void> setBloqueioAtivo(bool enabled) async {
    _ativo = enabled;
  }
}
