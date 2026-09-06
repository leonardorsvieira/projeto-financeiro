# Phase 02 — Research Notes

**Phase:** 2 — Lançamentos Manuais | **Date:** 2026-09-06

## 1. Supabase Realtime + `stream()` no supabase_flutter

- `SupabaseClient.from('lancamentos').stream(primaryKey: ['id'])` devolve `Stream<List<Map<String, dynamic>>>` que combina a leitura inicial (resultado da query) com as mudanças do Realtime.
- **RT.KEY FINDING**: por padrão, tabelas novas **não** têm Realtime habilitado — é preciso publicar a tabela na publicação `supabase_realtime` (`alter publication supabase_realtime add table public.<tbl>;`). Sem isso, o stream só emite o estado inicial.
- O `stream()` respeita **RLS**: usuário só recebe as linhas que as políticas permitem (com `auth.uid()` o filtro é feito no lado seguro).
- `primaryKey` deve ser a chave primária real da tabela (id).
- Combina com `.order('data', ascending: false)` — ordenação é aplicada no lado do PostgREST (a ordem do stream reflete a query).

## 2. Formatação monetária BRL com `intl`

- `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` — formata como `R$ 1.234,56`.
- Risco conhecido: locale pt-BR vs pt-PT (o formato do Real é correto com symbol explicitado; Não herdar `name` do locale — fixar `symbol: 'R\$'`).
- Cuidado com arredondamento: usar centavos inteiros (int) e converter para `double` só na camada de apresentação (`cents / 100.0`); na entrada, converter texto decimal para centavos com precisão controlada (rejeitar >2 casas decimais).

## 3. Aplicação da migration no projeto remoto (sem docker)

- Caminho preferido: `supabase db push` (projeto linkado; o CLI pode persistir o access token em `~/.supabase/access-token` — verificar; senão, exigir token de novo).
- Fallback: Management API `POST https://api.supabase.com/v1/projects/{ref}/database/query` com body `{"query": "<sql>"}` (no Auth Header `Authorization: Bearer <pat>`).
- Alternativa de verificação independente: repetir `pg_dump`-style query ler `information_schema` (id_table, rls, policies) via o endpoint de query.

## 4. PostgREST + RLS (checagem do bloqueio anon)

- Com `anon` (sem JWT autenticado), `SELECT` na tabela sem política de `anon` retorna colunas protegidas/erro de permissão ou lista vazia — a política sendo apenas `to authenticated using (auth.uid() = user_id)` não concede acesso a role anon.

## Sources
- supabase_flutter Realtime/stream docs (2026).
- intl NumberFormat currency docs (2026).
- Supabase Management API / CLI docs (revisão 2026).