-- Perfil de investidor e último Guia de investimentos de cada usuário: as
-- perguntas do perfil são feitas uma vez e o guia fica salvo (vale no celular
-- e na web e não some no logout). Uma linha por usuário.

create table if not exists public.guias_investimento (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  perfil jsonb check (perfil is null or octet_length(perfil::text) <= 4096),
  guia jsonb check (guia is null or octet_length(guia::text) <= 65536),
  atualizado_em timestamptz not null default now()
);

alter table public.guias_investimento enable row level security;

revoke all on public.guias_investimento from anon;
revoke truncate, references, trigger on public.guias_investimento from authenticated;
grant select, insert, update, delete on public.guias_investimento to authenticated;

drop policy if exists guias_investimento_select_own on public.guias_investimento;
create policy guias_investimento_select_own on public.guias_investimento
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists guias_investimento_insert_own on public.guias_investimento;
create policy guias_investimento_insert_own on public.guias_investimento
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists guias_investimento_update_own on public.guias_investimento;
create policy guias_investimento_update_own on public.guias_investimento
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists guias_investimento_delete_own on public.guias_investimento;
create policy guias_investimento_delete_own on public.guias_investimento
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Mesma regra de assinatura das outras tabelas
-- (20261001220000_controle_de_acesso.sql): sem acesso ativo, só leitura.
drop policy if exists guias_investimento_exige_acesso_insert on public.guias_investimento;
create policy guias_investimento_exige_acesso_insert on public.guias_investimento
  as restrictive for insert to authenticated
  with check ((select public.acesso_ativo()));

drop policy if exists guias_investimento_exige_acesso_update on public.guias_investimento;
create policy guias_investimento_exige_acesso_update on public.guias_investimento
  as restrictive for update to authenticated
  using ((select public.acesso_ativo()))
  with check ((select public.acesso_ativo()));

drop policy if exists guias_investimento_exige_acesso_delete on public.guias_investimento;
create policy guias_investimento_exige_acesso_delete on public.guias_investimento
  as restrictive for delete to authenticated
  using ((select public.acesso_ativo()));
