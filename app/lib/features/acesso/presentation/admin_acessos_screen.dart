import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../application/acesso_providers.dart';
import '../domain/acesso.dart';
import '../domain/acesso_repository.dart';
import '../domain/regras_acesso.dart';
import 'acesso_dialog.dart';

/// Acessos cujo e-mail contém [termo] (sem diferenciar maiúsculas). Termo
/// vazio devolve a lista inteira.
List<Acesso> filtrarAcessos(List<Acesso> lista, String termo) {
  final t = termo.trim().toLowerCase();
  if (t.isEmpty) return lista;
  return [
    for (final a in lista)
      if (a.email.toLowerCase().contains(t)) a,
  ];
}

enum _Acao { editar, renovar, bloquear, remover }

/// "Clientes e acessos": só o administrador chega aqui (o menu esconde o item
/// e o router manda os demais para a home). O RLS é quem impede a escrita de
/// quem não é administrador.
class AdminAcessosScreen extends ConsumerStatefulWidget {
  const AdminAcessosScreen({super.key});

  @override
  ConsumerState<AdminAcessosScreen> createState() => _AdminAcessosScreenState();
}

class _AdminAcessosScreenState extends ConsumerState<AdminAcessosScreen> {
  static const _falhaGenerica =
      'Não foi possível salvar agora. Verifique a conexão e tente novamente.';

