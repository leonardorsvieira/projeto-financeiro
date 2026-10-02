-- Cartões de crédito de cada usuário (antes ficavam só no aparelho, em
-- SharedPreferences: sumiam no logout, não sincronizavam celular ↔ web e todo
-- usuário novo nascia com os cartões do dono).

create table if not exists public.cartoes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null check (char_length(btrim(nome)) between 1 and 40),
  dia_fechamento smallint not null check (dia_fechamento between 1 and 31),
  dia_vencimento smallint not null check (dia_vencimento between 1 and 31),
  validade_mmyy text check (validade_mmyy is null or validade_mmyy ~ '^(0[1-9]|1[0-2])/[0-9]{2}$'),
  limite_cents bigint check (limite_cents is null or limite_cents >= 0),
  cor_hex text not null default '#0B7A4B' check (cor_hex ~ '^#[0-9A-Fa-f]{6}$'),
  created_at timestamptz not null default now()
);

create index if not exists cartoes_user_created_idx on public.cartoes (user_id, created_at);

alter table public.cartoes enable row level security;

revoke all on public.cartoes from anon;
revoke truncate, references, trigger on public.cartoes from authenticated;
grant select, insert, update, delete on public.cartoes to authenticated;

drop policy if exists cartoes_select_own on public.cartoes;
create policy cartoes_select_own on public.cartoes
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists cartoes_insert_own on public.cartoes;
create policy cartoes_insert_own on public.cartoes
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists cartoes_update_own on public.cartoes;
create policy cartoes_update_own on public.cartoes
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists cartoes_delete_own on public.cartoes;
create policy cartoes_delete_own on public.cartoes
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Mesma regra de assinatura de lançamentos/metas/investimentos
-- (20261001220000_controle_de_acesso.sql): sem acesso ativo, só leitura.
drop policy if exists cartoes_exige_acesso_insert on public.cartoes;
create policy cartoes_exige_acesso_insert on public.cartoes
  as restrictive for insert to authenticated
  with check ((select public.acesso_ativo()));

drop policy if exists cartoes_exige_acesso_update on public.cartoes;
create policy cartoes_exige_acesso_update on public.cartoes
  as restrictive for update to authenticated
  using ((select public.acesso_ativo()))
  with check ((select public.acesso_ativo()));

drop policy if exists cartoes_exige_acesso_delete on public.cartoes;
create policy cartoes_exige_acesso_delete on public.cartoes
  as restrictive for delete to authenticated
  using ((select public.acesso_ativo()));
