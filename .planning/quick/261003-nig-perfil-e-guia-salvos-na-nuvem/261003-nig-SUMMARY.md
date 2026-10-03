---
phase: quick-261003-nig
plan: 01
status: complete
date: 2026-10-03
---

# Quick 261003-nig — Perfil de investidor e guia salvos na nuvem

## Resultado

- **Banco:** migration `20261003195520_guias_investimento` aplicada pelo MCP
  (uma linha por usuário, `perfil`/`guia` jsonb com limite de tamanho, RLS
  própria + escrita exige acesso ativo, cascade ao excluir a conta). Advisor
  de segurança sem achado novo.
- **App:** `GuiasRepository`/`SupabaseGuiasRepository` (upsert por
  `user_id`, só das colunas enviadas); `guiaSalvoProvider` carrega perfil e
  último guia; `geracaoGuiaProvider` gera e salva (o guia aparece mesmo se
  guardar falhar). JSON defensivo (fonte só https).
- **Tela:** primeira vez → perguntas + "Gerar meu relatório" (salva o perfil
  e gera); depois → "Seu perfil" (resumo) + "Alterar perfil" (refaz as
  seleções, Cancelar/Salvar) + relatório salvo + "Gerar novo relatório"
  (dados atuais dos bancos, substitui o anterior; erro mantém o anterior).
- **Bug evitado:** a geração lia os lançamentos sem ninguém ouvindo o stream
  (sairia "nenhum lançamento registrado" no primeiro uso); a tela agora
  mantém os dados ouvidos e a geração espera os streams (até 10 s).
- **Política:** perfil e último guia guardados na conta; `versaoDocumentos`
  = 2026-10-04 (novo aceite).

## Verificação

- `flutter test`: 458 passando (tela do guia reescrita: primeira vez, guia
  salvo, alterar/cancelar perfil, erro; JSON do perfil/guia).
  `flutter analyze`: só os 9 avisos antigos.
