# Plan 02-01 — Summary

**Phase:** 02-lan-amentos-manuais | **Plan:** 01 | **Status:** Complete | **Date:** 2026-09-06

## What was done

1. **Migration `supabase/migrations/20260906120000_create_lancamentos.sql`** criada e idempotente:
   - Tabela `lancamentos` (id uuid pk, user_id default `auth.uid()` FK `auth.users ON DELETE CASCADE`, descricao 1..200, `valor_cents bigint > 0`, categoria, forma_pagamento, data default today, vencimento nullable, obs ≤500, created_at/updated_at).
   - Índices `lancamentos_user_data_idx (user_id, data DESC)` e `lancamentos_user_created_idx (user_id, created_at DESC)`.
   - RLS habilitada + 4 policies (`*_own` por `auth.uid() = user_id`, apenas `to authenticated`): SELECT/INSERT/UPDATE/DELETE.
   - Realtime: publicação `supabase_realtime` criada se ausente e tabela `lancamentos` adicionada.

2. **Aplicada no remoto** via `supabase db push --linked` (token do usuário revogado anteriormente; novo PAT usado via env var, substituído de forma rotativa).

3. **02-SKELETON.md** atualizado p/ Fase 2 (decisões D-14..D-21, stack touched).

## Verification results (remote, via Management API db/query)

| Check | Result |
|-------|--------|
| Tabela `lancamentos` com RLS (`rowsecurity=true`) | `n=1` √ |
| Policy count (SELECT+INSERT+UPDATE+DELETE) | `n=4` √ |
| Realtime publication `supabase_realtime` contém `lancamentos` | `n=1` √ |
| Acesso anon (sem JWT) via PostgREST | `200 []` — 0 linhas, sem leak √ |

Nenhuma credencial apareceu em logs/saída; `.env` e token fora do git.

## Decisions/notes

- Token anterior revogado; o novo PAT (`sbp_c0…`) foi usado apenas em memória. Recomenda-se revogá-lo ao fim do milestone e trocar por login no CLI se preferir persistência segura.
- `alter publication ... add table` executou sem erro de duplicidade (primeira aplicação).