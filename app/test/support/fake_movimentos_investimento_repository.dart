import 'dart:async';

import 'package:meubolso/features/investimentos/domain/movimento_investimento.dart';
import 'package:meubolso/features/investimentos/domain/movimentos_investimento_repository.dart';

class FakeMovimentosInvestimentoRepository
    implements MovimentosInvestimentoRepository {
  FakeMovimentosInvestimentoRepository([List<MovimentoInvestimento>? seed])
      : _items = List.of(seed ?? const []);

  final List<MovimentoInvestimento> _items;
  final _controller = StreamController<List<MovimentoInvestimento>>.broadcast();
  int createCount = 0;
  int deleteCount = 0;

  List<MovimentoInvestimento> get items => List.unmodifiable(_items);

  List<MovimentoInvestimento> porInvestimento(String id) =>
      _items.where((m) => m.investimentoId == id).toList();

  void _emit() => _controller.add(List.of(_items));

  @override
  Stream<List<MovimentoInvestimento>> watchPorInvestimento(
    String investimentoId,
  ) {
    Future.microtask(() =>
        _controller.add(_items.where((m) => m.investimentoId == investimentoId)
            .toList()));
    return _controller.stream
        .map((all) => all
            .where((m) => m.investimentoId == investimentoId)
            .toList());
  }

  String _nextId() => 'mov-${_items.length + 1}';

  @override
  Future<MovimentoInvestimento> create(MovimentoInvestimento movimento) async {
    createCount++;
    final novo = MovimentoInvestimento(
      id: _nextId(),
      investimentoId: movimento.investimentoId,
      tipo: movimento.tipo,
      quantidade: movimento.quantidade,
      precoUnitCents: movimento.precoUnitCents,
      data: movimento.data,
    );
    _items.add(novo);
    _emit();
    return novo;
  }

  @override
  Future<void> delete(String id) async {
    deleteCount++;
    _items.removeWhere((m) => m.id == id);
    _emit();
  }
}
