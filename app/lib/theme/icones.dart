import 'package:flutter/widgets.dart';

export 'phosphor_icon.dart';

/// Ícones do app, um nome por papel. Família Phosphor Duotone (sketch 003):
/// contorno de tinta + preenchimento suave na mesma cor.
///
/// Desenhe SEMPRE com `PhosphorIcon(Icones.<papel>)`: um `Icon` comum pinta só
/// o contorno e perde o preenchimento. Para trocar a família de ícones do app,
/// mude apenas este arquivo.
///
/// Os glifos vêm da fonte `PhosphorDuotone` do pacote `phosphor_flutter`
/// (usado só pelos assets de fonte). Os códigos abaixo são os do contorno no
/// `phosphor_icons_duotone.dart` do pacote (o nome Phosphor vai na linha acima
/// de cada papel). O pacote não compila no Flutter atual porque estende
/// `IconData`, agora `final`; por isso o `IconData` é montado aqui.
abstract final class Icones {
  static const String _f = 'PhosphorDuotone';
  static const String _p = 'phosphor_flutter';

  // Navegação, abas e menus
  // Phosphor: chartDonut
  static const resumo = IconData(0xeaa7, fontFamily: _f, fontPackage: _p);
  // Phosphor: notebook
  static const livroCaixa = IconData(0xe34f, fontFamily: _f, fontPackage: _p);
  // Phosphor: dotsThreeVertical
  static const menu = IconData(0xe209, fontFamily: _f, fontPackage: _p);
  // Phosphor: arrowLeft
  static const voltar = IconData(0xe059, fontFamily: _f, fontPackage: _p);
  // Phosphor: list
  static const menuLateral = IconData(0xe2f1, fontFamily: _f, fontPackage: _p);
  // Phosphor: caretLeft
  static const anterior = IconData(0xe139, fontFamily: _f, fontPackage: _p);
  // Phosphor: caretRight
  static const proximo = IconData(0xe13b, fontFamily: _f, fontPackage: _p);
  // Phosphor: caretDown
  static const abrirLista = IconData(0xe137, fontFamily: _f, fontPackage: _p);
  // Phosphor: calendarDot
  static const hoje = IconData(0xe7b3, fontFamily: _f, fontPackage: _p);

  // Dinheiro
  // Phosphor: trendUp
  static const sobe = IconData(0xe4af, fontFamily: _f, fontPackage: _p);
  // Phosphor: trendDown
  static const desce = IconData(0xe4ad, fontFamily: _f, fontPackage: _p);
  // Phosphor: chartLineUp
  static const rendimento = IconData(0xe157, fontFamily: _f, fontPackage: _p);
  // Phosphor: arrowCircleDown
  static const entrada = IconData(0xe029, fontFamily: _f, fontPackage: _p);
  // Phosphor: currencyCircleDollar
  static const valor = IconData(0xe54d, fontFamily: _f, fontPackage: _p);
  // Phosphor: money
  static const formaPagamento = IconData(
    0xe589,
    fontFamily: _f,
    fontPackage: _p,
  );
  // Phosphor: wallet
  static const carteira = IconData(0xe68b, fontFamily: _f, fontPackage: _p);
  // Phosphor: creditCard
  static const cartao = IconData(0xe1d3, fontFamily: _f, fontPackage: _p);
  // Phosphor: cards
  static const semCartao = IconData(0xe0f9, fontFamily: _f, fontPackage: _p);
  // Phosphor: bank
  static const banco = IconData(0xe0b5, fontFamily: _f, fontPackage: _p);
  // Phosphor: lightning
  static const pix = IconData(0xe2df, fontFamily: _f, fontPackage: _p);
  // Phosphor: lightning
  static const tempoReal = IconData(0xe2df, fontFamily: _f, fontPackage: _p);
  // Phosphor: chartPieSlice
  static const patrimonio = IconData(0xe15b, fontFamily: _f, fontPackage: _p);
  // Phosphor: chartPieSlice
  static const distribuicao = IconData(0xe15b, fontFamily: _f, fontPackage: _p);
  // Phosphor: target
  static const meta = IconData(0xe47d, fontFamily: _f, fontPackage: _p);
  // Phosphor: chartBar
  static const relatorio = IconData(0xe151, fontFamily: _f, fontPackage: _p);
  // Phosphor: ranking
  static const ranking = IconData(0xed63, fontFamily: _f, fontPackage: _p);
  // Phosphor: shapes
  static const categoria = IconData(0xec5f, fontFamily: _f, fontPackage: _p);
  // Phosphor: scales
  static const rebalancear = IconData(0xe751, fontFamily: _f, fontPackage: _p);
  // Phosphor: trophy
  static const trofeu = IconData(0xe67f, fontFamily: _f, fontPackage: _p);
  // Phosphor: slidersHorizontal
  static const ajustar = IconData(0xe435, fontFamily: _f, fontPackage: _p);

