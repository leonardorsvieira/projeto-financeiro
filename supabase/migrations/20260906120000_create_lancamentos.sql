-- Lancamentos — despesas do usuário dono (RLS por auth.uid()).

create table if not exists public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  descricao text not null check (char_length(descricao) between 1 and 200),
  valor_cents bigint not null check (valor_cents > 0),
  categoria text not null,
  forma_pagamento text not null,
  data date not null default current_date,
  vencimento date,
  obs text check (obs is null or char_length(obs) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists lancamentos_user_data_idx on public.lancamentos (user_id, data desc);
create index if not exists lancamentos_user_created_idx on public.lancamentos (user_id, created_at desc);

alter table public.lancamentos enable row level security;

drop policy if exists lancamentos_select_own on public.lancamentos;
create policy lancamentos_select_own on public.lancamentos
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists lancamentos_insert_own on public.lancamentos;
create policy lancamentos_insert_own on public.lancamentos
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists lancamentos_update_own on public.lancamentos;
create policy lancamentos_update_own on public.lancamentos
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists lancamentos_delete_own on public.lancamentos;
create policy lancamentos_delete_own on public.lancamentos
  for delete to authenticated using (auth.uid() = user_id);

-- Realtime para o stream() do supabase_flutter emitir mudanças em tempo real.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

alter publication supabase_realtime add table public.lancamentos;