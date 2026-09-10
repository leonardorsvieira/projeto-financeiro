import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/home/domain/app_routes.dart';
import '../features/ditado/domain/rascunho_lancamento.dart';
import '../features/ditado/domain/rascunho_investimento.dart';
import '../features/ditado/presentation/confirmacao_ditado_screen.dart';
import '../features/ditado/presentation/confirmacao_investimento_screen.dart';
import '../features/ditado/presentation/lancamento_ditado_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/lancamentos/presentation/lancamento_form_screen.dart';
import '../features/lancamentos/presentation/proximos_vencimentos_screen.dart';
import '../features/dashboard/presentation/historico_meses_screen.dart';
import '../features/metas/presentation/metas_screen.dart';
import '../features/investimentos/presentation/investimentos_screen.dart';
import '../features/investimentos/presentation/investimento_detalhe_screen.dart';
import '../features/investimentos/presentation/rendimento_form_screen.dart';
import '../features/investimentos/presentation/rendimentos_screen.dart';
import '../features/investimentos/domain/rendimento_investimento.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    _sub = ref.listen(authControllerProvider, (_, _) {
      notifyListeners();
    });
  }

  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.lancamentoNovo,
        builder: (_, _) => const LancamentoFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.lancamentoDitado,
        builder: (_, _) => const LancamentoDitadoScreen(),
      ),
      GoRoute(
        path: AppRoutes.confirmacaoDitado,
        builder: (_, state) {
          final rascunho = state.extra as RascunhoLancamento;
          return ConfirmacaoDitadoScreen(rascunho: rascunho);
        },
      ),
      GoRoute(
        path: AppRoutes.confirmacaoInvestimento,
        builder: (_, state) {
          final rascunho = state.extra as RascunhoInvestimento;
          return ConfirmacaoInvestimentoScreen(rascunho: rascunho);
        },
      ),
      GoRoute(
        path: AppRoutes.lancamentosDetalhe,
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return LancamentoFormScreen(lancamentoId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.proximosVencimentos,
        builder: (_, _) => const ProximosVencimentosScreen(),
      ),
      GoRoute(
        path: AppRoutes.metas,
        builder: (_, _) => const MetasScreen(),
      ),
      GoRoute(
        path: AppRoutes.historicoMeses,
        builder: (_, _) => const HistoricoMesesScreen(),
      ),
      GoRoute(
        path: AppRoutes.investimentos,
        builder: (_, _) => const InvestimentosScreen(),
      ),
      GoRoute(
        path: AppRoutes.investimentoDetalhe,
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return InvestimentoDetalheScreen(investimentoId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.rendimentos,
        builder: (_, _) => const RendimentosScreen(),
      ),
      GoRoute(
        path: AppRoutes.rendimentoForm,
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          final rendimento = state.extra as RendimentoInvestimento?;
          return RendimentoFormScreen(
            investimentoId: id,
            rendimento: rendimento,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final status = auth.maybeWhen(
        data: (s) => s.status,
        orElse: () => AuthStatus.unknown,
      );
      final location = state.matchedLocation;

      if (status == AuthStatus.authenticated) {
        if (location == AppRoutes.login ||
            location == AppRoutes.signup ||
            location == AppRoutes.splash) {
          return AppRoutes.home;
        }
      } else if (status == AuthStatus.unauthenticated) {
        if (location == AppRoutes.home || location == AppRoutes.splash) {
          return AppRoutes.login;
        }
      }
      return null;
    },
  );
});