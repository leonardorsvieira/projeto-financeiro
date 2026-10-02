---
phase: quick-261002-kvj
plan: 01
status: complete
date: 2026-10-02
commits:
  - 16f5958 feat(cartoes): cartões de cada usuário na nuvem e painel por forma de pagamento
---

# Quick 261002-kvj — Resumo

## O que mudou

- **Banco:** tabela `public.cartoes` (migration `20261002190000_cartoes.sql`),
  aplicada pelo usuário no SQL Editor com o script local
  `supabase/ativar_cartoes.local.sql` (versão registrada em
  `schema_migrations`). RLS própria + restritivas de `acesso_ativo()`; `anon`
  sem privilégio.
- **App 1.2.2+7:**
  - `SupabaseCartoesRepository` substitui o repositório local; sem cartões
    padrão (o Nubank/Inter do dono não aparecem mais para ninguém).
  - Pergunta "Quais cartões de crédito você usa?" ao abrir o app (sem cartões e
    sem resposta): sugestões dos cartões importados do banco, adicionar, "Não
    uso cartão de crédito" (grava `user_metadata.cartoes_perguntado`) e
    "Depois".
  - `formas_pagamento.dart`: formas do usuário, agrupamento do painel (Pix +
    débito em conta juntos; cada cartão; cartão não cadastrado em linha própria
    com "Toque para cadastrar"), sugestões de cartões.
  - Formulário, ditado (prompt e confirmação) usam `formasPagamentoProvider`;
    editar um importado mantém a forma ("Conta: Itaú") em vez de virar Pix.
  - Tela de cartões: sugestões do banco, dias sem padrão do dono, erros de
    gravação em snackbar.

## Verificação

- `flutter analyze`: só os avisos de depreciação antigos.
- `flutter test`: 371 passando (novos: `formas_pagamento_test`,
  `pergunta_cartoes_test`, prompt com formas do usuário).
- Banco: 9 cenários simulados com rollback — cliente cria/vê só os próprios
  cartões, não altera/apaga/cria em nome de outro, dia inválido recusado, sem
  assinatura não grava mas lê. Advisors de segurança sem achado novo.
- APK 1.2.2 (versionCode 7) assinado com a chave de produção, copiado para
  `Desktop\meubolso-release.apk`; site publicado pelo push.

## Observação

Cartões cadastrados antes ficavam só no aparelho e não migram: cada usuário
(inclusive o dono) responde a pergunta uma vez.
