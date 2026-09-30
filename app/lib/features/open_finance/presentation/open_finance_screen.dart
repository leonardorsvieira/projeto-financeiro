import '../../../theme/caderneta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/open_finance_providers.dart';
import '../domain/conta_bancaria_conectada.dart';
import 'widgets/abrir_autorizacao.dart';
import 'widgets/conectar_banco_dialog.dart';
import 'widgets/status_pluggy_dialog.dart';

/// Liga o cartão "Captura em Tempo Real" quando o leitor de notificações
/// bancárias existir de fato.
const _capturaNotificacoesImplementada = false;

class OpenFinanceScreen extends ConsumerStatefulWidget {
  const OpenFinanceScreen({super.key});

  @override
  ConsumerState<OpenFinanceScreen> createState() => _OpenFinanceScreenState();
}

class _OpenFinanceScreenState extends ConsumerState<OpenFinanceScreen> {
  bool _sincronizando = false;
  bool _abrindoMeuPluggy = false;

  Future<void> _abrirMeuPluggyConnect() async {
    final configurado = await ref.read(pluggyConfiguradoProvider.future);
    if (!mounted) return;
    if (!configurado) {
      mostrarDialogoStatusPluggy(context);
      return;
    }
    setState(() => _abrindoMeuPluggy = true);
    try {
      final service = ref.read(pluggyOpenFinanceServiceProvider);
      final resultado = await service.iniciarConexaoMeuPluggyDireta();

      // Salva ou adiciona a conta Meu Pluggy com o Item ID real gerado
      final contaMeuPluggy = ContaBancariaConectada(
        id: resultado.itemId,
        nomeBanco: 'Meu Pluggy (meu.pluggy.ai)',
        tipoConta: 'Contas & Cartões vinculados',
        corHex: '#EF294B',
        ultimoSync: DateTime.now(),
        status: StatusConexaoBanco.conectado,
        itemIdPluggy: resultado.itemId,
        capturaAutomaticaAtiva: true,
      );
      await ref
          .read(contasConectadasProvider.notifier)
          .adicionarConta(contaMeuPluggy);

      final url = Uri.parse(resultado.oauthUrl);
      final abriu = await abrirAutorizacaoPluggy(url);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        abriu
            ? SnackBar(
                content: const Text(
                  'Tela de autorização do meu.pluggy.ai aberta! Clique em "Permitir" e depois em "Sincronizar Agora".',
                ),
                backgroundColor: Colors.purple.shade700,
                duration: const Duration(seconds: 10),
                action: SnackBarAction(
                  label: 'Sincronizar',
                  textColor: Colors.white,
                  onPressed: _executarSincronizacao,
                ),
              )
            : snackBarAbrirAutorizacao(url),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir autorização: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _abrindoMeuPluggy = false);
    }
  }

  Future<void> _removerTodasConexoes() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover todas as conexões?'),
        content: const Text(
          'Todos os bancos conectados serão desconectados da Pluggy. '
          'Os lançamentos já importados continuam no app. '
          'Depois você pode conectar de novo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      final n = await ref
          .read(contasConectadasProvider.notifier)
          .removerTodas();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$n conexão(ões) removida(s).')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover conexões: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _executarSincronizacao({bool historico = false}) async {
    setState(() => _sincronizando = true);
    try {
      final res = historico
          ? await importarHistorico12Meses(ref)
          : await sincronizarComPluggy(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sincronização concluída! ${res.contasSincronizadas} banco(s) e ${res.transacoesNovas} transação(ões) nova(s) importada(s).'
            '${res.investimentosAtualizados > 0 ? ' ${res.investimentosAtualizados} investimento(s) atualizado(s) no Patrimônio.' : ''}',
          ),
          backgroundColor: Caderneta.corReceita(context),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha na sincronização: $e'),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Detalhes',
            textColor: Colors.white,
            onPressed: () => mostrarDialogoStatusPluggy(context),
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
    final capturaNotifAtiva = ref.watch(capturaNotificacoesAtivaProvider);
    final fmtData = DateFormat('dd/MM/yyyy HH:mm');
    final pluggyConfigurado =
        ref.watch(pluggyConfiguradoProvider).value ?? false;

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
            tooltip: 'Status do Open Finance',
            onPressed: () => mostrarDialogoStatusPluggy(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Integração Pluggy
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: pluggyConfigurado
                    ? (theme.brightness == Brightness.dark
                          ? Colors.purple.shade400.withValues(alpha: 0.4)
                          : Colors.purple.shade200)
                    : (theme.brightness == Brightness.dark
                          ? Colors.amber.shade400.withValues(alpha: 0.4)
                          : Caderneta.ocre(context)),
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
                        backgroundColor: pluggyConfigurado
                            ? Colors.purple.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.2),
                        child: Icon(
                          pluggyConfigurado ? Icons.link : Icons.link_off,
                          color: pluggyConfigurado
                              ? (theme.brightness == Brightness.dark
                                    ? Colors.purple.shade200
                                    : Colors.purple.shade900)
                              : (theme.brightness == Brightness.dark
                                    ? Colors.amber.shade200
                                    : Caderneta.ocre(context)),
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
                                  : 'Open Finance indisponível',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: pluggyConfigurado
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.purple.shade200
                                          : Colors.purple.shade900)
                                    : (theme.brightness == Brightness.dark
                                          ? Colors.amber.shade200
                                          : Caderneta.ocre(context)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pluggyConfigurado
                                  ? 'Conexão segura com a Pluggy: só você vê os seus bancos. Vincule o meu.pluggy.ai ou outros bancos para sincronizar compras e Pix automaticamente.'
                                  : 'O servidor ainda não está configurado para o Open Finance. Toque em Status para verificar de novo.',
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (pluggyConfigurado) ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                          ),
                          onPressed: _abrindoMeuPluggy
                              ? null
                              : _abrirMeuPluggyConnect,
                          icon: _abrindoMeuPluggy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_sync, size: 18),
                          label: const Text('Conectar meu.pluggy.ai'),
                        ),
                        FilledButton.icon(
                          onPressed: _sincronizando
                              ? null
                              : _executarSincronizacao,
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
                          label: Text(
                            _sincronizando
                                ? 'Sincronizando...'
                                : 'Sincronizar Agora',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _sincronizando
                              ? null
                              : () => _executarSincronizacao(historico: true),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Importar últimos 12 meses'),
                        ),
                        OutlinedButton(
                          onPressed: () => mostrarDialogoStatusPluggy(context),
                          child: const Text('Status'),
                        ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () => mostrarDialogoStatusPluggy(context),
                          icon: const Icon(Icons.vpn_key_outlined, size: 18),
                          label: const Text('Verificar Open Finance'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Captura Automática em Tempo Real (Leitor Push). Escondida:
          // o leitor de notificações nunca foi ligado (não há serviço
          // Android nem chamada a processarNotificacaoBancariaEmTempoReal).
          if (_capturaNotificacoesImplementada) ...[
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
          ],

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
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) =>
                Center(child: Text('Erro ao carregar bancos: $err')),
            data: (contas) {
              if (contas.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pluggyConfigurado
                              ? 'Nenhuma instituição sincronizada ainda.'
                              : 'Open Finance indisponível no momento.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pluggyConfigurado
                              ? 'Clique no botão abaixo para autorizar o meu.pluggy.ai ou conectar qualquer banco diretamente via Open Finance.'
                              : 'Tente novamente mais tarde.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (pluggyConfigurado) ...[
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.purple.shade700,
                                ),
                                onPressed: _abrindoMeuPluggy
                                    ? null
                                    : _abrirMeuPluggyConnect,
                                icon: const Icon(Icons.cloud_sync, size: 18),
                                label: const Text('Conectar meu.pluggy.ai'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    mostrarDialogoConectarBanco(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Adicionar Bancos / Item ID'),
                              ),
                            ] else ...[
                              FilledButton.icon(
                                onPressed: () =>
                                    mostrarDialogoStatusPluggy(context),
                                icon: const Icon(Icons.vpn_key_outlined),
                                label: const Text('Verificar Open Finance'),
                              ),
                            ],
                          ],
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: _removerTodasConexoes,
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('Remover todas as conexões'),
                    ),
                  ),
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
                      backgroundColor: Caderneta.corReceita(context),
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
                    ? Caderneta.corReceitaFundo(context)
                    : Caderneta.ocre(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: conta.status == StatusConexaoBanco.conectado
                      ? Caderneta.corReceita(context).withValues(alpha: 0.4)
                      : Caderneta.ocre(context).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                conta.status.rotulo,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: conta.status == StatusConexaoBanco.conectado
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Caderneta.corReceita(context)
                            : Caderneta.corReceita(context))
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Caderneta.ocre(context)
                            : Caderneta.ocre(context)),
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
