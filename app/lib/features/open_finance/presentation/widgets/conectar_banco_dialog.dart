import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/open_finance_providers.dart';
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

  final _tipos = [
    'Cartão & Conta Corrente',
    'Apenas Cartão de Crédito',
    'Apenas Conta Corrente & Pix',
  ];

  Future<void> _conectar() async {
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
            '${_bancoSelecionado!.nome} conectado com sucesso via Open Finance!',
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
        title: const Text('Conectar Banco (Open Finance)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Conexão 100% segura e regulada pelo Banco Central. Leitura automática de extratos, cartões e Pix.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecione sua Instituição Financeira',
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
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _conectando ? null : _conectar,
                icon: _conectando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open),
                label: Text(
                  _conectando
                      ? 'Autenticando no ${_bancoSelecionado!.nome}...'
                      : 'Autorizar Open Finance no ${_bancoSelecionado!.nome}',
                ),
              ),
            ),
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
