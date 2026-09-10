import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../../home/domain/app_routes.dart';
import '../../lancamentos/presentation/lancamentos_list_screen.dart';
import '../../lancamentos/presentation/lembretes_preferencias_dialog.dart';
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
        title: const Text('Meu Bolso'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumo'),
            Tab(text: 'Lançamentos'),
          ],
        ),
        actions: [
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS))
            IconButton(
              tooltip: 'Lembretes (horário e dias antes)',
              onPressed: () => abrirPreferenciasLembretes(context, ref),
              icon: const Icon(Icons.notifications_outlined),
            ),
          IconButton(
            tooltip: 'Próximos vencimentos',
            onPressed: () => context.push(AppRoutes.proximosVencimentos),
            icon: const Icon(Icons.event_outlined),
          ),
          IconButton(
            tooltip: 'Metas',
            onPressed: () => context.push(AppRoutes.metas),
            icon: const Icon(Icons.track_changes_outlined),
          ),
          IconButton(
            tooltip: 'Histórico de Meses',
            onPressed: () => context.push(AppRoutes.historicoMeses),
            icon: const Icon(Icons.history_outlined),
          ),
          IconButton(
            tooltip: 'Investimentos',
            onPressed: () => context.push(AppRoutes.investimentos),
            icon: const Icon(Icons.pie_chart_outline),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (value) {
              if (value == 'historico') {
                context.push(AppRoutes.historicoMeses);
              } else if (value == 'investimentos') {
                context.push(AppRoutes.investimentos);
              } else if (value == 'metas') {
                context.push(AppRoutes.metas);
              } else if (value == 'vencimentos') {
                context.push(AppRoutes.proximosVencimentos);
              } else if (value == 'lembretes') {
                abrirPreferenciasLembretes(context, ref);
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
              if (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS))
                const PopupMenuItem(
                  value: 'lembretes',
                  child: ListTile(
                    leading: Icon(Icons.notifications_outlined),
                    title: Text('Lembretes'),
                    dense: true,
                  ),
                ),
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