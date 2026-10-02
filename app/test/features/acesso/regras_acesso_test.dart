import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/acesso/domain/acesso.dart';
import 'package:meubolso/features/acesso/domain/regras_acesso.dart';

void main() {
  final hoje = DateTime(2026, 10, 1, 15, 30);

  group('e-mail', () {
    test('normalizarEmail tira espaços e põe em minúsculas', () {
      expect(
        normalizarEmail('  Ana.Souza@Exemplo.COM '),
        'ana.souza@exemplo.com',
      );
    });

    test('emailValido', () {
      expect(emailValido('ana@exemplo.com'), isTrue);
      expect(emailValido('a@b.co'), isTrue);
      expect(emailValido('ana@exemplo'), isFalse);
      expect(emailValido('ana exemplo.com'), isFalse);
      expect(emailValido(''), isFalse);
    });
  });

  group('novaValidade', () {
    test('sem prazo ou vencido conta a partir de hoje', () {
      expect(novaValidade(null, hoje), DateTime(2026, 10, 31));
      expect(novaValidade(DateTime(2026, 9, 20), hoje), DateTime(2026, 10, 31));
    });

    test('validade de hoje conta a partir de hoje', () {
      expect(novaValidade(DateTime(2026, 10, 1), hoje), DateTime(2026, 10, 31));
    });

    test('validade futura soma a partir dela', () {
      expect(novaValidade(DateTime(2026, 10, 10), hoje), DateTime(2026, 11, 9));
      expect(
        novaValidade(DateTime(2026, 10, 10), hoje, dias: 7),
        DateTime(2026, 10, 17),
      );
    });
  });

  group('validadeDeBloqueio', () {
    test('é ontem', () {
      expect(validadeDeBloqueio(hoje), DateTime(2026, 9, 30));
      expect(validadeDeBloqueio(DateTime(2026, 3, 1)), DateTime(2026, 2, 28));
    });
  });

  group('diasAte', () {
    test('conta dias de calendário', () {
      expect(diasAte(DateTime(2026, 10, 4), hoje), 3);
      expect(diasAte(DateTime(2026, 10, 1), DateTime(2026, 10, 1, 23, 59)), 0);
      expect(diasAte(DateTime(2026, 9, 30), hoje), -1);
    });
  });

  group('rotuloSituacao', () {
    test('cada faixa tem o seu rótulo', () {
      expect(rotuloSituacao(null, hoje), 'Sem prazo');
      expect(rotuloSituacao(DateTime(2026, 9, 30), hoje), 'Vencido');
      expect(rotuloSituacao(DateTime(2026, 10, 1), hoje), 'Vence hoje');
      expect(rotuloSituacao(DateTime(2026, 10, 2), hoje), 'Vence em 1 dia');
      expect(rotuloSituacao(DateTime(2026, 10, 6), hoje), 'Vence em 5 dias');
      expect(rotuloSituacao(DateTime(2026, 10, 7), hoje), 'Ativo');
    });

    test('situacaoAcesso separa as faixas', () {
      expect(situacaoAcesso(null, hoje), SituacaoAcesso.semPrazo);
      expect(
        situacaoAcesso(DateTime(2026, 9, 30), hoje),
        SituacaoAcesso.vencido,
      );
      expect(
        situacaoAcesso(DateTime(2026, 10, 6), hoje),
        SituacaoAcesso.venceEmBreve,
      );
      expect(situacaoAcesso(DateTime(2026, 10, 7), hoje), SituacaoAcesso.ativo);
    });
  });

  group('textoAvisoVencimento', () {
    StatusAcesso ativo(DateTime? ate, {bool admin = false}) =>
        StatusAcesso(ativo: true, admin: admin, validoAte: ate);

    test('de 0 a 5 dias avisa', () {
      expect(
        textoAvisoVencimento(ativo(DateTime(2026, 10, 4)), hoje),
        'Seu acesso vence em 3 dias (04/10).',
      );
      expect(
        textoAvisoVencimento(ativo(DateTime(2026, 10, 1)), hoje),
        'Seu acesso vence hoje.',
      );
      expect(
        textoAvisoVencimento(ativo(DateTime(2026, 10, 2)), hoje),
        'Seu acesso vence em 1 dia (02/10).',
      );
      expect(
        textoAvisoVencimento(ativo(DateTime(2026, 10, 6)), hoje),
        'Seu acesso vence em 5 dias (06/10).',
      );
    });

    test('fora da janela, sem prazo, vencido ou admin não avisa', () {
      expect(textoAvisoVencimento(ativo(DateTime(2026, 10, 7)), hoje), isNull);
      expect(textoAvisoVencimento(ativo(null), hoje), isNull);
      expect(
        textoAvisoVencimento(ativo(DateTime(2026, 10, 4), admin: true), hoje),
        isNull,
      );
      expect(textoAvisoVencimento(ativo(DateTime(2026, 9, 30)), hoje), isNull);
    });
  });

  group('formatos de data', () {
    test('formatarData, formatarDiaMes e dataIso', () {
      expect(formatarData(DateTime(2026, 9, 30)), '30/09/2026');
      expect(formatarDiaMes(DateTime(2026, 10, 4)), '04/10');
      expect(dataIso(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('Acesso.fromMap', () {
    test('lê a data do Postgres como data sem hora', () {
      final a = Acesso.fromMap({
        'email': 'ana@exemplo.com',
        'valido_ate': '2026-10-31',
        'observacao': 'Pix',
        'atualizado_em': '2026-10-01T12:00:00+00:00',
      });
      expect(a.email, 'ana@exemplo.com');
      expect(a.validoAte, DateTime(2026, 10, 31));
      expect(a.observacao, 'Pix');
      expect(a.atualizadoEm, isNotNull);
    });

    test('sem prazo e observação vazia viram null', () {
      final a = Acesso.fromMap({
        'email': 'ana@exemplo.com',
        'valido_ate': null,
        'observacao': '',
      });
      expect(a.validoAte, isNull);
      expect(a.observacao, isNull);
      expect(a.atualizadoEm, isNull);
    });
  });

  group('StatusAcesso', () {
    test('liberado = ativo ou admin; igualdade pelos 3 campos', () {
      expect(const StatusAcesso(ativo: true, admin: false).liberado, isTrue);
      expect(const StatusAcesso(ativo: false, admin: true).liberado, isTrue);
      expect(const StatusAcesso(ativo: false, admin: false).liberado, isFalse);
      expect(
        const StatusAcesso(ativo: true, admin: false),
        const StatusAcesso(ativo: true, admin: false),
      );
      expect(
        const StatusAcesso(ativo: true, admin: false).hashCode,
        const StatusAcesso(ativo: true, admin: false).hashCode,
      );
      expect(
        const StatusAcesso(ativo: true, admin: false),
        isNot(const StatusAcesso(ativo: false, admin: false)),
      );
    });
  });
}
