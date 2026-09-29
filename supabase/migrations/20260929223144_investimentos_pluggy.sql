-- Investimentos importados do Open Finance (Pluggy).
-- pluggy_id = id do investimento na Pluggy; NULL para os cadastrados à mão.
-- A unique é por usuário (a conta Pluggy é compartilhada) e, como NULLs são
-- distintos no Postgres, não afeta os ativos manuais. Não é índice parcial
-- para poder ser alvo do upsert (on_conflict) do PostgREST.
alter table public.investimentos add column if not exists pluggy_id text;

alter table public.investimentos
  drop constraint if exists investimentos_pluggy_unico;
alter table public.investimentos
  add constraint investimentos_pluggy_unico unique (user_id, pluggy_id);
