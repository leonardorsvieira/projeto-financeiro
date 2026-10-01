import 'package:meubolso/features/privacidade/domain/exclusao_conta_repository.dart';

class FakeExclusaoContaRepository implements ExclusaoContaRepository {
  int chamadas = 0;

  /// Se definido, `excluirConta` lança este erro (depois de contar a chamada).
  Object? erro;

  @override
  Future<void> excluirConta() async {
    chamadas++;
    if (erro != null) throw erro!;
  }
}
