---
phase: quick-261002-kvj
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - supabase/migrations/20261002190000_cartoes.sql
  - app/lib/features/cartoes/domain/cartao_credito.dart
  - app/lib/features/cartoes/domain/cartoes_repository.dart
  - app/lib/features/cartoes/domain/formas_pagamento.dart
  - app/lib/features/cartoes/data/supabase_cartoes_repository.dart
  - app/lib/features/cartoes/data/cartoes_repository.dart (removido)
  - app/lib/features/cartoes/application/cartoes_providers.dart
  - app/lib/features/cartoes/presentation/cartoes_screen.dart
  - app/lib/features/cartoes/presentation/pergunta_cartoes.dart
  - app/lib/features/dashboard/presentation/home_screen.dart
  - app/lib/features/dashboard/presentation/relatorio_cartoes_widget.dart
  - app/lib/features/lancamentos/domain/lancamento_converter.dart
  - app/lib/features/lancamentos/presentation/lancamento_form_screen.dart
  - app/lib/features/ditado/data/gemini_prompt.dart
  - app/lib/features/ditado/data/gemini_ditado_repository.dart
  - app/lib/features/ditado/application/ditado_providers.dart
  - app/lib/features/ditado/presentation/confirmacao_ditado_screen.dart
  - app/test/support/fake_cartoes_repository.dart
  - app/test/support/fake_wrappers.dart
  - app/test/features/cartoes/formas_pagamento_test.dart
  - app/test/features/ditado/data/gemini_prompt_test.dart
  - CLAUDE.md
autonomous: true
---

# Quick 261002-kvj: cartões do usuário na nuvem e painel por forma de pagamento

## Problema (visto em 2026-10-02 com clientes reais)

- `CartoesRepository.cartoesPadrao` semeava todo usuário com os cartões do dono
  (Nubank fecha 5/vence 12 e Banco Inter), em SharedPreferences — somem no
  logout e não sincronizam celular ↔ web.
- O painel "Despesas por forma de pagamento" jogava tudo que não era
  Pix/débito/dinheiro e não casava com um cartão cadastrado no PRIMEIRO cartão:
  "Conta: itau" (débito importado) R$ 66,50 aparecia como "Fatura Nubank" para um
  cliente sem Nubank; "Cartão: gold" R$ 1.326,88 de outro cliente idem.
- `formasPagamento` fixo (Pix, Cartão: Nubank, Cartão: Inter, Cartão de
  Crédito) no prompt do ditado e na confirmação do ditado. Editar um lançamento
  importado ("Conta: X") trocava a forma para Pix ao salvar.

## Decisão do usuário

Cartões na nuvem (Supabase, RLS por `user_id`). O usuário roda o SQL no SQL
Editor (o `apply_migration` do agente é bloqueado).

## Tarefas

1. **Banco:** tabela `public.cartoes` (uuid, `user_id` default `auth.uid()` com
   cascade, nome 1–40, dias 1–31, validade MM/AA, limite ≥ 0, cor #RRGGBB),
   RLS própria + restritivas de `acesso_ativo()` como lançamentos/metas, sem
   privilégio para `anon`.
2. **Repositório:** `CartoesRepository` abstrato (domain) + `SupabaseCartoesRepository`;
   sem cartões padrão. Resposta "não uso cartão" guardada em
   `user_metadata.cartoes_perguntado` (vale em todos os aparelhos).
3. **Regras puras** (`formas_pagamento.dart`): formas do usuário (Pix, Débito,
   Dinheiro, `Cartão: <nome>` de cada cartão, Cartão de Crédito); agrupamento do
   painel (Pix + débito em conta juntos; cada cartão cadastrado; cartão não
   cadastrado em linha própria; nunca no primeiro cartão); sugestões de cartões a
   partir das formas `Cartão: X` importadas.
4. **Pergunta ao cliente:** ao abrir o app logado, se não há cartões e a pergunta
   não foi respondida, diálogo "Quais cartões de crédito você usa?" com as
   sugestões do banco, "Adicionar cartão", "Não uso cartão de crédito" e "Depois".
5. **Telas:** painel usa o agrupamento; formulário, ditado (prompt e
   confirmação) usam as formas do usuário e preservam a forma atual do
   lançamento.
6. **Testes:** regras puras, prompt com formas injetadas, fake do repositório
   nos wrappers.

## Verificação

`flutter analyze` sem avisos novos; `flutter test` verde; SQL aplicado pelo
usuário e conferido (RLS/grants); APK novo.
