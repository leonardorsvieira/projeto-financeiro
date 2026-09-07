import 'meta.dart';

abstract class MetasRepository {
  Stream<List<Meta>> watch();

  Future<Meta> create({
    required String categoria,
    required int valorLimiteCents,
  });

  Future<Meta> update(
    Meta meta, {
    required String categoria,
    required int valorLimiteCents,
  });

  Future<void> delete(String id);
}