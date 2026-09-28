import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/open_finance_providers.dart';
import '../domain/conta_bancaria_conectada.dart';
import 'widgets/conectar_banco_dialog.dart';

class OpenFinanceScreen extends ConsumerWidget {
  const OpenFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contasAsync = ref.watch(contasConectadasProvider);
    final capturaNotifAtiva = ref.watch(capturaNotificacoesAtivaProvider);
    final fmtData = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Finance & Bancos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Conectar Novo Banco',
            onPressed: () => mostrarDialogoConectarBanco(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Status
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.account_balance, color: Colors.blue.shade900),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open Finance Brasil Ativo',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Conexão criptografada de leitura automática para Pix, cartões e contas.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
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
                            'Captura Automática (Pix & Cartões)',
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
                  const SizedBox(height: 8),
                  Text(
                    'Ao fazer uma nova compra no Cartão de Crédito ou realizar um Pix nos seus aplicativos bancários (Nubank, Inter, Itaú, Bradesco, Santander, C6, PicPay), o Meu Bolso reconhece o valor e lança automaticamente!',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Bancos Conectados
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
                label: const Text('Conectar'),
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
              child: Text('Erro ao carregar bancos conectados: $err'),
            ),
            data: (contas) {
              if (contas.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.link_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum banco conectado ainda.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Conecte seu banco pelo Open Finance para puxar extratos e faturas automaticamente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => mostrarDialogoConectarBanco(context),
                          icon: const Icon(Icons.add_link),
                          label: const Text('Conectar Meu Banco'),
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
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Importador de Extrato OFX
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
                              'Importar Extrato OFX Bancário',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Baixe o extrato .ofx do seu internet banking para importar múltiplos lançamentos.',
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
  });

  final ContaBancariaConectada conta;
  final DateFormat fmtData;
  final VoidCallback onRemover;

  Color _parseCorHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cor = _parseCorHex(conta.corHex);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor,
          child: Text(
            conta.nomeBanco.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          conta.nomeBanco,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${conta.tipoConta} ${conta.mascaraCartao ?? ""}\n'
          'Sincronizado: ${fmtData.format(conta.ultimoSync)}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          tooltip: 'Opções',
          onSelected: (val) {
            if (val == 'remover') onRemover();
          },
          itemBuilder: (ctx) => [
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
