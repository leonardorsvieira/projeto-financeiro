import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/env.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/lancamentos/application/lembretes_controller.dart';
import 'features/seguranca/application/limpeza_local.dart';
import 'features/seguranca/presentation/biometric_lock_wrapper.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/glass.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppEnv.supabaseUrl.isNotEmpty && AppEnv.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      publishableKey: AppEnv.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(persistSession: true),
    );
  } else {
    debugPrint(
      'AVISO: SUPABASE_URL/SUPABASE_ANON_KEY ausentes — rode com '
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  runApp(const _SessaoIsolada());
}

ProviderContainer _novoContainer() {
  final container = ProviderContainer();
  // Inicia a sincronização de lembretes apenas em mobile (notificação local).
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    container.read(lembretesControllerProvider);
  }
  return container;
}

/// Isola a sessão de cada usuário: quando alguém sai (ou a sessão expira, ou
/// outra conta entra), apaga os dados locais e descarta TODO o estado em
/// memória (streams, caches, router), para que nada do usuário anterior
/// apareça para o próximo no mesmo aparelho/navegador.
class _SessaoIsolada extends StatefulWidget {
  const _SessaoIsolada();

  @override
  State<_SessaoIsolada> createState() => _SessaoIsoladaState();
}

class _SessaoIsoladaState extends State<_SessaoIsolada> {
  late ProviderContainer _container = _criarContainer();

  ProviderContainer _criarContainer() {
    final container = _novoContainer();
    container.listen<AsyncValue<AuthState>>(authControllerProvider, (
      anterior,
      atual,
    ) {
      final antes = anterior?.value;
      final agora = atual.value;
      if (antes == null || !antes.isAuthenticated || agora == null) return;
      if (!agora.isAuthenticated || agora.email != antes.email) {
        _reiniciarSessao();
      }
    });
    return container;
  }

  Future<void> _reiniciarSessao() async {
    await limparDadosLocais();
    if (!mounted) return;
    final antigo = _container;
    setState(() => _container = _criarContainer());
    WidgetsBinding.instance.addPostFrameCallback((_) => antigo.dispose());
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      key: ObjectKey(_container),
      container: _container,
      child: const MeuBolsoApp(),
    );
  }
}

class MeuBolsoApp extends ConsumerWidget {
  const MeuBolsoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'Meu Bolso',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return GlassBackground(
          child: BiometricLockWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