  // Datas e vencimentos
  // Phosphor: calendarDots
  static const vencimento = IconData(0xe7b5, fontFamily: _f, fontPackage: _p);
  // Phosphor: calendarBlank
  static const data = IconData(0xe10b, fontFamily: _f, fontPackage: _p);
  // Phosphor: clock
  static const horario = IconData(0xe19b, fontFamily: _f, fontPackage: _p);
  // Phosphor: calendarMinus
  static const antecedencia = IconData(0xea15, fontFamily: _f, fontPackage: _p);
  // Phosphor: calendarCheck
  static const semVencimentos = IconData(
    0xe713,
    fontFamily: _f,
    fontPackage: _p,
  );
  // Phosphor: calendarBlank
  static const periodoCurto = IconData(0xe10b, fontFamily: _f, fontPackage: _p);
  // Phosphor: calendar
  static const periodoLongo = IconData(0xe109, fontFamily: _f, fontPackage: _p);
  // Phosphor: clockCounterClockwise
  static const historico = IconData(0xe1a1, fontFamily: _f, fontPackage: _p);
  // Phosphor: repeat
  static const fixaMensal = IconData(0xe3f9, fontFamily: _f, fontPackage: _p);

  // Voz
  // Phosphor: microphone
  static const ditar = IconData(0xe327, fontFamily: _f, fontPackage: _p);
  // Phosphor: stop
  static const pararGravacao = IconData(
    0xe46d,
    fontFamily: _f,
    fontPackage: _p,
  );
  // Phosphor: hourglassHigh
  static const processando = IconData(0xe2b5, fontFamily: _f, fontPackage: _p);

  // Ações
  // Phosphor: plus
  static const adicionar = IconData(0xe3d5, fontFamily: _f, fontPackage: _p);
  // Phosphor: plusCircle
  static const aumentar = IconData(0xe3d7, fontFamily: _f, fontPackage: _p);
  // Phosphor: minusCircle
  static const remover = IconData(0xe32d, fontFamily: _f, fontPackage: _p);
  // Phosphor: x
  static const fechar = IconData(0xe4f7, fontFamily: _f, fontPackage: _p);
  // Phosphor: xCircle
  static const limpar = IconData(0xe4f9, fontFamily: _f, fontPackage: _p);
  // Phosphor: check
  static const confirmar = IconData(0xe183, fontFamily: _f, fontPackage: _p);
  // Phosphor: magnifyingGlass
  static const buscar = IconData(0xe30d, fontFamily: _f, fontPackage: _p);
  // Phosphor: arrowsClockwise
  static const sincronizar = IconData(0xe095, fontFamily: _f, fontPackage: _p);
  // Phosphor: arrowClockwise
  static const atualizar = IconData(0xe037, fontFamily: _f, fontPackage: _p);
  // Phosphor: trash
  static const excluir = IconData(0xe4a7, fontFamily: _f, fontPackage: _p);
  // Phosphor: pencilSimple
  static const editar = IconData(0xe3b5, fontFamily: _f, fontPackage: _p);
  // Phosphor: downloadSimple
  static const exportar = IconData(0xe20d, fontFamily: _f, fontPackage: _p);
  // Phosphor: fileArrowUp
  static const importar = IconData(0xe61f, fontFamily: _f, fontPackage: _p);
  // Phosphor: filePdf
  static const pdf = IconData(0xe703, fontFamily: _f, fontPackage: _p);
  // Phosphor: fileCsv
  static const planilha = IconData(0xeb1d, fontFamily: _f, fontPackage: _p);
  // Phosphor: arrowSquareOut
  static const abrirExterno = IconData(0xe5df, fontFamily: _f, fontPackage: _p);
  // Phosphor: gearSix
  static const configuracoes = IconData(
    0xe273,
    fontFamily: _f,
    fontPackage: _p,
  );
  // Phosphor: notePencil
  static const descricao = IconData(0xe34d, fontFamily: _f, fontPackage: _p);
  // Phosphor: basket
  static const item = IconData(0xe965, fontFamily: _f, fontPackage: _p);

