-- Quanto foi aplicado em cada investimento (vindo do Open Finance:
-- amountOriginal da Pluggy). NULL quando o banco não informa.
alter table public.investimentos
  add column if not exists valor_investido_cents bigint
  check (valor_investido_cents is null or valor_investido_cents >= 0);
