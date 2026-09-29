---
quick_id: 260929-r0j
status: complete
---

# Resumo — Investimentos do Open Finance no Patrimônio

- **Banco:** migration `20260929223144_investimentos_pluggy` (aplicada no remoto):
  `investimentos.pluggy_id` + unique `(user_id, pluggy_id)`.
- **Edge Function `pluggy` (v8, deployada, JWT ligado):** nova rota
  `GET /investments?itemId=&page=&pageSize=`, só para items do próprio usuário.
- **App:**
  - `Investimento.pluggyId` / `importadoOpenFinance`.
  - `investimentoDaPluggy` + `classeDoInvestimentoPluggy` (EQUITY/ETF → Ações,
    fundo imobiliário → FIIs, cripto → Cripto, resto → Renda Fixa; ignora
    `TOTAL_WITHDRAWAL`/saldo zero). Ações usam o ticker como nome.
  - `PluggyOpenFinanceService.buscarInvestimentos` (paginado, `completo` só se
    todas as conexões responderem).
  - `InvestimentosRepository.sincronizarOpenFinance`: insere/atualiza por
    `pluggy_id`, só reescreve quando muda, remove importados ausentes apenas
    com resposta completa; manuais intocados.
  - Chamado no fim de `_sincronizar` (botão, histórico e automática a cada
    30 min); falha não afeta a importação de transações.
  - Lista do Patrimônio mostra "· Open Finance" nos importados.
- **Verificação:** `flutter analyze` (só infos antigos), `flutter test` 250 ✓
  (novo `investimentos_pluggy_test.dart`).

## Limitações conhecidas
- Editar um ativo importado é sobrescrito na próxima sincronização.
- Mesmo banco conectado duas vezes (direto e via Meu Pluggy) duplica posições.
- Ativos já cadastrados à mão iguais aos importados ficam duplicados — apagar o manual.
- Depende do produto "Investments" habilitado na aplicação Pluggy.
