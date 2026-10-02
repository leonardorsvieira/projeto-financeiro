import '../../lancamentos/domain/lancamento.dart';
import 'cartao_credito.dart';

/// Regras de forma de pagamento que dependem dos cartões de cada usuário.
///
/// Os lançamentos guardam a forma como texto: "Pix", "Débito", "Cartão: Nubank"
/// (cartão específico), "Cartão de Crédito" (genérico) e, nos importados do Open
/// Finance, "Conta: Itaú" (saída da conta) ou `Cartão: <nome da conta>`.

const prefixoCartao = 'Cartão: ';
const formaCartaoGenerico = 'Cartão de Crédito';

/// Formas sempre disponíveis, que não dependem de cartão cadastrado.
const formasPagamentoBase = ['Pix', 'Débito', 'Dinheiro'];

/// Formas oferecidas ao usuário: as fixas, um "Cartão: nome" por cartão
/// cadastrado e o cartão genérico.
List<String> formasPagamentoDoUsuario(List<CartaoCredito> cartoes) => [
  ...formasPagamentoBase,
  for (final c in cartoes) '$prefixoCartao${c.nome}',
  formaCartaoGenerico,
];

/// As [formas] do usuário mais a [atual], se ela não estiver na lista — para
/// que editar um lançamento (ex.: importado como "Conta: Itaú") não troque a
/// forma dele sem o usuário pedir.
List<String> formasComAtual(List<String> formas, String? atual) {
  if (atual == null || atual.trim().isEmpty || formas.contains(atual)) {
    return formas;
  }
  return [...formas, atual];
}

/// Nome do cartão em "Cartão: Nubank"; null se a forma não for de um cartão
/// específico.
String? nomeCartaoDaForma(String forma) {
  final f = forma.trim();
  if (!f.toLowerCase().startsWith(prefixoCartao.toLowerCase())) return null;
  final nome = f.substring(prefixoCartao.length).trim();
  return nome.isEmpty ? null : nome;
}

String _normalizar(String s) => s.trim().toLowerCase();

/// Pagamento que sai direto da conta: Pix, débito, dinheiro e as saídas de
/// conta importadas do banco ("Conta: Itaú").
bool ehPagamentoEmConta(String forma) {
  final f = _normalizar(forma);
  return f.contains('pix') ||
      f.contains('débito') ||
      f.contains('debito') ||
      f.contains('dinheiro') ||
      f.startsWith('conta:');
}

/// Cartão cadastrado da forma "Cartão: X": primeiro o de mesmo nome; depois um
/// cujo nome contenha o outro ("Cartão: Inter" ↔ "Banco Inter").
CartaoCredito? cartaoDaForma(String forma, List<CartaoCredito> cartoes) {
  final nome = nomeCartaoDaForma(forma);
  if (nome == null) return null;
  final n = _normalizar(nome);
  for (final c in cartoes) {
    if (_normalizar(c.nome) == n) return c;
  }
  for (final c in cartoes) {
    final cn = _normalizar(c.nome);
    if (cn.isNotEmpty && (cn.contains(n) || n.contains(cn))) return c;
  }
  return null;
}

enum TipoGrupoForma { conta, cartao, outras }

/// Uma fatia do painel "Despesas por forma de pagamento".
class GrupoFormaPagamento {
  const GrupoFormaPagamento({
    required this.titulo,
    required this.tipo,
    required this.totalCents,
    this.cartao,
    this.nomeNaoCadastrado,
  });

  final String titulo;
  final TipoGrupoForma tipo;
  final int totalCents;

  /// Cartão cadastrado do grupo.
  final CartaoCredito? cartao;

  /// Nome de "Cartão: X" que não corresponde a nenhum cartão cadastrado.
  final String? nomeNaoCadastrado;
}

/// Soma as [despesas] por forma de pagamento: Pix e débito em conta juntos,
/// cada cartão cadastrado, cada cartão não cadastrado em linha própria e o
/// resto em "Outras formas". Nunca atribui um gasto a um cartão que não é o
/// dele. Ordenado do maior para o menor total; grupos zerados ficam de fora.
List<GrupoFormaPagamento> agruparPorFormaPagamento(
  Iterable<Lancamento> despesas,
  List<CartaoCredito> cartoes,
) {
  final totais = <String, int>{};
  final titulos = <String, String>{};
  final tipos = <String, TipoGrupoForma>{};
  final cartaoDoGrupo = <String, CartaoCredito>{};
  final nomeDoGrupo = <String, String>{};

  void somar(String chave, String titulo, TipoGrupoForma tipo, int cents) {
    totais[chave] = (totais[chave] ?? 0) + cents;
    titulos.putIfAbsent(chave, () => titulo);
    tipos.putIfAbsent(chave, () => tipo);
  }

  for (final d in despesas) {
    final forma = d.formaPagamento;
    if (ehPagamentoEmConta(forma)) {
      somar('conta', 'Pix e débito', TipoGrupoForma.conta, d.valorCents);
      continue;
    }
    final nome = nomeCartaoDaForma(forma);
    if (nome != null) {
      final cartao = cartaoDaForma(forma, cartoes);
      if (cartao != null) {
        final chave = 'cartao:${cartao.id}';
        cartaoDoGrupo[chave] = cartao;
        somar(
          chave,
          'Cartão ${cartao.nome}',
          TipoGrupoForma.cartao,
          d.valorCents,
        );
      } else {
        final chave = 'nome:${_normalizar(nome)}';
        nomeDoGrupo.putIfAbsent(chave, () => nome);
        somar(chave, 'Cartão $nome', TipoGrupoForma.cartao, d.valorCents);
      }
      continue;
    }
    if (_normalizar(forma) == _normalizar(formaCartaoGenerico)) {
      somar('generico', 'Cartão sem nome', TipoGrupoForma.cartao, d.valorCents);
      continue;
    }
    somar('outras', 'Outras formas', TipoGrupoForma.outras, d.valorCents);
  }

  final grupos = [
    for (final chave in totais.keys)
      if (totais[chave]! > 0)
        GrupoFormaPagamento(
          titulo: titulos[chave]!,
          tipo: tipos[chave]!,
          totalCents: totais[chave]!,
          cartao: cartaoDoGrupo[chave],
          nomeNaoCadastrado: nomeDoGrupo[chave],
        ),
  ]..sort((a, b) => b.totalCents.compareTo(a.totalCents));
  return grupos;
}

/// Nomes de cartões vindos do banco (lançamentos importados do Open Finance
/// como "Cartão: X") que ainda não estão cadastrados, do mais usado para o
/// menos usado.
List<String> sugestoesDeCartoes(
  Iterable<Lancamento> lancamentos,
  List<CartaoCredito> cartoes,
) {
  final contagem = <String, int>{};
  final grafia = <String, String>{};
  for (final l in lancamentos) {
    if (!(l.obs?.startsWith('pluggy_id:') ?? false)) continue;
    final nome = nomeCartaoDaForma(l.formaPagamento);
    if (nome == null || cartaoDaForma(l.formaPagamento, cartoes) != null) {
      continue;
    }
    final chave = _normalizar(nome);
    grafia.putIfAbsent(chave, () => nome);
    contagem[chave] = (contagem[chave] ?? 0) + 1;
  }
  final chaves = contagem.keys.toList()
    ..sort((a, b) => contagem[b]!.compareTo(contagem[a]!));
  return [for (final c in chaves) grafia[c]!];
}
