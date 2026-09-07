import 'dart:async';

import 'package:meubolso/features/investimentos/domain/rendimento_investimento.dart';
import 'package:meubolso/features/investimentos/domain/rendimentos_investimento_repository.dart';

class FakeRendimentosInvestimentoRepository
    implements RendimentosInvestimentoRepository {
  FakeRendimentosInvestimentoRepository(
      [List<RendimentoInvestimento>? seed])
      : _items = List.of(seed ?? const []);

  final List<RendimentoInvestimento> _items;
  final _controller =
      StreamController<List<RendimentoInvestimento>>.broadcast();
  int createCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  List<RendimentoInvestimento> get items => List.unmodifiable(_items);

  void _emit() => _controller.add(List.of(_items));

  @override
  Stream<List<RendimentoInvestimento>> watchTodos() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  String _nextId() => 'rend-${_items.length + 1}';

  @override
  Future<RendimentoInvestimento> create(
    RendimentoInvestimento rendimento,
  ) async {
    createCount++;
    final novo = RendimentoInvestimento(
      id: _nextId(),
      investimentoId: rendimento.investimentoId,
      tipo: rendimento.tipo,
      valorCents: rendimento.valorCents,
      data: rendimento.data,
    );
    _items.add(novo);
    _emit();
    return novo;
  }

  @override
  Future<RendimentoInvestimento> update(
    RendimentoInvestimento rendimento,
  ) async {
    updateCount++;
    final index = _items.indexWhere((r) => r.id == rendimento.id);
    final atualizado = rendimento.copyWith(id: rendimento.id);
    if (index >= 0) {
      _items[index] = atualizado;
      _emit();
    }
    return atualizado;
  }

  @override
  Future<void> delete(String id) async {
    deleteCount++;
    _items.removeWhere((r) => r.id == id);
    _emit();
  }
}