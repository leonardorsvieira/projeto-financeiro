import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/open_finance_providers.dart';
import '../domain/conta_bancaria_conectada.dart';
import 'widgets/conectar_banco_dialog.dart';
import 'widgets/configurar_pluggy_dialog.dart';

class OpenFinanceScreen extends ConsumerStatefulWidget {
  const OpenFinanceScreen({super.key});

  @override
  ConsumerState<OpenFinanceScreen> createState() => _OpenFinanceScreenState();
}

class _OpenFinanceScreenState extends ConsumerState<OpenFinanceScreen> {
  bool _sincronizando = false;

  Future<void> _executarSincronizacao() async {
    setState(() => _sincronizando = true);
    try {
      final res = await sincronizarComPluggy(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sincronização concluída! ${res.contasSincronizadas} banco(s) e ${res.transacoesNovas} transação(ões) nova(s) importada(s).',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha na sincronização: $e'),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Configurar',
            textColor: Colors.white,
            onPressed: () => mostrarDialogoConfigurarPluggy(context),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contasAsync = ref.watch(contasConectadasProvider);
    final credsAsync = ref.watch(pluggyCredentialsProvider);
    final capturaNotifAtiva = ref.watch(capturaNotificacoesAtivaProvider);
    final fmtData = DateFormat('dd/MM/yyyy HH:mm');

    final creds = credsAsync.value;
    final pluggyConfigurado = creds?.isPreenchido ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Finance & Bancos'),
        actions: [
          IconButton(
            icon: _sincronizando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sincronizar com Pluggy',
            onPressed: _sincronizando ? null : _executarSincronizacao,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações do Pluggy',
            onPressed: () => mostrarDialogoConfigurarPluggy(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Integração Pluggy
          Card(
            color: pluggyConfigurado
                ? Colors.purple.shade50
                : Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: pluggyConfigurado
                            ? Colors.purple.shade100
                            : Colors.amber.shade100,
                        child: Icon(
                          pluggyConfigurado ? Icons.link : Icons.link_off,
                          color: pluggyConfigurado
                              ? Colors.purple.shade900
                              : Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pluggyConfigurado
                                  ? 'Integração Pluggy Ativa'
                                  : 'Vincular Conta Pluggy (meu.pluggy.ai)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: pluggyConfigurado
                                    ? Colors.purple.shade900
                                    : Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pluggyConfigurado
                                  ? 'Suas conexões bancárias e faturas são sincronizadas via API oficial Open Finance.'
                                  : 'Conecte sua conta do meu.pluggy.ai para puxar suas compras no cartão e Pix automaticamente.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (pluggyConfigurado) ...[
                        FilledButton.icon(
                          onPressed: _sincronizando ? null : _executarSincronizacao,
                          icon: _sincronizando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync, size: 18),
                          label: Text(_sincronizando
                              ? 'Sincronizando...'
                              : 'Sincronizar Agora'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => mostrarDialogoConfigurarPluggy(context),
                          child: const Text('Credenciais'),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () => mostrarDialogoConfigurarPluggy(context),
                          icon: const Icon(Icons.vpn_key_outlined, size: 18),
                          label: const Text('Vincular Conta Pluggy'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Captura Automática em Tempo Real (Leitor Push)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Captura em Tempo Real (Notificações)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: capturaNotifAtiva,
                        onChanged: (val) {
                          ref
                              .read(capturaNotificacoesAtivaProvider.notifier)
                              .setAtivo(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ao fazer uma compra no Cartão de Crédito ou enviar/receber um Pix, o Meu Bolso reconhece o valor da notificação bancária e lança instantaneamente.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Instituições Conectadas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Instituições Conectadas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => mostrarDialogoConectarBanco(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          contasAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Erro ao carregar bancos: $err'),
            ),
            data: (contas) {
              if (contas.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          pluggyConfigurado
                              ? 'Nenhum banco sincronizado ainda.'
                              : 'Vincule seu Pluggy para listar seus bancos.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pluggyConfigurado
                              ? 'Clique em "Sincronizar Agora" acima para carregar suas contas do meu.pluggy.ai.'
                              : 'Conecte suas credenciais do meu.pluggy.ai para importar suas contas e movimentações de forma automática.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: pluggyConfigurado
                              ? _executarSincronizacao
                              : () => mostrarDialogoConfigurarPluggy(context),
                          icon: Icon(pluggyConfigurado
                              ? Icons.sync
                              : Icons.vpn_key_outlined),
                          label: Text(pluggyConfigurado
                              ? 'Sincronizar Agora'
                              : 'Vincular Conta Pluggy'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final conta in contas) ...[
                    _CardContaBancaria(
                      conta: conta,
                      fmtData: fmtData,
                      onRemover: () => ref
                          .read(contasConectadasProvider.notifier)
                          .removerConta(conta.id),
                      onSincronizar: _executarSincronizacao,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Importador de Extrato OFX (Fallback)
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.file_upload_outlined, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Importar Extrato Bancário (.OFX)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Importação manual de arquivo de extrato baixado do internet banking.',
                              style: theme.textTheme.bodySmall,
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
                      onPressed: () => _mostrarDialogoOFX(context, ref),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Importar Arquivo OFX'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoOFX(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar Extrato OFX'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole o texto do arquivo .ofx baixado do seu banco:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '<OFX> ... <STMTTRN> ... </OFX>',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final texto = controller.text;
              Navigator.pop(ctx);
              if (texto.trim().isNotEmpty) {
                final qtd = await importarExtratoOFX(ref, texto);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$qtd transações importadas com sucesso!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text('Importar Transações'),
          ),
        ],
      ),
    );
  }
}

class _CardContaBancaria extends StatelessWidget {
  const _CardContaBancaria({
    required this.conta,
    required this.fmtData,
    required this.onRemover,
    required this.onSincronizar,
  });

  final ContaBancariaConectada conta;
  final DateFormat fmtData;
  final VoidCallback onRemover;
  final VoidCallback onSincronizar;

  Color _parseCorHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _parseCorHex(conta.corHex);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor,
          child: Text(
            conta.nomeBanco.isNotEmpty ? conta.nomeBanco.substring(0, 1) : 'B',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conta.nomeBanco,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: conta.status == StatusConexaoBanco.conectado
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: conta.status == StatusConexaoBanco.conectado
                      ? Colors.green.shade300
                      : Colors.amber.shade300,
                ),
              ),
              child: Text(
                conta.status.rotulo,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: conta.status == StatusConexaoBanco.conectado
                      ? Colors.green.shade900
                      : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${conta.tipoConta} ${conta.mascaraCartao ?? ""}\n'
          'Sincronizado: ${fmtData.format(conta.ultimoSync)}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          tooltip: 'Opções',
          onSelected: (val) {
            if (val == 'sync') onSincronizar();
            if (val == 'remover') onRemover();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'sync',
              child: ListTile(
                leading: Icon(Icons.sync),
                title: Text('Sincronizar'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'remover',
              child: ListTile(
                leading: Icon(Icons.link_off, color: Colors.red),
                title: Text('Desconectar'),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
