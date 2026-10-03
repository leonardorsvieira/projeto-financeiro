import 'package:meubolso/features/consultoria/domain/guia_investimentos.dart';
import 'package:meubolso/features/consultoria/domain/perfil_investidor.dart';

class FakeGuiasRepository implements GuiasRepository {
  FakeGuiasRepository({this.perfil, this.guia, this.erroAoSalvar});

  PerfilInvestidor? perfil;
  GuiaInvestimentos? guia;
  Object? erroAoSalvar;

  int salvamentosDePerfil = 0;
  int salvamentosDeGuia = 0;

  @override
  Future<GuiaSalvo> carregar() async => GuiaSalvo(perfil: perfil, guia: guia);

  @override
  Future<void> salvarPerfil(PerfilInvestidor perfil) async {
    final erro = erroAoSalvar;
    if (erro != null) throw erro;
    salvamentosDePerfil++;
    this.perfil = perfil;
  }

  @override
  Future<void> salvarGuia(GuiaInvestimentos guia) async {
    final erro = erroAoSalvar;
    if (erro != null) throw erro;
    salvamentosDeGuia++;
    this.guia = guia;
  }
}
