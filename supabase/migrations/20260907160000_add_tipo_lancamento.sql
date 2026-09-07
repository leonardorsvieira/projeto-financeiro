-- Adicionar tipo (despesa | receita) aos lançamentos — Fase 7 (Recebimentos por Voz).
-- Valores em centavos permanecem positivos; o sinal é aplicado na UI.

alter table if exists public.lancamentos
  add column if not exists tipo text not null default 'despesa';

alter table if exists public.lancamentos
  drop constraint if exists lancamentos_tipo_check;

alter table if exists public.lancamentos
  add constraint lancamentos_tipo_check check (tipo in ('despesa', 'receita'));

comment on column public.lancamentos.tipo is 'despesa | receita (default despesa)';