  // Open Finance
  // Phosphor: cloudArrowUp
  static const conectarNuvem = IconData(
    0xe1af,
    fontFamily: _f,
    fontPackage: _p,
  );
  // Phosphor: cloudSlash
  static const semConexao = IconData(0xe1b7, fontFamily: _f, fontPackage: _p);
  // Phosphor: link
  static const conectado = IconData(0xe2e3, fontFamily: _f, fontPackage: _p);
  // Phosphor: linkBreak
  static const desconectar = IconData(0xe2e5, fontFamily: _f, fontPackage: _p);
  // Phosphor: key
  static const chave = IconData(0xe2d7, fontFamily: _f, fontPackage: _p);
  // Phosphor: hash
  static const codigo = IconData(0xe2a3, fontFamily: _f, fontPackage: _p);
  // Phosphor: password
  static const pin = IconData(0xe753, fontFamily: _f, fontPackage: _p);
  // Phosphor: shieldCheck
  static const verificado = IconData(0xe40f, fontFamily: _f, fontPackage: _p);

  // Conta e segurança
  // Phosphor: envelopeSimple
  static const email = IconData(0xe219, fontFamily: _f, fontPackage: _p);
  // Phosphor: envelopeSimpleOpen
  static const emailConfirmado = IconData(
    0xe21b,
    fontFamily: _f,
    fontPackage: _p,
  );
  // Phosphor: lockKey
  static const senha = IconData(0xe2ff, fontFamily: _f, fontPackage: _p);
  // Phosphor: eye
  static const verSenha = IconData(0xe221, fontFamily: _f, fontPackage: _p);
  // Phosphor: eyeSlash
  static const ocultarSenha = IconData(0xe225, fontFamily: _f, fontPackage: _p);
  // Phosphor: lockSimple
  static const seguranca = IconData(0xe309, fontFamily: _f, fontPackage: _p);
  // Phosphor: fingerprint
  static const biometria = IconData(0xe23f, fontFamily: _f, fontPackage: _p);
  // Phosphor: lockSimpleOpen
  static const desbloquear = IconData(0xe30b, fontFamily: _f, fontPackage: _p);
  // Phosphor: warning
  static const aviso = IconData(0xe4e1, fontFamily: _f, fontPackage: _p);
  // Phosphor: signOut
  static const sair = IconData(0xe42b, fontFamily: _f, fontPackage: _p);

  // Aparência, avisos e IA
  // Phosphor: palette
  static const tema = IconData(0xe6c9, fontFamily: _f, fontPackage: _p);
  // Phosphor: circleHalf
  static const temaSistema = IconData(0xe18d, fontFamily: _f, fontPackage: _p);
  // Phosphor: sun
  static const temaClaro = IconData(0xe473, fontFamily: _f, fontPackage: _p);
  // Phosphor: moon
  static const temaEscuro = IconData(0xe331, fontFamily: _f, fontPackage: _p);
  // Phosphor: bell
  static const notificacao = IconData(0xe0cf, fontFamily: _f, fontPackage: _p);
  // Phosphor: bellRinging
  static const testarNotificacao = IconData(
    0xe5e9,
    fontFamily: _f,
    fontPackage: _p,
  );
  // Phosphor: sparkle
  static const ia = IconData(0xe6a3, fontFamily: _f, fontPackage: _p);
  // Phosphor: brain
  static const analisar = IconData(0xe74f, fontFamily: _f, fontPackage: _p);

  // Categorias
  // Phosphor: forkKnife
  static const alimentacao = IconData(0xe263, fontFamily: _f, fontPackage: _p);
  // Phosphor: carProfile
  static const transporte = IconData(0xe8cd, fontFamily: _f, fontPackage: _p);
  // Phosphor: houseLine
  static const moradia = IconData(0xe2c5, fontFamily: _f, fontPackage: _p);
  // Phosphor: firstAidKit
  static const saude = IconData(0xe571, fontFamily: _f, fontPackage: _p);
  // Phosphor: filmSlate
  static const lazer = IconData(0xe8c3, fontFamily: _f, fontPackage: _p);
  // Phosphor: graduationCap
  static const educacao = IconData(0xe62d, fontFamily: _f, fontPackage: _p);
  // Phosphor: basket
  static const mercado = IconData(0xe965, fontFamily: _f, fontPackage: _p);
  // Phosphor: repeat
  static const assinaturas = IconData(0xe3f9, fontFamily: _f, fontPackage: _p);
  // Phosphor: dotsThreeCircle
  static const outros = IconData(0xe201, fontFamily: _f, fontPackage: _p);

