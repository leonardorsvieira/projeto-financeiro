import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/acesso/application/acesso_providers.dart';
import '../features/acesso/domain/acesso.dart';
import '../features/acesso/presentation/admin_acessos_screen.dart';
import '../features/acesso/presentation/sem_acesso_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/application/aviso_login.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/consultoria/presentation/guia_investimentos_screen.dart';
import '../features/home/domain/app_routes.dart';
import '../features/privacidade/domain/aceite_termos.dart';
import '../features/privacidade/domain/textos_legais.dart';
import '../features/privacidade/presentation/aceite_termos_screen.dart';
import '../features/privacidade/presentation/documento_legal_screen.dart';
import '../features/privacidade/presentation/privacidade_dados_screen.dart';
import '../features/ditado/domain/rascunho_lancamento.dart';
import '../features/ditado/presentation/confirmacao_ditado_screen.dart';
import '../features/ditado/presentation/lancamento_ditado_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/lancamentos/presentation/lancamento_form_screen.dart';
import '../features/lancamentos/presentation/proximos_vencimentos_screen.dart';
import '../features/dashboard/presentation/historico_meses_screen.dart';
import '../features/relatorios/presentation/relatorios_screen.dart';
import '../features/open_finance/presentation/open_finance_screen.dart';
import '../features/metas/presentation/metas_screen.dart';
import '../features/investimentos/presentation/investimentos_screen.dart';
import '../features/investimentos/presentation/investimento_detalhe_screen.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref.listen(authControllerProvider, (_, _) {
      notifyListeners();
    });
    // O portão de acesso depende do status da assinatura: reavalia o redirect
    // quando ele chega ou muda.
    _subAcesso = _ref.listen<AsyncValue<StatusAcesso?>>(statusAcessoProvider, (
      _,
      atual,
    ) {
      if (!atual.isLoading) _ultimaRevalidacao = DateTime.now();
      notifyListeners();
    });
    // Ao voltar ao app, reconsulta o status (o dono pode ter liberado ou
    // bloqueado nesse meio tempo), no máximo uma vez por minuto.
    _ciclo = AppLifecycleListener(onResume: _revalidarAcesso);
  }

  final Ref _ref;
  late final ProviderSubscription _sub;
  late final ProviderSubscription _subAcesso;
  late final AppLifecycleListener _ciclo;
  DateTime? _ultimaRevalidacao;

  void _revalidarAcesso() {
    final auth = _ref.read(authControllerProvider).value;
    if (auth == null || !auth.isAuthenticated) return;
    final ultima = _ultimaRevalidacao;
    final agora = DateTime.now();
    if (ultima != null && agora.difference(ultima) < const Duration(minutes: 1)) {
      return;
    }
    _ultimaRevalidacao = agora;
    _ref.invalidate(statusAcessoProvider);
  }

  @override
  void dispose() {
    _sub.close();
    _subAcesso.close();
    _ciclo.dispose();
    super.dispose();
  }
}

/// Aviso no login quando o link do e-mail já foi usado ou expirou.
const avisoLinkInvalido =
    'Este link de confirmação já foi usado ou expirou. Se você já confirmou '
    'o e-mail, é só entrar.';

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    // Endereço desconhecido nunca quebra o app. Na web isso acontece quando o
    // link de confirmação do Supabase volta com o resultado no fragmento
    // (`#access_token=...` ou `#error=...&error_code=otp_expired`), que o
    // roteador lê como rota. Vai para o splash, que leva ao login ou à home.
    onException: (_, state, router) {
      final endereco = state.uri.toString();
      if (endereco.contains('error_code=') || endereco.contains('error=')) {
        ref.read(avisoLoginProvider).definir(avisoLinkInvalido);
      }
      router.go(AppRoutes.splash);
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
      GoRoute(
        path: AppRoutes.aceiteTermos,
        builder: (_, _) => const AceiteTermosScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacidade,
        builder: (_, _) =>
            const DocumentoLegalScreen(documento: politicaDePrivacidade),
      ),
      GoRoute(
        path: AppRoutes.termos,
        builder: (_, _) => const DocumentoLegalScreen(documento: termosDeUso),
      ),
      GoRoute(
        path: AppRoutes.privacidadeEDados,
        builder: (_, _) => const PrivacidadeDadosScreen(),
      ),
      GoRoute(
        path: AppRoutes.semAcesso,
        builder: (_, _) => const SemAcessoScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAcessos,
        builder: (_, _) => const AdminAcessosScreen(),
      ),
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
        path: AppRoutes.relatorios,
        builder: (_, _) => const RelatoriosScreen(),
      ),
      GoRoute(
        path: AppRoutes.openFinance,
        builder: (_, _) => const OpenFinanceScreen(),
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
        path: AppRoutes.guiaInvestimentos,
        builder: (_, _) => const GuiaInvestimentosScreen(),
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final estado = auth.maybeWhen(data: (s) => s, orElse: () => null);
      final status = estado?.status ?? AuthStatus.unknown;
      final location = state.matchedLocation;

      if (status == AuthStatus.authenticated) {
        // Portão de re-aceite: sem o aceite da versão vigente, só a tela de
        // aceite e os dois documentos ficam acessíveis.
        if (!termosEmDia(estado?.termosVersao)) {
          const liberadas = {
            AppRoutes.aceiteTermos,
            AppRoutes.privacidade,
            AppRoutes.termos,
          };
          return liberadas.contains(location) ? null : AppRoutes.aceiteTermos;
        }
        // Portão de assinatura (UX): quem garante o acesso é o servidor.
        const entrada = {
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.splash,
          AppRoutes.aceiteTermos,
        };
        final statusAcesso = ref.read(statusAcessoProvider);
        switch (decidirAcesso(statusAcesso)) {
          case DecisaoAcesso.aguardando:
            // Espera o status no splash em vez de piscar a home.
            if (entrada.contains(location)) {
              return location == AppRoutes.splash ? null : AppRoutes.splash;
            }
            return null;
          case DecisaoAcesso.bloqueado:
            // Sem acesso, só a tela de aviso e as telas de dados e documentos.
            const liberadas = {
              AppRoutes.semAcesso,
              AppRoutes.privacidadeEDados,
              AppRoutes.privacidade,
              AppRoutes.termos,
            };
            return liberadas.contains(location) ? null : AppRoutes.semAcesso;
          case DecisaoAcesso.liberado:
            if (entrada.contains(location) || location == AppRoutes.semAcesso) {
              return AppRoutes.home;
            }
            // A lista de acessos é só do administrador (o RLS já impede a
            // escrita de quem não é; isto evita abrir uma tela vazia).
            if (location == AppRoutes.adminAcessos &&
                !(statusAcesso.value?.admin ?? false)) {
              return AppRoutes.home;
            }
            return null;
        }
      } else if (status == AuthStatus.unauthenticated) {
        if (location == AppRoutes.home ||
            location == AppRoutes.splash ||
            location == AppRoutes.aceiteTermos ||
            location == AppRoutes.semAcesso ||
            location == AppRoutes.adminAcessos ||
            location == AppRoutes.privacidadeEDados) {
          return AppRoutes.login;
        }
      }
      return null;
    },
  );
});