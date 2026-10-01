import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/privacidade/domain/controlador.dart';
import 'package:meubolso/features/privacidade/domain/documento_legal.dart';
import 'package:meubolso/features/privacidade/domain/textos_legais.dart';

void main() {
  group('Política de Privacidade', () {
    final texto = politicaDePrivacidade.textoCompleto;

    test('cita controlador, canal de contato e provedores reais', () {
      for (final trecho in [
        emailPrivacidade,
        cnpjControlador,
        'Supabase',
        'São Paulo',
        'Google',
        'Gemini',
        'gratuito',
        'melhorar',
        'Pluggy',
      ]) {
        expect(texto, contains(trecho), reason: trecho);
      }
    });

    test('cobre bases legais, direitos, transferência e prazos da LGPD', () {
      for (final trecho in [
        'art. 7º',
        'art. 18',
        'art. 33',
        'ANPD',
        '15 dias',
        '18 anos',
        'Marco Civil',
      ]) {
        expect(texto, contains(trecho), reason: trecho);
      }
    });

    test('a versão acompanha versaoDocumentos', () {
      expect(politicaDePrivacidade.versao, versaoDocumentos);
    });

    test('a primeira seção traz o e-mail de contato', () {
      final primeira = politicaDePrivacidade.secoes.first;
      final bloco = primeira.blocos
          .map(
            (b) => switch (b) {
              ParagrafoLegal(:final texto) => texto,
              ListaLegal(:final itens) => itens.join('\n'),
            },
          )
          .join('\n');
      expect(bloco, contains(emailPrivacidade));
    });
  });

  group('Termos de Uso', () {
    final texto = termosDeUso.textoCompleto;

    test('cita contato, consultoria, CDC, foro e licença', () {
      for (final trecho in [
        emailPrivacidade,
        'consultoria',
        'revis',
        'Código de Defesa do Consumidor',
        'domicílio',
        'engenharia reversa',
        'art. 49',
      ]) {
        expect(texto, contains(trecho), reason: trecho);
      }
    });

    test('sem cláusula de isenção total nem assunção de todos os riscos', () {
      expect(texto, isNot(contains('todos os riscos')));
      expect(texto, isNot(contains('isenta')));
    });

    test('a versão acompanha versaoDocumentos', () {
      expect(termosDeUso.versao, versaoDocumentos);
    });
  });

  test('nenhum documento deixa marcador pendente',
      () {
    for (final doc in [politicaDePrivacidade, termosDeUso]) {
      final limpo = doc.textoCompleto;
      expect(limpo, isNot(contains('[')), reason: doc.titulo);
      expect(limpo, isNot(contains('TODO')), reason: doc.titulo);
    }
  });

  test('destaques de privacidade têm 3 frases, a primeira sobre o ditado', () {
    expect(destaquesPrivacidade, hasLength(3));
    expect(destaquesPrivacidade.first, contains('Google'));
  });
}
