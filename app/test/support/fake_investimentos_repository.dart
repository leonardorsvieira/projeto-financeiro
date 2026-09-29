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

  @override
  Future<int> sincronizarOpenFinance(
    List<Investimento> importados, {
    required bool removerAusentes,
  }) async {
    final ids = importados.map((i) => i.pluggyId).toSet();
    final antes = _items.length;
    if (removerAusentes) {
      _items.removeWhere(
          (i) => i.pluggyId != null && !ids.contains(i.pluggyId));
    }
    if (importados.isNotEmpty) {
      _items.removeWhere((i) => i.pluggyId == null);
    }
    var alterados = antes - _items.length;
    for (final inv in importados) {
      final index = _items.indexWhere((i) => i.pluggyId == inv.pluggyId);
      final novo = Investimento(
        id: index >= 0 ? _items[index].id : 'inv-pluggy-${inv.pluggyId}',
        classe: inv.classe,
        nome: inv.nome,
        quantidade: inv.quantidade,
        precoAtualCents: inv.precoAtualCents,
        saldoCents: inv.saldoCents,
        pluggyId: inv.pluggyId,
      );
      if (index >= 0) {
        _items[index] = novo;
      } else {
        _items.add(novo);
      }
      alterados++;
    }
    _emit();
    return alterados;
  }
}
