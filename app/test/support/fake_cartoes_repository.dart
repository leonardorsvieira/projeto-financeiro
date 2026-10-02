import 'package:meubolso/features/cartoes/domain/cartao_credito.dart';
import 'package:meubolso/features/cartoes/domain/cartoes_repository.dart';

class FakeCartoesRepository implements CartoesRepository {
  FakeCartoesRepository({
    List<CartaoCredito>? seed,
    this.respondida = true,
  }) : _items = List.of(seed ?? const []);

  final List<CartaoCredito> _items;

  /// Padrão true: testes que não tratam da pergunta não veem o diálogo.
  bool respondida;
  int marcarCount = 0;

  List<CartaoCredito> get items => List.unmodifiable(_items);

  @override
  Future<List<CartaoCredito>> listar() async => List.of(_items);

  @override
  Future<void> salvar(CartaoCredito cartao) async {
    if (cartao.id.isEmpty) {
      _items.add(
        CartaoCredito(
          id: 'cartao-${_items.length + 1}',
          nome: cartao.nome,
          diaFechamento: cartao.diaFechamento,
          diaVencimento: cartao.diaVencimento,
          validadeMMYY: cartao.validadeMMYY,
          limiteCents: cartao.limiteCents,
          corHex: cartao.corHex,
        ),
      );
      return;
    }
    final i = _items.indexWhere((c) => c.id == cartao.id);
    if (i >= 0) _items[i] = cartao;
  }

  @override
  Future<void> excluir(String id) async =>
      _items.removeWhere((c) => c.id == id);

  @override
  Future<bool> perguntaRespondida() async => respondida;

  @override
  Future<void> marcarPerguntaRespondida() async {
    marcarCount++;
    respondida = true;
  }
}
