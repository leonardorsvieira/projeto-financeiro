import '../../../theme/caderneta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/icones.dart';
import '../../auth/application/auth_controller.dart';
import '../../home/domain/app_routes.dart';
import '../../lancamentos/presentation/lancamentos_list_screen.dart';
import '../../lancamentos/presentation/lembretes_preferencias_dialog.dart';
import '../../open_finance/application/open_finance_providers.dart';
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
    // Mantém a sincronização automática do Open Finance ativa enquanto o
    // usuário está logado (a HomeScreen só existe autenticada).
    ref.watch(sincronizacaoAutomaticaProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CarimboLogo(tamanho: 30),
            const SizedBox(width: 8),
            Text(
              'Meu Bolso',
              style: CadernetaTexto.display(
                size: 22,
                italico: true,
                cor: CadernetaCores.of(context).tinta,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          // Folga para a pílula da aba selecionada (indicador do tema).
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          tabs: const [
            Tab(icon: PhosphorIcon(Icones.resumo), text: 'Resumo'),
            Tab(icon: PhosphorIcon(Icones.livroCaixa), text: 'Livro-caixa'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opções',
            icon: const PhosphorIcon(Icones.menu),
            onSelected: (value) {
              if (value == 'historico') {
                context.push(AppRoutes.historicoMeses);
              } else if (value == 'relatorios') {
                context.push(AppRoutes.relatorios);
              } else if (value == 'open_finance') {
                context.push(AppRoutes.openFinance);
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
              } else if (value == 'privacidade') {
                context.push(AppRoutes.privacidadeEDados);
              } else if (value == 'signout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'historico',
                child: ListTile(
                  leading: PhosphorIcon(Icones.historico),
                  title: Text('Histórico de meses'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'relatorios',
                child: ListTile(
                  leading: PhosphorIcon(Icones.relatorio),
                  title: Text('Relatórios e comparativos'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'open_finance',
                child: ListTile(
                  leading: PhosphorIcon(Icones.banco),
                  title: Text('Bancos e Open Finance'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'investimentos',
                child: ListTile(
                  leading: PhosphorIcon(Icones.patrimonio),
                  title: Text('Investimentos'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'metas',
                child: ListTile(
                  leading: PhosphorIcon(Icones.meta),
                  title: Text('Metas'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'vencimentos',
                child: ListTile(
                  leading: PhosphorIcon(Icones.vencimento),
                  title: Text('Próximos vencimentos'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'cartoes',
                child: ListTile(
                  leading: PhosphorIcon(Icones.cartao),
                  title: Text('Cartões de crédito'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'tema',
                child: ListTile(
                  leading: PhosphorIcon(Icones.tema),
                  title: Text('Aparência'),
                  dense: true,
                ),
              ),
              if (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)) ...[
                const PopupMenuItem(
                  value: 'lembretes',
                  child: ListTile(
                    leading: PhosphorIcon(Icones.notificacao),
                    title: Text('Lembretes'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'biometria',
                  child: ListTile(
                    leading: PhosphorIcon(Icones.seguranca),
                    title: Text('Segurança e biometria'),
                    dense: true,
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'privacidade',
                child: ListTile(
                  leading: PhosphorIcon(Icones.privacidade),
                  title: Text('Privacidade e dados'),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  leading: PhosphorIcon(Icones.sair),
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
            icon: const PhosphorIcon(Icones.ditar),
            label: const Text('Ditar'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'novo',
            tooltip: 'Novo lançamento',
            onPressed: () => context.push(AppRoutes.lancamentoNovo),
            child: const PhosphorIcon(Icones.adicionar),
          ),
        ],
      ),
    );
  }
}
