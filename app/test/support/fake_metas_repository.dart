import 'dart:async';

import 'package:meubolso/features/metas/domain/meta.dart';
import 'package:meubolso/features/metas/domain/metas_repository.dart';

class FakeMetasRepository implements MetasRepository {
  FakeMetasRepository([List<Meta>? seed]) : _items = List.of(seed ?? const []);

  final List<Meta> _items;
  final _controller = StreamController<List<Meta>>.broadcast();
  int createCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  List<Meta> get items => List.unmodifiable(_items);

  void _emit() => _controller.add(List.of(_items));

  @override
  Stream<List<Meta>> watch() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  String _nextId() => 'meta-${_items.length + 1}';

  @override
  Future<Meta> create({
    required String categoria,
    required int valorLimiteCents,
  }) async {
    createCount++;
    final meta = Meta(
      id: _nextId(),
      categoria: categoria,
      valorLimiteCents: valorLimiteCents,
    );
    _items.add(meta);
    _emit();
    return meta;
  }

  @override
  Future<Meta> update(
    Meta meta, {
    required String categoria,
    required int valorLimiteCents,
  }) async {
    updateCount++;
    final index = _items.indexWhere((m) => m.id == meta.id);
    final updated = Meta(
      id: meta.id,
      categoria: categoria,
      valorLimiteCents: valorLimiteCents,
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
    _items.removeWhere((m) => m.id == id);
    _emit();
  }
}