import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meubolso/features/acesso/application/acesso_providers.dart';
import 'package:meubolso/features/acesso/domain/acesso.dart';
import 'package:meubolso/features/auth/application/auth_controller.dart';
import 'package:meubolso/features/auth/domain/auth_state.dart';

import '../../support/fake_acesso_repository.dart';
import '../../support/fake_auth.dart';

void main() {
  group('decidirAcesso', () {
    test('sem status e sem erro: aguardando', () {
      expect(decidirAcesso(const AsyncLoading()), DecisaoAcesso.aguardando);
      expect(
        decidirAcesso(const AsyncData<StatusAcesso?>(null)),
        DecisaoAcesso.aguardando,
      );
    });

    test('conta ativa ou administradora: liberado', () {
      expect(
        decidirAcesso(const AsyncData(StatusAcesso(ativo: true, admin: false))),
        DecisaoAcesso.liberado,
      );
      expect(
        decidirAcesso(const AsyncData(StatusAcesso(ativo: false, admin: true))),
        DecisaoAcesso.liberado,
      );
    });

    test('conta inativa e não administradora: bloqueado', () {
      expect(
        decidirAcesso(
          const AsyncData(StatusAcesso(ativo: false, admin: false)),
        ),
        DecisaoAcesso.bloqueado,
      );
    });

    test('erro na primeira consulta: liberado (falha aberta)', () {
      expect(
        decidirAcesso(
          AsyncError<StatusAcesso?>(Exception('x'), StackTrace.empty),
        ),
        DecisaoAcesso.liberado,
      );
    });
  });

  group('statusAcessoProvider', () {
    ProviderContainer criar(
      FakeAuthRepository auth,
      FakeAcessoRepository acesso,
    ) {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          acessoRepositoryProvider.overrideWithValue(acesso),
        ],
      );
      addTearDown(container.dispose);
      // Riverpod 3 pausa provider sem ouvinte: mantém os dois ativos.
      container.listen(authControllerProvider, (_, _) {});
      container.listen(statusAcessoProvider, (_, _) {});
      return container;
    }

    Future<void> aguardarAuth(ProviderContainer container) =>
        container.read(authControllerProvider.future);

    test('deslogado: resolve null sem consultar o servidor', () async {
      final acesso = FakeAcessoRepository();
      final container = criar(
        FakeAuthRepository(const AuthState(AuthStatus.unauthenticated)),
        acesso,
      );
      await aguardarAuth(container);

      expect(await container.read(statusAcessoProvider.future), isNull);
      expect(acesso.statusChamadas, 0);
    });

    test('logado: consulta o servidor; invalidar consulta de novo', () async {
      const inativo = StatusAcesso(ativo: false, admin: false);
      final acesso = FakeAcessoRepository(statusAtual: inativo);
      final container = criar(
        FakeAuthRepository(
          const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
        ),
        acesso,
      );
      await aguardarAuth(container);

      expect(await container.read(statusAcessoProvider.future), inativo);
      expect(acesso.statusChamadas, 1);

      container.invalidate(statusAcessoProvider);
      await container.read(statusAcessoProvider.future);
      expect(acesso.statusChamadas, 2);
    });

    test('erro numa recarga mantém o último status conhecido', () async {
      final acesso = FakeAcessoRepository(
        statusAtual: const StatusAcesso(ativo: false, admin: false),
      );
      final container = criar(
        FakeAuthRepository(
          const AuthState(AuthStatus.authenticated, email: 'leo@meubolso.com'),
        ),
        acesso,
      );
      await aguardarAuth(container);
      await container.read(statusAcessoProvider.future);
      expect(
        decidirAcesso(container.read(statusAcessoProvider)),
        DecisaoAcesso.bloqueado,
      );

      acesso.erroStatus = Exception('sem rede');
      container.invalidate(statusAcessoProvider);
      await expectLater(
        container.read(statusAcessoProvider.future),
        throwsException,
      );

      expect(
        decidirAcesso(container.read(statusAcessoProvider)),
        DecisaoAcesso.bloqueado,
      );
    });
  });
}
