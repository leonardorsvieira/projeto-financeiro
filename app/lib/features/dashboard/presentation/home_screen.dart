import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../home/domain/app_routes.dart';
import '../../lancamentos/presentation/lancamentos_list_screen.dart';
import '../../lancamentos/presentation/lembretes_preferencias_dialog.dart';
import '../../seguranca/presentation/bloqueio_biometrico_dialog.dart';
import '../../../theme/theme_selector_dialog.dart';
import '../../cartoes/presentation/cartoes_screen.dart';
import '../../cartoes/application/cartoes_providers.dart';
import '../../cartoes/application/cartoes_notificacoes_service.dart';
import 'dashboard_screen.dart';

/// Primeira tela autenticada (`/home`): tab **Resumo** (dashboard) e tab
/// **Lançamentos** (lista). Centraliza AppBar, ações e FABs.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cartoes = await ref.read(cartoesRepositoryProvider).getCartoes();
      await CartoesNotificacoesService.agendarNotificacoesCartoes(cartoes);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined),
            const SizedBox(width: 8),
            Text(
              'Meu Bolso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.space_dashboard_outlined), text: 'Dashboard'),
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'Lançamentos'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opções',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'historico') {
                context.push(AppRoutes.historicoMeses);
              } else if (value == 'relatorios') {
                context.push(AppRoutes.relatorios);
              } else if (value == 'investimentos') {
                context.push(AppRoutes.investimentos);
              } else if (value == 'metas') {
                context.push(AppRoutes.metas);
              } else if (value == 'vencimentos') {
                context.push(AppRoutes.proximosVencimentos);
              } else if (value == 'lembretes') {
                abrirPreferenciasLembretes(context, ref);
              } else if (value == 'cartoes') {
                abrirGerenciadorCartoes(context);
              } else if (value == 'biometria') {
                mostrarDialogoBloqueioBiometrico(context);
              } else if (value == 'tema') {
                mostrarDialogoSelecaoTema(context);
              } else if (value == 'signout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'historico',
                child: ListTile(
                  leading: Icon(Icons.history_outlined),
                  title: Text('Histórico de Meses'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'relatorios',
                child: ListTile(
                  leading: Icon(Icons.bar_chart_outlined),
                  title: Text('Relatórios & Comparativos'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'investimentos',
                child: ListTile(
                  leading: Icon(Icons.pie_chart_outline),
                  title: Text('Investimentos'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'metas',
                child: ListTile(
                  leading: Icon(Icons.track_changes_outlined),
                  title: Text('Metas'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'vencimentos',
                child: ListTile(
                  leading: Icon(Icons.event_outlined),
                  title: Text('Próximos Vencimentos'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'cartoes',
                child: ListTile(
                  leading: Icon(Icons.credit_card_outlined),
                  title: Text('Meus Cartões de Crédito'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'tema',
                child: ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Aparência & Tema'),
                  dense: true,
                ),
              ),
              if (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)) ...[
                const PopupMenuItem(
                  value: 'lembretes',
                  child: ListTile(
                    leading: Icon(Icons.notifications_outlined),
                    title: Text('Lembretes'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'biometria',
                  child: ListTile(
                    leading: Icon(Icons.fingerprint),
                    title: Text('Segurança & Biometria'),
                    dense: true,
                  ),
                ),
              ],
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sair'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardScreen(),
          LancamentosListScreen(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ditar',
            onPressed: () => context.push(AppRoutes.lancamentoDitado),
            icon: const Icon(Icons.mic),
            label: const Text('Ditar'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'novo',
            tooltip: 'Novo lançamento',
            onPressed: () => context.push(AppRoutes.lancamentoNovo),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}