  /// Glifo de preenchimento (camada suave) do contorno de [icone], ou `null`
  /// se [icone] não for um dos ícones acima. Todo papel de [Icones] precisa
  /// ter uma entrada em [_preenchimentos] (o teste de ícones confere).
  static IconData? preenchimentoDe(IconData icone) {
    if (icone.fontFamily != _f || icone.fontPackage != _p) return null;
    return _preenchimentos[icone.codePoint];
  }

  // Constantes, não `IconData(...)` montado em runtime: o tree-shaking de
  // ícones do build release só mantém os glifos de `IconData` const.
  static const Map<int, IconData> _preenchimentos = {
    0xeaa7: IconData(0xeaa6, fontFamily: _f, fontPackage: _p),
    0xe34f: IconData(0xe34e, fontFamily: _f, fontPackage: _p),
    0xe209: IconData(0xe208, fontFamily: _f, fontPackage: _p),
    0xe059: IconData(0xe058, fontFamily: _f, fontPackage: _p),
    0xe2f1: IconData(0xe2f0, fontFamily: _f, fontPackage: _p),
    0xe139: IconData(0xe138, fontFamily: _f, fontPackage: _p),
    0xe13b: IconData(0xe13a, fontFamily: _f, fontPackage: _p),
    0xe137: IconData(0xe136, fontFamily: _f, fontPackage: _p),
    0xe7b3: IconData(0xe7b2, fontFamily: _f, fontPackage: _p),
    0xe4af: IconData(0xe4ae, fontFamily: _f, fontPackage: _p),
    0xe4ad: IconData(0xe4ac, fontFamily: _f, fontPackage: _p),
    0xe157: IconData(0xe156, fontFamily: _f, fontPackage: _p),
    0xe029: IconData(0xe028, fontFamily: _f, fontPackage: _p),
    0xe54d: IconData(0xe54c, fontFamily: _f, fontPackage: _p),
    0xe589: IconData(0xe588, fontFamily: _f, fontPackage: _p),
    0xe68b: IconData(0xe68a, fontFamily: _f, fontPackage: _p),
    0xe1d3: IconData(0xe1d2, fontFamily: _f, fontPackage: _p),
    0xe0f9: IconData(0xe0f8, fontFamily: _f, fontPackage: _p),
    0xe0b5: IconData(0xe0b4, fontFamily: _f, fontPackage: _p),
    0xe2df: IconData(0xe2de, fontFamily: _f, fontPackage: _p),
    0xe15b: IconData(0xe15a, fontFamily: _f, fontPackage: _p),
    0xe47d: IconData(0xe47c, fontFamily: _f, fontPackage: _p),
    0xe151: IconData(0xe150, fontFamily: _f, fontPackage: _p),
    0xed63: IconData(0xed62, fontFamily: _f, fontPackage: _p),
    0xec5f: IconData(0xec5e, fontFamily: _f, fontPackage: _p),
    0xe751: IconData(0xe750, fontFamily: _f, fontPackage: _p),
    0xe67f: IconData(0xe67e, fontFamily: _f, fontPackage: _p),
    0xe435: IconData(0xe434, fontFamily: _f, fontPackage: _p),
    0xe7b5: IconData(0xe7b4, fontFamily: _f, fontPackage: _p),
    0xe10b: IconData(0xe10a, fontFamily: _f, fontPackage: _p),
    0xe19b: IconData(0xe19a, fontFamily: _f, fontPackage: _p),
    0xea15: IconData(0xea14, fontFamily: _f, fontPackage: _p),
    0xe713: IconData(0xe712, fontFamily: _f, fontPackage: _p),
    0xe109: IconData(0xe108, fontFamily: _f, fontPackage: _p),
    0xe1a1: IconData(0xe1a0, fontFamily: _f, fontPackage: _p),
    0xe3f9: IconData(0xe3f6, fontFamily: _f, fontPackage: _p),
    0xe327: IconData(0xe326, fontFamily: _f, fontPackage: _p),
    0xe46d: IconData(0xe46c, fontFamily: _f, fontPackage: _p),
    0xe2b5: IconData(0xe2b4, fontFamily: _f, fontPackage: _p),
    0xe3d5: IconData(0xe3d4, fontFamily: _f, fontPackage: _p),
    0xe3d7: IconData(0xe3d6, fontFamily: _f, fontPackage: _p),
    0xe32d: IconData(0xe32c, fontFamily: _f, fontPackage: _p),
    0xe4f7: IconData(0xe4f6, fontFamily: _f, fontPackage: _p),
    0xe4f9: IconData(0xe4f8, fontFamily: _f, fontPackage: _p),
    0xe183: IconData(0xe182, fontFamily: _f, fontPackage: _p),
    0xe30d: IconData(0xe30c, fontFamily: _f, fontPackage: _p),
    0xe095: IconData(0xe094, fontFamily: _f, fontPackage: _p),
    0xe037: IconData(0xe036, fontFamily: _f, fontPackage: _p),
    0xe4a7: IconData(0xe4a6, fontFamily: _f, fontPackage: _p),
    0xe3b5: IconData(0xe3b4, fontFamily: _f, fontPackage: _p),
    0xe20d: IconData(0xe20c, fontFamily: _f, fontPackage: _p),
    0xe61f: IconData(0xe61e, fontFamily: _f, fontPackage: _p),
    0xe703: IconData(0xe702, fontFamily: _f, fontPackage: _p),
    0xeb1d: IconData(0xeb1c, fontFamily: _f, fontPackage: _p),
    0xe5df: IconData(0xe5de, fontFamily: _f, fontPackage: _p),
    0xe273: IconData(0xe272, fontFamily: _f, fontPackage: _p),
    0xe34d: IconData(0xe34c, fontFamily: _f, fontPackage: _p),
    0xe965: IconData(0xe964, fontFamily: _f, fontPackage: _p),
    0xe1af: IconData(0xe1ae, fontFamily: _f, fontPackage: _p),
    0xe1b7: IconData(0xe1b6, fontFamily: _f, fontPackage: _p),
    0xe2e3: IconData(0xe2e2, fontFamily: _f, fontPackage: _p),
    0xe2e5: IconData(0xe2e4, fontFamily: _f, fontPackage: _p),
    0xe2d7: IconData(0xe2d6, fontFamily: _f, fontPackage: _p),
    0xe2a3: IconData(0xe2a2, fontFamily: _f, fontPackage: _p),
    0xe753: IconData(0xe752, fontFamily: _f, fontPackage: _p),
    0xe40f: IconData(0xe40c, fontFamily: _f, fontPackage: _p),
    0xe219: IconData(0xe218, fontFamily: _f, fontPackage: _p),
    0xe21b: IconData(0xe21a, fontFamily: _f, fontPackage: _p),
    0xe2ff: IconData(0xe2fe, fontFamily: _f, fontPackage: _p),
    0xe221: IconData(0xe220, fontFamily: _f, fontPackage: _p),
    0xe225: IconData(0xe224, fontFamily: _f, fontPackage: _p),
    0xe309: IconData(0xe308, fontFamily: _f, fontPackage: _p),
    0xe23f: IconData(0xe23e, fontFamily: _f, fontPackage: _p),
    0xe30b: IconData(0xe30a, fontFamily: _f, fontPackage: _p),
    0xe4e1: IconData(0xe4e0, fontFamily: _f, fontPackage: _p),
    0xe42b: IconData(0xe42a, fontFamily: _f, fontPackage: _p),
    0xe6c9: IconData(0xe6c8, fontFamily: _f, fontPackage: _p),
    0xe18d: IconData(0xe18c, fontFamily: _f, fontPackage: _p),
    0xe473: IconData(0xe472, fontFamily: _f, fontPackage: _p),
    0xe331: IconData(0xe330, fontFamily: _f, fontPackage: _p),
    0xe0cf: IconData(0xe0ce, fontFamily: _f, fontPackage: _p),
    0xe5e9: IconData(0xe5e8, fontFamily: _f, fontPackage: _p),
    0xe6a3: IconData(0xe6a2, fontFamily: _f, fontPackage: _p),
    0xe74f: IconData(0xe74e, fontFamily: _f, fontPackage: _p),
    0xe263: IconData(0xe262, fontFamily: _f, fontPackage: _p),
    0xe8cd: IconData(0xe8cc, fontFamily: _f, fontPackage: _p),
    0xe2c5: IconData(0xe2c4, fontFamily: _f, fontPackage: _p),
    0xe571: IconData(0xe570, fontFamily: _f, fontPackage: _p),
    0xe8c3: IconData(0xe8c2, fontFamily: _f, fontPackage: _p),
    0xe62d: IconData(0xe62c, fontFamily: _f, fontPackage: _p),
    0xe201: IconData(0xe200, fontFamily: _f, fontPackage: _p),
  };
}
