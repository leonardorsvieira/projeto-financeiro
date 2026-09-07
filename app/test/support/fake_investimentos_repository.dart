import 'dart:async';

import 'package:meubolso/features/investimentos/domain/investimento.dart';
import 'package:meubolso/features/investimentos/domain/investimentos_repository.dart';

class FakeInvestimentosRepository implements InvestimentosRepository {
  FakeInvestimentosRepository([List<Investimento>? seed])
      : _items = List.of(seed ?? const []);

  final List<Investimento> _items;
  final _controller = StreamController<List<Investimento>>.broadcast();
  int createCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  List<Investimento> get items => List.unmodifiable(_items);

  void _emit() => _controller.add(List.of(_items));

  @override
  Stream<List<Investimento>> watch() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  String _nextId() => 'inv-${_items.length + 1}';

  @override
  Future<Investimento> create(Investimento investimento) async {
    createCount++;
    final novo = Investimento(
      id: _nextId(),
      classe: investimento.classe,
      nome: investimento.nome,
      quantidade: investimento.quantidade,
      precoAtualCents: investimento.precoAtualCents,
      saldoCents: investimento.saldoCents,
    );
    _items.add(novo);
    _emit();
    return novo;
  }

  @override
  Future<Investimento> update(Investimento investimento) async {
    updateCount++;
    final index = _items.indexWhere((m) => m.id == investimento.id);
    final atualizado = Investimento(
      id: investimento.id,
      classe: investimento.classe,
      nome: investimento.nome,
      quantidade: investimento.quantidade,
      precoAtualCents: investimento.precoAtualCents,
      saldoCents: investimento.saldoCents,
    );
    if (index >= 0) {
      _items[index] = atualizado;
    }
    _emit();
    return atualizado;
  }

  @override
  Future<void> delete(String id) async {
    deleteCount++;
    _items.removeWhere((m) => m.id == id);
    _emit();
  }
}
