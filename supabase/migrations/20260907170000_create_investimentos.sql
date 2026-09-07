-- Investimentos — ativos/posições, movimentos (compra/venda) e rendimentos.
-- Decisões Fase 8 (08-CONTEXT D-02/D-03/D-04/D-07):
--  * sem cotação automática (preço atual manual ou último trade);
--  * acao/fii/cripto = posição por quantidade × preco_atual_cents;
--  * renda_fixa/banco_digital = posição por saldo_cents (editável).

create table if not exists public.investimentos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  classe text not null check (classe in ('acao', 'fii', 'cripto', 'renda_fixa', 'banco_digital')),
  nome text not null,
  -- Posição por quantidade (ações/FII/cripto). 0 quando não aplicável.
  quantidade double precision not null default 0 check (quantidade >= 0),
  -- Preço unitário atual em centavos (0 quando não aplicável).
  preco_atual_cents bigint not null default 0 check (preco_atual_cents >= 0),
  -- Posição por saldo (renda fixa/banco digital). 0 quando não aplicável.
  saldo_cents bigint not null default 0 check (saldo_cents >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists investimentos_user_classe_idx on public.investimentos (user_id, classe);

alter table public.investimentos enable row level security;

drop policy if exists investimentos_select_own on public.investimentos;
create policy investimentos_select_own on public.investimentos
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists investimentos_insert_own on public.investimentos;
create policy investimentos_insert_own on public.investimentos
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists investimentos_update_own on public.investimentos;
create policy investimentos_update_own on public.investimentos
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists investimentos_delete_own on public.investimentos;
create policy investimentos_delete_own on public.investimentos
  for delete to authenticated using (auth.uid() = user_id);

create table if not exists public.movimentos_investimento (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  investimento_id uuid not null references public.investimentos(id) on delete cascade,
  tipo text not null check (tipo in ('compra', 'venda')),
  quantidade double precision not null check (quantidade > 0),
  preco_unit_cents bigint not null check (preco_unit_cents >= 0),
  data date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists movimentos_investimento_invest_id_idx
  on public.movimentos_investimento (investimento_id, data desc);

alter table public.movimentos_investimento enable row level security;

drop policy if exists movimentos_investimento_select_own on public.movimentos_investimento;
create policy movimentos_investimento_select_own on public.movimentos_investimento
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists movimentos_investimento_insert_own on public.movimentos_investimento;
create policy movimentos_investimento_insert_own on public.movimentos_investimento
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists movimentos_investimento_update_own on public.movimentos_investimento;
create policy movimentos_investimento_update_own on public.movimentos_investimento
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists movimentos_investimento_delete_own on public.movimentos_investimento;
create policy movimentos_investimento_delete_own on public.movimentos_investimento
  for delete to authenticated using (auth.uid() = user_id);

create table if not exists public.rendimentos_investimento (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  investimento_id uuid not null references public.investimentos(id) on delete cascade,
  tipo text not null default 'dividendo' check (tipo in ('dividendo', 'juros', 'rendimento', 'outro')),
  valor_cents bigint not null check (valor_cents >= 0),
  data date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists rendimentos_investimento_invest_id_idx
  on public.rendimentos_investimento (investimento_id, data desc);

alter table public.rendimentos_investimento enable row level security;

drop policy if exists rendimentos_investimento_select_own on public.rendimentos_investimento;
create policy rendimentos_investimento_select_own on public.rendimentos_investimento
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists rendimentos_investimento_insert_own on public.rendimentos_investimento;
create policy rendimentos_investimento_insert_own on public.rendimentos_investimento
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists rendimentos_investimento_update_own on public.rendimentos_investimento;
create policy rendimentos_investimento_update_own on public.rendimentos_investimento
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists rendimentos_investimento_delete_own on public.rendimentos_investimento;
create policy rendimentos_investimento_delete_own on public.rendimentos_investimento
  for delete to authenticated using (auth.uid() = user_id);

-- Realtime para o stream() do supabase_flutter emitir mudanças em tempo real.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

alter publication supabase_realtime add table public.investimentos;
alter publication supabase_realtime add table public.movimentos_investimento;
alter publication supabase_realtime add table public.rendimentos_investimento;