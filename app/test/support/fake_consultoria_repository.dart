import 'package:meubolso/features/consultoria/domain/guia_investimentos.dart';
import 'package:meubolso/features/consultoria/domain/indicadores_mercado.dart';
import 'package:meubolso/features/consultoria/domain/perfil_investidor.dart';

class FakeConsultoriaRepository implements ConsultoriaRepository {
  FakeConsultoriaRepository({this.guia, this.erroLancado});

  GuiaInvestimentos? guia;
  Object? erroLancado;

  int chamadas = 0;
  String? ultimosDados;
  PerfilInvestidor? ultimoPerfil;
  String? ultimosIndicadores;

  @override
  Future<GuiaInvestimentos> gerar({
    required String dadosCliente,
    required PerfilInvestidor perfil,
    String? indicadores,
  }) async {
    chamadas++;
    ultimosDados = dadosCliente;
    ultimoPerfil = perfil;
    ultimosIndicadores = indicadores;
    final erro = erroLancado;
    if (erro != null) throw erro;
    return guia ??
        GuiaInvestimentos(
          texto: '## Sua situação hoje\nGuia simulado.',
          geradoEm: DateTime(2026, 10, 3, 14, 30),
        );
  }
}

class FakeIndicadoresRepository implements IndicadoresRepository {
  FakeIndicadoresRepository([this.indicadores]);

  IndicadoresMercado? indicadores;
  int chamadas = 0;

  @override
  Future<IndicadoresMercado?> buscar() async {
    chamadas++;
    return indicadores;
  }
}
