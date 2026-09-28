import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/open_finance_providers.dart';
import '../../data/open_finance_repository.dart';

void mostrarDialogoConfigurarPluggy(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const _ConfigurarPluggyDialog(),
  );
}

class _ConfigurarPluggyDialog extends ConsumerStatefulWidget {
  const _ConfigurarPluggyDialog();

  @override
  ConsumerState<_ConfigurarPluggyDialog> createState() =>
      __ConfigurarPluggyDialogState();
}

class __ConfigurarPluggyDialogState
    extends ConsumerState<_ConfigurarPluggyDialog> {
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _clientSecretCtrl;
  late final TextEditingController _apiKeyCtrl;

  bool _carregado = false;
  bool _testando = false;
  bool _salvando = false;
  bool _usarApiKeyDireta = false;
  String? _statusMensagem;
  bool? _statusSucesso;

  @override
  void initState() {
    super.initState();
    _clientIdCtrl = TextEditingController();
    _clientSecretCtrl = TextEditingController();
    _apiKeyCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final creds = ref.read(pluggyCredentialsProvider).value;
      if (creds != null) {
        _clientIdCtrl.text = creds.clientId ?? '';
        _clientSecretCtrl.text = creds.clientSecret ?? '';
        _apiKeyCtrl.text = creds.apiKey ?? '';
        if (creds.apiKey != null &&
            creds.apiKey!.isNotEmpty &&
            (creds.clientId == null || creds.clientId!.isEmpty)) {
          _usarApiKeyDireta = true;
        }
      }
      setState(() => _carregado = true);
    });
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  PluggyCredentials _obterCredenciaisDoFormulario() {
    if (_usarApiKeyDireta) {
      return PluggyCredentials(apiKey: _apiKeyCtrl.text.trim());
    } else {
      return PluggyCredentials(
        clientId: _clientIdCtrl.text.trim(),
        clientSecret: _clientSecretCtrl.text.trim(),
        apiKey: _apiKeyCtrl.text.trim().isNotEmpty
            ? _apiKeyCtrl.text.trim()
            : null,
      );
    }
  }

  Future<void> _testar() async {
    final creds = _obterCredenciaisDoFormulario();
    if (!creds.isPreenchido) {
      setState(() {
        _statusMensagem = 'Preencha os campos obrigatórios primeiro.';
        _statusSucesso = false;
      });
      return;
    }

    setState(() {
      _testando = true;
      _statusMensagem = null;
    });

    try {
      final service = ref.read(pluggyOpenFinanceServiceProvider);
      final ok = await service.testarConexao(creds);
      setState(() {
        _statusSucesso = ok;
        _statusMensagem = ok
            ? 'Conexão com a Pluggy estabelecida com sucesso!'
            : 'Falha ao autenticar na Pluggy. Verifique suas credenciais.';
      });
    } catch (e) {
      setState(() {
        _statusSucesso = false;
        _statusMensagem = 'Erro de comunicação: $e';
      });
    } finally {
      if (mounted) setState(() => _testando = false);
    }
  }

  Future<void> _salvarESincronizar() async {
    final creds = _obterCredenciaisDoFormulario();
    if (!creds.isPreenchido) {
      setState(() {
        _statusMensagem = 'Preencha suas credenciais para salvar.';
        _statusSucesso = false;
      });
      return;
    }

    setState(() {
      _salvando = true;
      _statusMensagem = null;
    });

    try {
      await ref.read(pluggyCredentialsProvider.notifier).salvar(creds);
      final resultado = await sincronizarComPluggy(ref);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pluggy conectado! ${resultado.contasSincronizadas} banco(s) e ${resultado.transacoesNovas} transação(ões) sincronizada(s)!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      setState(() {
        _statusSucesso = false;
        _statusMensagem = 'Erro ao sincronizar: $e';
      });
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _desvincular() async {
    await ref.read(pluggyCredentialsProvider.notifier).limpar();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciais da Pluggy removidas.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final credsExistentes = ref.watch(pluggyCredentialsProvider).value;
    final temCredenciais = credsExistentes?.isPreenchido ?? false;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple.shade700,
            radius: 16,
            child: const Icon(Icons.sync, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Vincular Conta Pluggy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Conexão com seu Pluggy',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Para sincronizar os bancos e transações que você conectou no meu.pluggy.ai, informe seu Client ID e Client Secret (obtidos gratuitamente em dashboard.pluggy.ai) ou seu Token/API Key.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _usarApiKeyDireta
                        ? 'Modo: Token / API Key'
                        : 'Modo: Client ID & Secret',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _usarApiKeyDireta = !_usarApiKeyDireta;
                        _statusMensagem = null;
                      });
                    },
                    child: Text(
                      _usarApiKeyDireta
                          ? 'Usar Client ID & Secret'
                          : 'Usar Token Direto',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (!_usarApiKeyDireta) ...[
                TextField(
                  controller: _clientIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client ID',
                    hintText: 'Ex: b1234567-89ab-cdef-...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clientSecretCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Client Secret',
                    hintText: '••••••••••••••••••••••••',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _apiKeyCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'API Key ou Token da Sessão',
                    hintText: 'Cole aqui sua API Key ou Bearer Token',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),
              ],

              if (_statusMensagem != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusSucesso == true
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusSucesso == true
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusSucesso == true
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _statusSucesso == true
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMensagem!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _statusSucesso == true
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (temCredenciais)
          TextButton(
            onPressed: _desvincular,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desvincular'),
          ),
        OutlinedButton(
          onPressed: _testando || _salvando ? null : _testar,
          child: _testando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Testar Conexão'),
        ),
        FilledButton(
          onPressed: _testando || _salvando ? null : _salvarESincronizar,
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar e Sincronizar'),
        ),
      ],
    );
  }
}
