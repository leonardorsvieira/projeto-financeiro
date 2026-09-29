-- Reserva dos lançamentos importados da Pluggy antes de reimportar
-- (importação antiga tratava compra de cartão como entrada). Só servidor.
create table if not exists public.lancamentos_backup_pluggy
  (like public.lancamentos including defaults);
alter table public.lancamentos_backup_pluggy
  add column if not exists movido_em timestamptz not null default now(),
  add column if not exists motivo text;
alter table public.lancamentos_backup_pluggy enable row level security;
revoke all on public.lancamentos_backup_pluggy from anon, authenticated;
