-- Adicionar colunas para itens detalhados e recorrência mensal
-- 20260906140000_add_itens_recorrencia.sql

alter table if exists public.lancamentos
  add column if not exists itens jsonb,
  add column if not exists fixo_mensal boolean not null default false,
  add column if not exists serie_id uuid;

-- Índice para busca eficiente de séries
create index if not exists lancamentos_user_serie_idx
  on public.lancamentos (user_id, serie_id)
  where serie_id is not null;

-- Índice para buscar cópias vigentes (mês atual + próximo)
create index if not exists lancamentos_user_fixa_data_idx
  on public.lancamentos (user_id, data desc)
  where fixo_mensal = true;

-- Comentários para documentação
comment on column public.lancamentos.itens is 'Array de itens: [{descricao, valor_cents}]';
comment on column public.lancamentos.fixo_mensal is 'Marca se é despesa fixa mensal (gera cópias automáticas)';
comment on column public.lancamentos.serie_id is 'Agrupa lançamentos de uma mesma série fixa mensal';