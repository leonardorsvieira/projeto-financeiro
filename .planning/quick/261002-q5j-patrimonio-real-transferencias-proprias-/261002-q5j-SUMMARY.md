---
phase: quick-261002-q5j
plan: 01
status: complete
date: 2026-10-02
commits:
  - 2de4c38 fix(relatorios): patrimônio real, transferências para contas próprias e recargas
---

# Quick 261002-q5j — Patrimônio real, transferências próprias e recargas

## Contexto (cliente com e-mail "gabriel…jesus…", 2026-10-02)

- Relatórios mostravam "Patrimônio atual" R$ 75.360,42 = entradas − saídas de
  todo o histórico importado (R$ 41.360,42, desde 02/10/2025) + investimentos
  (R$ 34.000, 9 CDBs Sicredi). O dinheiro recebido e depois aplicado contava
  duas vezes; os investimentos de hoje eram somados em todos os meses.
- Pix de R$ 3.950 para conta no nome de outra pessoa (Lorena, provavelmente da
  família) contava como despesa; não havia como o usuário marcar como
  transferência própria (categoria neutra fora da lista).
- 11 recargas de celular (R$ 325) estavam como "Transferência entre contas"
  (não contavam como gasto).
- CDBs Sicredi com saldo exatamente igual ao aplicado; nada do Inter no
  Patrimônio.

## O que mudou (app 1.2.3+8, `pluggy` v14, `pluggy-webhook` v7)

- **Patrimônio** = saldo das contas (BANK `balance`) + investimentos − faturas
  em aberto (CREDIT `balance`), guardados em `ContaBancariaConectada`
  (`saldoContasCents`/`faturaCartoesCents`) na sincronização. Evolução
  reconstruída para trás (`evolucaoPatrimonialPorMes`). Sem banco conectado:
  "Saldo acumulado" do período. Tela e PDF.
- **"Transferência entre minhas contas"** no formulário de edição; em importado,
  oferece "Sempre" para a contraparte → `user_metadata.contas_proprias` +
  reclassificação dos importados com esse nome; usado na importação do app e do
  webhook.
- Edição não quebra mais com categoria fora da lista (ex.: "Compras").
- **Recarga** nunca é neutra (vira Assinaturas) no app e no webhook; as 11
  recargas do cliente foram corrigidas no banco.
- `pluggy`: log de diagnóstico de `/investments` só com tipos de campo e
  comparações (sem valores nem nomes) para entender o saldo sem rendimento.

## Verificação

- `flutter analyze` sem avisos novos; `flutter test` 380 passando (novos:
  evolução patrimonial, recarga, contas próprias, saldos das contas).
- Funções publicadas e respondendo (pluggy 401 sem JWT; webhook 200 ignora item
  desconhecido; boot sem erro). Site publicado (deploy-pages ok).

## Pendente

- Cliente sincronizar para gravar os saldos das contas; conferir o novo
  patrimônio com o valor que ele vê nos bancos.
- Ler o log `/investments` depois da sincronização dele para decidir o campo
  de valor dos CDBs Sicredi e entender a ausência do Inter.
- Cliente marcar o Pix para a Lorena como transferência própria (se for conta
  da família) e escolher "Sempre".
