-- Controle de acesso por assinatura mensal.
--
-- O Meu Bolso é vendido por mensalidade e cada cliente é liberado à mão pelo
-- dono, pelo e-mail. Só usa o app quem é administrador ou tem uma linha em
-- public.acessos com a validade em dia (valido_ate nulo = sem prazo).
--
-- O SERVIDOR é a fonte da verdade: o portão do app (/sem-acesso) é só UX.
-- Quem baixar o APK repassado ou modificar o app continua sem escrever nada,
-- porque as policies RESTRICTIVE abaixo exigem public.acesso_ativo() e as Edge
-- Functions (ditado, pluggy, pluggy-webhook) conferem o mesmo antes de gastar cota.
--
-- O SELECT continua liberado de propósito (LGPD: acesso e portabilidade dos
-- próprios dados mesmo com a assinatura vencida). A exclusão da conta também
-- segue funcionando: a Edge Function excluir-conta usa service_role e o
-- ON DELETE CASCADE de auth.users não passa por RLS.
--
-- O seed (o dono em administradores e as contas já existentes em acessos com
-- valido_ate nulo) é feito por SQL fora do repositório, que é público: nenhum
-- e-mail nem id de usuário mora neste arquivo.
--
-- O hook de cadastro (hook_antes_de_criar_usuario) é OPCIONAL e se ativa no
-- Dashboard. Sem ele o cadastro passa, mas o portão do app, o RLS e as Edge
-- Functions bloqueiam do mesmo jeito.

-- 1) administradores: quem gerencia a lista de acessos.
--    Só leitura da própria linha pelo cliente; inclusão e remoção só por SQL.
create table if not exists public.administradores (
  user_id uuid primary key references auth.users(id) on delete cascade
);

alter table public.administradores enable row level security;

drop policy if exists administradores_select_proprio on public.administradores;
create policy administradores_select_proprio on public.administradores
  for select to authenticated using ((select auth.uid()) = user_id);

revoke all on public.administradores from anon;
-- TRUNCATE ignora RLS: tira também (defesa em profundidade).
revoke insert, update, delete, truncate, references, trigger
  on public.administradores from authenticated;

-- 2) acessos: e-mails liberados e até quando (valido_ate nulo = sem prazo).
create table if not exists public.acessos (
  email text primary key
    check (email = lower(btrim(email)) and email like '%_@_%'),
  valido_ate date,
  observacao text check (observacao is null or char_length(observacao) <= 500),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

alter table public.acessos enable row level security;

revoke all on public.acessos from anon;
revoke truncate, references, trigger on public.acessos from authenticated;

-- 3) Funções de decisão. Rodam como o dono das tabelas (security definer), então
--    leem sem passar pelo RLS (sem recursão). search_path vazio + nomes
--    qualificados. Regra espelhada em acessoAtivo() de
--    supabase/functions/_shared/seguranca.ts: mude as duas juntas.
create or replace function public.eh_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.administradores a
    where a.user_id = (select auth.uid())
  );
$$;

create or replace function public.acesso_ativo()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.eh_admin() or exists (
    select 1
    from public.acessos x
    where x.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
      and (
        x.valido_ate is null
        or x.valido_ate >= (now() at time zone 'America/Sao_Paulo')::date
      )
  );
$$;

-- Funções novas ganham EXECUTE para PUBLIC por padrão: só authenticated usa.
revoke execute on function public.eh_admin() from public, anon;
grant execute on function public.eh_admin() to authenticated;
revoke execute on function public.acesso_ativo() from public, anon;
grant execute on function public.acesso_ativo() to authenticated;

-- 4) Policies de acessos: cada um enxerga a própria linha; só administrador
--    lê a lista inteira e escreve. Ninguém se libera sozinho.
drop policy if exists acessos_select on public.acessos;
create policy acessos_select on public.acessos
  for select to authenticated
  using (
    email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    or (select public.eh_admin())
  );

drop policy if exists acessos_insert_admin on public.acessos;
create policy acessos_insert_admin on public.acessos
  for insert to authenticated
  with check ((select public.eh_admin()));

