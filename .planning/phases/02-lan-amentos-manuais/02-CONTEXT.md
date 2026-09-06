# Phase 02 — Context & Decisions

**Phase:** 2 — Lançamentos Manuais | **Status:** Planning | **Date:** 2026-09-06

## Objectives (from ROADMAP)

- Registrar despesas manualmente com todos os campos (DSP-01), editar (DSP-02), excluir (DSP-03).
- Dados sincronizados na nuvem via Supabase, isolados por usuário com RLS (PLAT-04).

## Constraints / Context Carried From Phase 1

- Flutter 3.47.2, Riverpod 3, go_router, Supabase projeto `meubolso` (sa-east-1, ref `tkfhthotspehsgvmpsjm`), auth e-mail sem confirmação.
- Deploy web no GitHub Pages (workflow deploy-pages, base-href `/projeto-financeiro/`, `--dart-define` via repo secrets).
- Validação **web-first** (Android toolchain adiada por decisão do usuário; já registrada como pendência).
- Padrões: feature-first, `flutter_riverpod` + `AsyncValue`, `.env` fora do git, testes com fakes sem rede.

## Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D-14 | Tabela `lancamentos` com `id uuid pk default gen_random_uuid()`, `user_id uuid NOT NULL default auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE`, `descricao text NOT NULL`, `valor_cents bigint NOT NULL CHECK (valor_cents > 0)`, `categoria text NOT NULL`, `forma_pagamento text NOT NULL`, `data date NOT NULL DEFAULT CURRENT_DATE`, `vencimento date NULL`, `obs text NULL`, `created_at/updated_at timestamptz NOT NULL DEFAULT now()`, índice `(user_id, data DESC)` | Modelo enxuto p/ MVP; dono inferido do JWT (cliente nunca envia user_id) |
| D-15 | RLS habilitada; políticas por comando: SELECT/UPDATE/DELETE `USING auth.uid() = user_id`; INSERT `WITH CHECK auth.uid() = user_id`; nenhuma política para anon | Área de dados sensíveis (PLAT-04); `auth.uid()` do JWT como fronteira de autorização |
| D-16 | Valores monetários em **centavos (bigint)**, nunca `double` no armazenamento; formatação BRL só na UI com `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` | Evita arredondamento/erro de ponto flutuante; exibição determinística |
| D-17 | Migrations versionadas em `supabase/migrations/*.sql`; aplicação no remoto via `supabase db push` (fallback Management API `POST /v1/projects/{ref}/database/query`; CLI pode exigir token de acesso se não estiver persistido) | Schema entrando no git (infra como código); escolha documentada no summary de execução |
| D-18 | Camada Dart: `Lancamento` (model imutável) + `LancamentosRepository` (abstract) com `stream()` real-time (`.from('lancamentos').stream(primaryKey: ['id']).order('data', desc)`), `create/update/delete`; providers Riverpod (`StreamProvider` para lista + repo provider) | Sync entre dispositivos "de graça"; interface p/ fakes nos testes |
| D-19 | Telas (UI-SPEC): **S5 Lista** (home vira lista; FAB "+"; tap edita; menu ⋮ → Excluir com confirmação; pull-to-refresh; empty state) e **S6 Formulário** (descricao, valor BRL, categoria dropdown, forma dropdown, data picker default hoje, vencimento opcional, obs; erros inline; Salvar/Cancelar). Categorias fixas do app: Alimentação, Transporte, Moradia, Saúde, Lazer, Educação, Mercado, Assinaturas, Outros. Formas: Pix, Cartão de Crédito, Cartão de Débito, Dinheiro, Boleto, Transferência, Outro | Orvalho padrão Material 3 (tokens da Fase 1); fluxo simples e direto |
| D-20 | Realtime da tabela habilitado (publicação `supabase_realtime`) p/ sync entre dispositivos no mesmo login; `stream()` no cliente com RLS ativa (usuário só vê as próprias linhas) | "Sincronizadas entre dispositivos" do ROADMAP sem backend extra |
| D-21 | `intl` adicionado ao pubspec p/ formatação BRL/datas; fuso/calendário defaults pt-BR (já via localizations da Fase 1) | Números e datas consistentes |

## Out of Scope (Phase 2)

- Receitas (só despesas nesta fase — receitas na Fase 7), itens/parcelas (Fase 4), recorrências (Fase 4), dashboard/saldo/metas (Fase 6), importação (v2), categorias custom (v2), offline cache (trilha futura; cloud é a fonte de verdade).

## Follow-up notes

- Android toolchain pendente (validação Android após Fase 2 ou adiável).
- Revogação do token Supabase fica a cargo do usuário quando desejar.