-- Metas — limite mensal de gasto por categoria (uma meta por categoria).
-- Recorrente: o limite vale para todos os meses (comparado com o gasto do mês vigente).

create table if not exists public.metas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  categoria text not null,
  valor_limite_cents bigint not null check (valor_limite_cents > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, categoria)
);

create index if not exists metas_user_created_idx on public.metas (user_id, created_at desc);

alter table public.metas enable row level security;

drop policy if exists metas_select_own on public.metas;
create policy metas_select_own on public.metas
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists metas_insert_own on public.metas;
create policy metas_insert_own on public.metas
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists metas_update_own on public.metas;
create policy metas_update_own on public.metas
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists metas_delete_own on public.metas;
create policy metas_delete_own on public.metas
  for delete to authenticated using (auth.uid() = user_id);

-- Realtime para o stream() do supabase_flutter emitir mudanças em tempo real.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

alter publication supabase_realtime add table public.metas;