drop policy if exists acessos_update_admin on public.acessos;
create policy acessos_update_admin on public.acessos
  for update to authenticated
  using ((select public.eh_admin()))
  with check ((select public.eh_admin()));

drop policy if exists acessos_delete_admin on public.acessos;
create policy acessos_delete_admin on public.acessos
  for delete to authenticated
  using ((select public.eh_admin()));

-- 5) Trava de escrita nas tabelas de dados. Policies RESTRICTIVE se somam (E) às
--    permissivas *_own, que seguem intactas: além de ser o dono da linha, a conta
--    precisa estar com acesso ativo. Sem restrição de SELECT, de propósito.
--    service_role (webhook, excluir-conta) ignora RLS.

-- lancamentos
drop policy if exists lancamentos_exige_acesso_insert on public.lancamentos;
create policy lancamentos_exige_acesso_insert on public.lancamentos
  as restrictive for insert to authenticated
  with check ((select public.acesso_ativo()));

drop policy if exists lancamentos_exige_acesso_update on public.lancamentos;
create policy lancamentos_exige_acesso_update on public.lancamentos
  as restrictive for update to authenticated
  using ((select public.acesso_ativo()))
  with check ((select public.acesso_ativo()));

drop policy if exists lancamentos_exige_acesso_delete on public.lancamentos;
create policy lancamentos_exige_acesso_delete on public.lancamentos
  as restrictive for delete to authenticated
  using ((select public.acesso_ativo()));

-- metas
drop policy if exists metas_exige_acesso_insert on public.metas;
create policy metas_exige_acesso_insert on public.metas
  as restrictive for insert to authenticated
  with check ((select public.acesso_ativo()));

drop policy if exists metas_exige_acesso_update on public.metas;
create policy metas_exige_acesso_update on public.metas
  as restrictive for update to authenticated
  using ((select public.acesso_ativo()))
  with check ((select public.acesso_ativo()));

drop policy if exists metas_exige_acesso_delete on public.metas;
create policy metas_exige_acesso_delete on public.metas
  as restrictive for delete to authenticated
  using ((select public.acesso_ativo()));

-- investimentos
drop policy if exists investimentos_exige_acesso_insert on public.investimentos;
create policy investimentos_exige_acesso_insert on public.investimentos
  as restrictive for insert to authenticated
  with check ((select public.acesso_ativo()));

drop policy if exists investimentos_exige_acesso_update on public.investimentos;
create policy investimentos_exige_acesso_update on public.investimentos
  as restrictive for update to authenticated
  using ((select public.acesso_ativo()))
  with check ((select public.acesso_ativo()));

drop policy if exists investimentos_exige_acesso_delete on public.investimentos;
create policy investimentos_exige_acesso_delete on public.investimentos
  as restrictive for delete to authenticated
  using ((select public.acesso_ativo()));

-- 6) Hook opcional "Before User Created": barra já no cadastro e-mails sem
--    acesso em dia. Ativar em Dashboard > Authentication > Hooks > Before User
--    Created (tipo Postgres) apontando para public.hook_antes_de_criar_usuario.
--    Sem o hook o cadastro passa, mas o portão + RLS + Edge Functions bloqueiam
--    igual. Devolve {} para liberar ou o erro 403 com a mensagem para o cliente.
create or replace function public.hook_antes_de_criar_usuario(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(coalesce(event -> 'user' ->> 'email', '')));
begin
  if v_email <> '' and exists (
    select 1
    from public.acessos x
    where x.email = v_email
      and (
        x.valido_ate is null
        or x.valido_ate >= (now() at time zone 'America/Sao_Paulo')::date
      )
  ) then
    return '{}'::jsonb;
  end if;

  return jsonb_build_object(
    'error',
    jsonb_build_object(
      'http_code', 403,
      'message', 'Este e-mail ainda não tem acesso ao Meu Bolso. Fale com o vendedor.'
    )
  );
end;
$$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.hook_antes_de_criar_usuario(jsonb) to supabase_auth_admin;
revoke execute on function public.hook_antes_de_criar_usuario(jsonb) from public, anon, authenticated;
