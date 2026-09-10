import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BiometriaRepository {
  Future<bool> isBiometricsAvailable();
  Future<bool> autenticar({String motivo = 'Confirme sua identidade para acessar o Meu Bolso'});
  Future<bool> isBloqueioAtivo();
  Future<void> setBloqueioAtivo(bool enabled);
}

class BiometriaService implements BiometriaRepository {
  BiometriaService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;
  static const String _prefKey = 'bloqueio_biometrico_ativo';

  @override
  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> autenticar({
    String motivo = 'Confirme sua identidade para acessar o Meu Bolso',
  }) async {
    if (kIsWeb) return true;
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Erro na autenticação biométrica: $e');
      return false;
    }
  }

  @override
  Future<bool> isBloqueioAtivo() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_prefKey) ?? false;
  }

  @override
  Future<void> setBloqueioAtivo(bool enabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_prefKey, enabled);
  }
}
