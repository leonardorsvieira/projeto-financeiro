---
quick_id: 260929-rf2
status: complete
---

# Resumo — Patrimônio somente Open Finance

- Sincronização: com ao menos 1 investimento vindo da Pluggy, os ativos
  manuais (sem `pluggy_id`) são apagados — hoje 15, todos do dono; nenhum
  movimento/rendimento vinculado. Sem investimentos da Pluggy, nada é apagado.
- Telas de Investimentos e detalhe agora são só leitura; card esconde o
  rendimento quando não há custo registrado.
- Removidos: formulário de ativo, movimentos e rendimentos manuais, botão e
  serviço de cotações (e seus domínios no CSP), ditado de investimento
  (rascunho, tela de confirmação, rota e campos do prompt).
- Mantidos (só leitura): calculadora de rebalanceamento, tela de rendimentos
  e calendário de proventos — ficam vazios sem rendimentos cadastrados.
- `flutter analyze`: só infos antigos; `flutter test`: 236 ✓.
