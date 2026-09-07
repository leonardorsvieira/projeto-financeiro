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
            tooltip: 'Investimentos',
            onPressed: () => context.push(AppRoutes.investimentos),
            icon: const Icon(Icons.pie_chart_outline),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (value) {
              if (value == 'signout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
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