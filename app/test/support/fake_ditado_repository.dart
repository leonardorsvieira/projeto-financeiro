import 'package:meubolso/features/ditado/domain/ditado_repository.dart';
import 'package:meubolso/features/ditado/domain/rascunho_lancamento.dart';

class FakeDitadoRepository implements DitadoRepository {
  FakeDitadoRepository({
    this.rascunho,
    this.correcao,
    this.erroLancado,
    this.delayReconhecer,
  });

  RascunhoLancamento? rascunho;
  String? correcao;
  Object? erroLancado;
  Duration? delayReconhecer;

  int reconhecerCount = 0;
  int corrigirCount = 0;
  LancamentoAudio? ultimoAudio;
  CampoDitado? ultimoCampo;
  String? ultimoTexto;

  @override
  Future<RascunhoLancamento> reconhecer(LancamentoAudio audio) async {
    reconhecerCount++;
    ultimoAudio = audio;
    final atraso = delayReconhecer;
    if (atraso != null) await Future<void>.delayed(atraso);
    final erro = erroLancado;
    if (erro != null) throw erro;
    return rascunho ?? RascunhoLancamento();
  }

  @override
  Future<String?> corrigirCampo(
    CampoDitado campo, {
    LancamentoAudio? audio,
    String? texto,
    RascunhoLancamento? rascunhoAtual,
  }) async {
    corrigirCount++;
    ultimoCampo = campo;
    ultimoAudio = audio;
    ultimoTexto = texto;
    final erro = erroLancado;
    if (erro != null) throw erro;
    return correcao;
  }
}