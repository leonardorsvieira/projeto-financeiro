import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/lancamentos/application/notificacoes_service.dart';
import 'package:meubolso/features/lancamentos/domain/lancamento.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
  });

  Lancamento lancamento(DateTime venc, {String? id}) {
    final agora = DateTime.now();
    return Lancamento(
      id: id ?? 'lan-1',
      descricao: 'Internet',
      categoria: 'Casa',
      valorCents: 9950,
      data: venc,
      vencimento: venc,
      formaPagamento: 'Credito',
      fixoMensal: false,
      serieId: null,
      itens: const [],
      createdAt: agora,
      updatedAt: agora,
    );
  }

  group('datasDeAgendamento', () {
    test('agenda T-3 e T-0 para vencimento futuro (padrão 3 dias, 09:00)', () {
      final venc = DateTime.now().add(const Duration(days: 30));
      final agendados =
          NotificacoesService.instance.datasDeAgendamento(venc, 9, 0, 3);

      expect(agendados.length, 2);

      final tx = agendados.first;
      final t0 = agendados.last;

      expect(
        DateTime(tx.quando.year, tx.quando.month, tx.quando.day),
        DateTime(venc.year, venc.month, venc.day - 3),
      );
      expect(tx.tipo, 'xd');
      expect(tx.titulo, 'Vence em 3 dias');

      expect(
        DateTime(t0.quando.year, t0.quando.month, t0.quando.day),
        DateTime(venc.year, venc.month, venc.day),
      );
      expect(t0.tipo, 'dia');
      expect(t0.titulo, 'Vence hoje');

      for (final a in agendados) {
        expect(a.quando.hour, 9);
        expect(a.quando.minute, 0);
      }
    });

    test('diasAntes=5 agenda T-5 e T-0 (horário configurável)', () {
      final venc = DateTime.now().add(const Duration(days: 20));
      final agendados =
          NotificacoesService.instance.datasDeAgendamento(venc, 15, 30, 5);

      expect(agendados, hasLength(2));
      expect(
        DateTime(
          agendados.first.quando.year,
          agendados.first.quando.month,
          agendados.first.quando.day,
        ),
        DateTime(venc.year, venc.month, venc.day - 5),
      );
      expect(agendados.first.titulo, 'Vence em 5 dias');
      for (final a in agendados) {
        expect(a.quando.hour, 15);
        expect(a.quando.minute, 30);
      }
    });

    test('diasAntes=0 agenda apenas no dia', () {
      final venc = DateTime.now().add(const Duration(days: 10));
      final agendados =
          NotificacoesService.instance.datasDeAgendamento(venc, 9, 0, 0);

      expect(agendados, hasLength(1));
      expect(agendados.single.tipo, 'dia');
      expect(agendados.single.titulo, 'Vence hoje');
    });

    test('diasAntes=1 usa singular no título', () {
      final venc = DateTime.now().add(const Duration(days: 15));
      final agendados =
          NotificacoesService.instance.datasDeAgendamento(venc, 9, 0, 1);

      expect(agendados, hasLength(2));
      expect(agendados.first.titulo, 'Vence em 1 dia');
    });

    test('diasAntes maior que distância até vencimento omite T-X', () {
      // Vencimento em 2 dias, diasAntes=5: T-X já passou, só T-0.
      final venc = DateTime.now().add(const Duration(days: 2));
      final agendados =
          NotificacoesService.instance.datasDeAgendamento(venc, 9, 0, 5);

      final tipos = agendados.map((a) => a.tipo).toSet();
      expect(tipos, isNot(contains('xd')));
      expect(tipos, contains('dia'));
    });

    test('omite disparos já passados (T-X venceu, T-0 no futuro)', () {
      // Vencimento hoje à noite: T-3 (ontem) passou, T-0 (hoje) não.
      final vencHoje = DateTime.now().add(const Duration(hours: 15));
      final agendados =
          NotificacoesService.instance.datasDeAgendamento(vencHoje, 9, 0, 3);

      final tipos = agendados.map((a) => a.tipo).toSet();
      expect(tipos, isNot(contains('xd')));
      expect(tipos, contains('dia'));
    });

    test('nenhum disparo para vencimento já encerrado', () {
      final passado = DateTime.now().subtract(const Duration(days: 2));
      final agendados =
          NotificacoesService.instance.datasDeAgendamento(passado, 9, 0, 3);

      expect(agendados, isEmpty);
    });
  });

  group('agendarLembrete', () {
    test('não agenda se não houver vencimento', () async {
      final agora = DateTime.now();
      final semVenc = Lancamento(
        id: 'lan-2',
        descricao: 'Compra',
        categoria: 'Lazer',
        valorCents: 5000,
        data: agora,
        vencimento: null,
        formaPagamento: 'Debito',
        createdAt: agora,
        updatedAt: agora,
      );

      final ok = await NotificacoesService.instance
          .agendarLembrete(semVenc, hora: 9, minuto: 0, diasAntes: 3);
      expect(ok, isTrue);
    });

    test('não agenda e retorna true para vencimento expirado', () async {
      final expirado = DateTime.now().subtract(const Duration(days: 5));
      final ok = await NotificacoesService.instance.agendarLembrete(
        lancamento(expirado),
        hora: 9,
        minuto: 0,
        diasAntes: 3,
      );
      expect(ok, isTrue);
    });
  });
}