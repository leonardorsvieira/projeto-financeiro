-- Impede lançamento duplicado da mesma transação da Pluggy: o app (botão e
-- sincronização automática) e o webhook `pluggy-webhook` podem importar a mesma
-- transação ao mesmo tempo. A chave é `obs = 'pluggy_id:<id da transação>'`.
create unique index if not exists lancamentos_pluggy_unico
  on public.lancamentos (user_id, obs)
  where obs like 'pluggy_id:%';
