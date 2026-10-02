import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/icones.dart';
import '../../application/open_finance_providers.dart';
import 'abrir_autorizacao.dart';
import '../../data/pluggy_open_finance_service.dart';

void mostrarDialogoConectarBanco(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ConectarBancoModal(),
  );
}

class _ConectarBancoModal extends ConsumerStatefulWidget {
  const _ConectarBancoModal();

  @override
  ConsumerState<_ConectarBancoModal> createState() => __ConectarBancoModalState();
}

class __ConectarBancoModalState extends ConsumerState<_ConectarBancoModal> {
  BancoDisponivelOpenFinance? _bancoSelecionado;
  String _tipoConta = 'Cartão & Conta Corrente';
  bool _conectando = false;
  final TextEditingController _itemIdCtrl = TextEditingController();
  bool _vinculandoItemId = false;

  final _tipos = [
    'Cartão & Conta Corrente',
    'Apenas Cartão de Crédito',
    'Apenas Conta Corrente & Pix',
  ];

  @override
  void dispose() {
    _itemIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _conectarMeuPluggy() async {
    final configurado = await ref.read(pluggyConfiguradoProvider.future);
    if (!mounted) return;
    if (!configurado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O Open Finance ainda não foi configurado no servidor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _conectando = true);
    try {
      final service = ref.read(pluggyOpenFinanceServiceProvider);
      final url = await service.urlConexaoMeuPluggy();
      final abriu = await abrirAutorizacaoPluggy(url);

      if (!mounted) return;
      final mensageiro = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      mensageiro.showSnackBar(
        abriu
            ? SnackBar(
                content: const Text(
                  'Pluggy aberta no navegador! Entre no meu.pluggy.ai, autorize e depois volte e toque em "Sincronizar agora".',
                ),
                backgroundColor: Colors.purple.shade700,
                duration: const Duration(seconds: 10),
              )
            : snackBarAbrirAutorizacao(url),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir conexão: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _conectando = false);
    }
  }

  Future<void> _abrirPluggyConnectGeral({int? connectorId}) async {
    final configurado = await ref.read(pluggyConfiguradoProvider.future);
    if (!mounted) return;
    if (!configurado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O Open Finance ainda não foi configurado no servidor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _conectando = true);
    try {
      final service = ref.read(pluggyOpenFinanceServiceProvider);
      await service.abrirWidgetConexao(connectorId: connectorId);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pluggy Connect aberto no navegador. Autorize sua instituição bancária e clique em "Sincronizar agora".',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 7),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir Pluggy Connect: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _conectando = false);
    }
  }

  Future<void> _vincularPorItemId() async {
    final itemId = _itemIdCtrl.text.trim();
    if (itemId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o ID do Item da Pluggy.')),
      );
      return;
    }

    final configurado = await ref.read(pluggyConfiguradoProvider.future);
    if (!mounted) return;
    if (!configurado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O Open Finance ainda não foi configurado no servidor.')),
      );
      return;
    }

    setState(() => _vinculandoItemId = true);
    try {
      final service = ref.read(pluggyOpenFinanceServiceProvider);
      final conta = await service.buscarItemPorId(itemId);

      await ref.read(contasConectadasProvider.notifier).adicionarConta(conta);

      // Executa sincronização das transações imediatamente
      await sincronizarComPluggy(ref);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${conta.nomeBanco} vinculado e sincronizado.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao vincular Item: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _vinculandoItemId = false);
    }
  }

  Future<void> _conectarManual() async {
    if (_bancoSelecionado == null) return;
    setState(() => _conectando = true);

    try {
      final service = ref.read(pluggyOpenFinanceServiceProvider);
      final contaConectada = await service.conectarBanco(
        nomeBanco: _bancoSelecionado!.nome,
        tipoConta: _tipoConta,
        corHex: _bancoSelecionado!.corHex,
      );

      await ref
          .read(contasConectadasProvider.notifier)
          .adicionarConta(contaConectada);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_bancoSelecionado!.nome} conectado via Open Finance.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao conectar banco via Open Finance.')),
      );
    } finally {
      if (mounted) setState(() => _conectando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bancos = PluggyOpenFinanceService.bancosPrincipais;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar banco (Open Finance)'),
        leading: IconButton(
          icon: const PhosphorIcon(Icones.fechar),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Destaque: Conexão direta com meu.pluggy.ai
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.purple.shade400.withValues(alpha: 0.4)
                    : Colors.purple.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple.shade700,
                        radius: 18,
                        child: const PhosphorIcon(Icones.conectarNuvem, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vincular com meu.pluggy.ai',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.purple.shade200
                                    : Colors.purple.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Conecte o Meu Bolso diretamente ao painel meu.pluggy.ai onde suas contas já estão vinculadas.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                      ),
                      onPressed: _conectando ? null : _conectarMeuPluggy,
                      icon: _conectando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const PhosphorIcon(Icones.abrirExterno, size: 18),
                      label: const Text('Autorizar no meu.pluggy.ai'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Opção: Conectar qualquer banco via Widget Pluggy Connect
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 18,
                        child: PhosphorIcon(Icones.banco, color: Colors.blue.shade800, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conectar banco via Pluggy Connect',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Abre a lista completa com mais de 230 bancos e fintechs brasileiras.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _conectando ? null : () => _abrirPluggyConnectGeral(),
                      icon: const PhosphorIcon(Icones.abrirExterno, size: 18),
                      label: const Text('Abrir catálogo de bancos Pluggy'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Opção: Vincular por Item ID direto
          ExpansionTile(
            leading: const PhosphorIcon(Icones.pin),
            title: const Text(
              'Vincular conexão por Item ID',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Já tem o identificador do Item criado na Pluggy?',
              style: TextStyle(fontSize: 12),
            ),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              TextField(
                controller: _itemIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item ID da Pluggy',
                  hintText: 'Ex: e1c385fa-7b98-4c02-...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: PhosphorIcon(Icones.codigo),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _vinculandoItemId ? null : _vincularPorItemId,
                  icon: _vinculandoItemId
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const PhosphorIcon(Icones.confirmar),
                  label: const Text('Vincular e Importar Contas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Ou selecione um Banco Rápido',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: bancos.length,
            itemBuilder: (context, index) {
              final b = bancos[index];
              final isSelected = _bancoSelecionado?.nome == b.nome;
              final Color corBanco = _parseCorHex(b.corHex);

              return Card(
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _bancoSelecionado = b),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: corBanco,
                          child: Text(
                            b.nome.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.nome,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_bancoSelecionado != null) ...[
            Text(
              'Tipo de Conta / Acesso',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              icon: const PhosphorIcon(Icones.abrirLista),
              value: _tipoConta,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _tipos
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _tipoConta = val);
              },
            ),
            const SizedBox(height: 16),
            if (_bancoSelecionado!.connectorId != null) ...[
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _conectando
                      ? null
                      : () => _abrirPluggyConnectGeral(
                            connectorId: _bancoSelecionado!.connectorId,
                          ),
                  icon: const PhosphorIcon(Icones.abrirExterno),
                  label: Text('Conectar ${_bancoSelecionado!.nome} Oficial'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _conectando ? null : _conectarManual,
                icon: const PhosphorIcon(Icones.adicionar),
                label: Text('Adicionar ${_bancoSelecionado!.nome} Manualmente'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Color _parseCorHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.purple;
    }
  }
}
