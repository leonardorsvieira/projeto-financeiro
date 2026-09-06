import 'dart:async';

import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:meubolso/features/lancamentos/domain/lancamentos_repository.dart';

class FakeLancamentosRepository implements LancamentosRepository {
  FakeLancamentosRepository([List<Lancamento>? seed, this.createDelay])
      : _items = List.of(seed ?? const []);

  final Duration? createDelay;
  final List<Lancamento> _items;
  final _controller = StreamController<List<Lancamento>>.broadcast();
  int createCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  List<Lancamento> get items => List.unmodifiable(_items);

  void _emit() => _controller.add(List.of(_items));

  @override
  Stream<List<Lancamento>> watch() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  String _nextId() => 'id-${_items.length + 1}';

  @override
  Future<Lancamento> create({
    required String descricao,
    required int valorCents,
    required String categoria,
    required String formaPagamento,
    required DateTime data,
    DateTime? vencimento,
    String? obs,
  }) async {
    if (createDelay != null) {
      await Future<void>.delayed(createDelay!);
    }
    createCount++;
    final now = DateTime.now().toUtc();
    final lancamento = Lancamento(
      id: _nextId(),
      descricao: descricao,
      valorCents: valorCents,
      categoria: categoria,
      formaPagamento: formaPagamento,
      data: data,
      vencimento: vencimento,
      obs: obs,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(lancamento);
    _emit();
    return lancamento;
  }

  @override
  Future<Lancamento> update(
    Lancamento lancamento, {
    required String descricao,
    required int valorCents,
    required String categoria,
    required String formaPagamento,
    required DateTime data,
    DateTime? vencimento,
    String? obs,
  }) async {
    updateCount++;
    final index = _items.indexWhere((l) => l.id == lancamento.id);
    final updated = lancamento.copyWith(
      descricao: descricao,
      valorCents: valorCents,
      categoria: categoria,
      formaPagamento: formaPagamento,
      data: data,
      vencimento: () => vencimento,
      obs: () => obs,
    );
    if (index >= 0) {
      _items[index] = updated;
    }
    _emit();
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    deleteCount++;
    _items.removeWhere((l) => l.id == id);
    _emit();
  }

  @override
  Future<Lancamento?> findById(String id) async {
    for (final l in _items) {
      if (l.id == id) return l;
    }
    return null;
  }
}