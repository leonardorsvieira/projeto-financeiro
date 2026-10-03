-- Desliga o agendamento das 8h/14h/20h: todas as conexões são Meu Pluggy, que
-- a Pluggy não deixa atualizar por API ("MeuPluggy item cant be updated").
-- A função atualizar-bancos, o segredo do Vault e a RPC continuam; para
-- religar, repetir o cron.schedule da migration 20261003162629.
select cron.unschedule('atualizar-bancos')
where exists (select 1 from cron.job where jobname = 'atualizar-bancos');
