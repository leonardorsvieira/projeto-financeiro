-- Atualização automática dos bancos às 8h, 14h e 20h de Brasília (UTC−3,
-- sem horário de verão): o pg_cron chama a Edge Function atualizar-bancos,
-- que pede à Pluggy uma sincronização nova de cada conexão.
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

-- Segredo da chamada agendada, gerado aqui e guardado só no Vault (o
-- repositório é público): a função confere o cabeçalho x-cron-secret por RPC.
select vault.create_secret(
  encode(extensions.gen_random_bytes(32), 'hex'),
  'cron_atualizar_bancos',
  'Cabeçalho x-cron-secret da Edge Function atualizar-bancos'
)
where not exists (
  select 1 from vault.secrets where name = 'cron_atualizar_bancos'
);

create or replace function public.cron_atualizar_bancos_confere(segredo text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from vault.decrypted_secrets
    where name = 'cron_atualizar_bancos'
      and decrypted_secret = segredo
  );
$$;

revoke all on function public.cron_atualizar_bancos_confere(text)
  from public, anon, authenticated;
grant execute on function public.cron_atualizar_bancos_confere(text)
  to service_role;

select cron.schedule(
  'atualizar-bancos',
  '0 11,17,23 * * *',
  $$
  select net.http_post(
    url := 'https://tkfhthotspehsgvmpsjm.supabase.co/functions/v1/atualizar-bancos',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = 'cron_atualizar_bancos'
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  $$
);
