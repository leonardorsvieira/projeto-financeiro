import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/texto_ia.dart';
import '../../../theme/caderneta.dart';
import '../../../theme/icones.dart';
import '../../ditado/domain/ditado_repository.dart';
import '../../lancamentos/domain/lancamento_converter.dart';
import '../application/consultoria_providers.dart';
import '../data/consultoria_prompt.dart';
import '../domain/guia_investimentos.dart';
import '../domain/perfil_investidor.dart';

/// Guia de investimentos (IA): o cliente escolhe objetivo, prazo e risco e a
/// IA cruza os números dele com o mercado de hoje e os livros de
/// investimento mais lidos. Conteúdo educativo — não é recomendação.
class GuiaInvestimentosScreen extends ConsumerWidget {
  const GuiaInvestimentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guia = ref.watch(guiaInvestimentosProvider);
    final perfil = ref.watch(perfilInvestidorProvider);
    final carregando = guia.isLoading;
    final temGuia = guia.value != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Guia de investimentos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Apresentacao(),
          const SizedBox(height: 16),
          const _Perfil(),
          const SizedBox(height: 8),
          const _DadosEnviados(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: perfil.completo && !carregando
                ? () => ref.read(guiaInvestimentosProvider.notifier).gerar()
                : null,
            icon: PhosphorIcon(temGuia ? Icones.atualizar : Icones.analisar),
            label: Text(temGuia ? 'Gerar de novo' : 'Gerar meu guia'),
          ),
          if (!perfil.completo) ...[
            const SizedBox(height: 4),
            Text(
              'Escolha objetivo, prazo e risco para gerar o guia.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          switch (guia) {
            AsyncLoading() => const _Carregando(),
            AsyncError(:final error) => _Erro(erro: error),
            AsyncData(:final value) when value != null => _Resultado(guia: value),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: 16),
          Text(
            ConsultoriaPrompt.avisoFinal,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Apresentacao extends StatelessWidget {
  const _Apresentacao();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(Icones.ia, color: Caderneta.ocre(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seu guia de investimentos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A IA usa os indicadores de hoje do Banco Central e do IBGE '
              '(Selic, inflação, expectativas do mercado, dólar), cruza com os '
              'seus números — renda, gastos, reserva e patrimônio — e com as '
              'lições dos livros de investimento mais lidos, e monta um plano '
              'em etapas para o seu perfil.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'É conteúdo educativo: não é recomendação de compra ou venda '
              'de nenhum investimento.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Perfil extends ConsumerWidget {
  const _Perfil();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final perfil = ref.watch(perfilInvestidorProvider);
    final notifier = ref.read(perfilInvestidorProvider.notifier);

    Widget titulo(String texto) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(texto, style: theme.textTheme.titleSmall),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seu perfil', style: theme.textTheme.titleMedium),
        titulo('Qual é o seu principal objetivo?'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final o in ObjetivoInvestimento.values)
              ChoiceChip(
                label: Text(o.rotulo),
                selected: perfil.objetivo == o,
                onSelected: (_) => notifier.objetivo(o),
              ),
          ],
        ),
        titulo('Quando pretende usar esse dinheiro?'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final p in PrazoInvestimento.values)
              ChoiceChip(
                label: Text(p.rotulo),
                selected: perfil.prazo == p,
                onSelected: (_) => notifier.prazo(p),
              ),
          ],
        ),
        titulo('Como você lida com o risco?'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final r in ToleranciaRisco.values)
              ChoiceChip(
                label: Text(r.rotulo),
                selected: perfil.risco == r,
                onSelected: (_) => notifier.risco(r),
              ),
          ],
        ),
        if (perfil.risco != null) ...[
          const SizedBox(height: 4),
          Text(perfil.risco!.descricao, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 12),
        TextFormField(
          initialValue: perfil.observacao,
          maxLength: PerfilInvestidor.maxObservacao,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: 'Algo mais que a IA deva saber? (opcional)',
            hintText: 'Ex.: quero trocar de carro em 2028',
          ),
          onChanged: notifier.observacao,
        ),
      ],
    );
  }
}

/// Transparência: o texto exato que vai para a IA.
class _DadosEnviados extends ConsumerWidget {
  const _DadosEnviados();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dados = ref.watch(dadosConsultoriaProvider);
    return Card(
      child: ExpansionTile(
        leading: const PhosphorIcon(Icones.privacidade),
        title: const Text('Dados que a IA vai usar'),
        subtitle: dados.semDados
            ? const Text('Ainda não há lançamentos, bancos ou investimentos')
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(dados.paraPrompt(), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            'Só totais e médias: descrições de lançamentos não são enviadas. '
            'Junto vão os indicadores públicos de mercado do dia.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Consultando os indicadores de hoje e montando o seu guia… '
                'Pode levar até um minuto.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.erro});

  final Object erro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mensagem = erro is DitadoException
        ? (erro as DitadoException).mensagem
        : 'Não foi possível gerar o guia agora. Tente novamente.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          mensagem,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.guia});

  final GuiaInvestimentos guia;

  Future<void> _abrir(BuildContext context, Uri url) async {
    var abriu = false;
    try {
      abriu = await launchUrl(url, mode: LaunchMode.externalApplication);
    } on Object {
      abriu = false;
    }
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = guia.geradoEm;
    String dois(int n) => n.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextoIA(guia.texto),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Gerado em ${formatoData(g)} às '
                        '${dois(g.hour)}:${dois(g.minute)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: guia.texto),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Guia copiado.')),
                          );
                        }
                      },
                      icon: const PhosphorIcon(Icones.exportar, size: 18),
                      label: const Text('Copiar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (guia.fontes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Fontes consultadas', style: theme.textTheme.titleSmall),
          for (final f in guia.fontes)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const PhosphorIcon(Icones.abrirExterno, size: 18),
              title: Text(f.titulo, overflow: TextOverflow.ellipsis),
              onTap: () => _abrir(context, f.url),
            ),
        ],
        if (guia.buscas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Pesquisas feitas no Google', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final b in guia.buscas)
                ActionChip(
                  avatar: const PhosphorIcon(Icones.buscar, size: 16),
                  label: Text(b),
                  onPressed: () => _abrir(
                    context,
                    Uri.https('www.google.com', '/search', {'q': b}),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