  final _busca = TextEditingController();
  String _termo = '';

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  DateTime get _hoje => ref.read(acessoRelogioProvider)();

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Roda a [acao] no servidor, recarrega a lista e avisa o resultado.
  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      if (!mounted) return;
      ref.invalidate(acessosAdminProvider);
      _aviso(sucesso);
    } on AcessoException catch (e) {
      if (mounted) _aviso(e.mensagem);
    } catch (_) {
      if (mounted) _aviso(_falhaGenerica);
    }
  }

  Future<void> _novoOuEditar(Acesso? existente) async {
    final dados = await mostrarDialogoAcesso(
      context,
      existente: existente,
      hoje: _hoje,
    );
    if (dados == null || !mounted) return;
    await _executar(
      () => ref
          .read(acessoRepositoryProvider)
          .salvar(dados.email, dados.validoAte, dados.observacao),
      'Acesso salvo.',
    );
  }

  Future<bool> _confirmar({
    required String titulo,
    required String texto,
    required String confirmar,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmar),
          ),
        ],
      ),
    );
    return ok == true && mounted;
  }

  Future<void> _acao(_Acao acao, Acesso a) async {
    final repo = ref.read(acessoRepositoryProvider);
    switch (acao) {
      case _Acao.editar:
        await _novoOuEditar(a);
      case _Acao.renovar:
        final ate = novaValidade(a.validoAte, _hoje);
        await _executar(
          () => repo.renovar(a.email),
          'Acesso renovado até ${formatarData(ate)}.',
        );
      case _Acao.bloquear:
        if (!await _confirmar(
          titulo: 'Bloquear acesso?',
          texto:
              '${a.email} perde o acesso hoje. A pessoa continua podendo ver, '
              'exportar e excluir os próprios dados.',
          confirmar: 'Bloquear',
        )) {
          return;
        }
        await _executar(() => repo.bloquear(a.email), 'Acesso bloqueado.');
      case _Acao.remover:
        if (!await _confirmar(
          titulo: 'Remover acesso?',
          texto:
              '${a.email} sai da lista e perde o acesso. Os dados da conta '
              'não são apagados.',
          confirmar: 'Remover',
        )) {
          return;
        }
        await _executar(() => repo.remover(a.email), 'Acesso removido.');
    }
  }

  Future<void> _recarregar() async {
    ref.invalidate(acessosAdminProvider);
    try {
      await ref.read(acessosAdminProvider.future);
    } catch (_) {
      // A própria tela mostra o erro e o botão de tentar de novo.
    }
  }

  Color _corDaSituacao(SituacaoAcesso situacao) => switch (situacao) {
    SituacaoAcesso.semPrazo => CadernetaCores.of(context).apagado,
    SituacaoAcesso.ativo => Caderneta.corReceita(context),
    SituacaoAcesso.venceEmBreve => Caderneta.ocre(context),
    SituacaoAcesso.vencido => Theme.of(context).colorScheme.error,
  };

  Widget _linha(Acesso a, DateTime hoje) {
    final cores = CadernetaCores.of(context);
    final cor = _corDaSituacao(situacaoAcesso(a.validoAte, hoje));
    final validade = a.validoAte == null
        ? 'Sem prazo'
        : 'Válido até ${formatarData(a.validoAte!)}';
    return ListTile(
      title: Text(a.email),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(validade),
          if (a.observacao != null)
            Text(
              a.observacao!,
              style: CadernetaTexto.corpo(size: 13, cor: cores.apagado),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(rotuloSituacao(a.validoAte, hoje)),
            labelStyle: TextStyle(color: cor, fontWeight: FontWeight.w600),
            backgroundColor: cor.withValues(alpha: 0.12),
            side: BorderSide(color: cor.withValues(alpha: 0.4)),
            visualDensity: VisualDensity.compact,
          ),
          PopupMenuButton<_Acao>(
            tooltip: 'Ações de ${a.email}',
            icon: const PhosphorIcon(Icones.menu),
            onSelected: (acao) => _acao(acao, a),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _Acao.editar,
                child: ListTile(
                  leading: PhosphorIcon(Icones.editar),
                  title: Text('Editar'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: _Acao.renovar,
                child: ListTile(
                  leading: PhosphorIcon(Icones.fixaMensal),
                  title: Text('Renovar +30 dias'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: _Acao.bloquear,
                child: ListTile(
                  leading: PhosphorIcon(Icones.seguranca),
                  title: Text('Bloquear'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: _Acao.remover,
                child: ListTile(
                  leading: PhosphorIcon(Icones.excluir),
                  title: Text('Remover'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _conteudo(AsyncValue<List<Acesso>> lista, DateTime hoje) {
    final cores = CadernetaCores.of(context);
    final textoApagado = CadernetaTexto.corpo(size: 15, cor: cores.apagado);

    // Durante uma recarga mantém a lista anterior na tela.
    final dados = lista.value;
    if (dados == null) {
      if (lista.hasError) {
        return [
          const SizedBox(height: 32),
          Text(
            'Não foi possível carregar a lista.',
            textAlign: TextAlign.center,
            style: textoApagado,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => ref.invalidate(acessosAdminProvider),
              child: const Text('Tentar de novo'),
            ),
          ),
        ];
      }
      return const [
        SizedBox(height: 48),
        Center(child: CircularProgressIndicator()),
      ];
    }

    if (dados.isEmpty) {
      return [
        const SizedBox(height: 32),
        Text(
          'Nenhum acesso cadastrado ainda.',
          textAlign: TextAlign.center,
          style: textoApagado,
        ),
      ];
    }
    final filtrados = filtrarAcessos(dados, _termo);
    if (filtrados.isEmpty) {
      return [
        const SizedBox(height: 32),
        Text(
          'Nenhum e-mail encontrado.',
          textAlign: TextAlign.center,
          style: textoApagado,
        ),
      ];
    }
    return [for (final a in filtrados) _linha(a, hoje)];
  }

  @override
  Widget build(BuildContext context) {
    final cores = CadernetaCores.of(context);
    final hoje = ref.watch(acessoRelogioProvider)();
    final lista = ref.watch(acessosAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes e acessos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _novoOuEditar(null),
        icon: const PhosphorIcon(Icones.adicionar),
        label: const Text('Novo acesso'),
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              'Quem está nesta lista, com a validade em dia, usa o Meu Bolso. '
              'Administradores não precisam estar aqui.',
              style: CadernetaTexto.corpo(
                size: 14,
                cor: cores.apagado,
              ).copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _busca,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: PhosphorIcon(Icones.buscar),
                hintText: 'Buscar por e-mail',
              ),
              onChanged: (v) => setState(() => _termo = v),
            ),
            const SizedBox(height: 8),
            ..._conteudo(lista, hoje),
          ],
        ),
      ),
    );
  }
}
