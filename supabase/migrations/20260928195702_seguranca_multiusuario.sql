-- Endurecimento de segurança multiusuário.
-- 1) pluggy_items: dono de cada item (conexão bancária) da Pluggy. A conta Pluggy é
--    compartilhada entre todos os usuários, então o isolamento é feito aqui: a Edge
--    Function `pluggy` só entrega items/contas/transações cujo item pertence ao usuário.
--    Escrita apenas pela Edge Function (service_role); o cliente só lê os próprios.
create table if not exists public.pluggy_items (
  item_id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists pluggy_items_user_id_idx on public.pluggy_items (user_id);

alter table public.pluggy_items enable row level security;

create policy pluggy_items_select_own on public.pluggy_items
  for select to authenticated using ((select auth.uid()) = user_id);

revoke insert, update, delete on public.pluggy_items from anon, authenticated;

-- 2) uso_diario + consumir_cota(): limite diário por usuário das Edge Functions
--    (IA e Pluggy), para que uma conta nova não esgote as cotas do projeto.
create table if not exists public.uso_diario (
  user_id uuid not null references auth.users(id) on delete cascade,
  recurso text not null,
  dia date not null default current_date,
  chamadas integer not null default 0,
  primary key (user_id, recurso, dia)
);

alter table public.uso_diario enable row level security;
-- Sem policies: nenhum acesso pelo cliente.
revoke all on public.uso_diario from anon, authenticated;

create or replace function public.consumir_cota(
  p_user uuid,
  p_recurso text,
  p_limite integer
) returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_chamadas integer;
begin
  insert into public.uso_diario (user_id, recurso, dia, chamadas)
  values (p_user, p_recurso, current_date, 1)
  on conflict (user_id, recurso, dia)
    do update set chamadas = public.uso_diario.chamadas + 1
  returning chamadas into v_chamadas;
  return v_chamadas <= p_limite;
end;
$$;

revoke execute on function public.consumir_cota(uuid, text, integer) from public, anon, authenticated;
grant execute on function public.consumir_cota(uuid, text, integer) to service_role;

-- 3) Defesa em profundidade: o app só acessa tabelas autenticado; `anon` não
--    precisa de nenhum privilégio no schema public (o RLS continua valendo).
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke execute on all functions in schema public from anon;
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public revoke execute on functions from anon;
