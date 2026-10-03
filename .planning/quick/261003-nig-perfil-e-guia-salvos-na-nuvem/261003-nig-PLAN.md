---
phase: quick-261003-nig
plan: 01
type: quick
date: 2026-10-03
---

# Quick 261003-nig — Perfil de investidor e guia salvos na nuvem

## Pedido

"Quero que as perguntas sejam feitas apenas uma vez para definir o meu perfil
de investimento, quero que gere uma vez o relatório; se a pessoa quiser gerar
outro com os novos dados que vieram dos bancos, tenha um botão com a opção
'gerar novo relatório'." Escolha do usuário: guardar **na nuvem** (vale no
celular e no PC e sobrevive ao logout), aceitando novo aceite dos documentos.

## Tarefas

1. Migration `20261003195520_guias_investimento` (aplicada): uma linha por
   usuário com `perfil` e `guia` (jsonb, limites de tamanho), RLS própria +
   exige acesso ativo para escrever, cascade ao excluir a conta.
2. App: `toJson`/`fromJson` do perfil e do guia; `GuiasRepository` +
   `SupabaseGuiasRepository` (upsert por `user_id`); `guiaSalvoProvider`
   carrega perfil e guia; gerar salva o guia.
3. Tela: sem perfil → perguntas + "Gerar meu relatório" (salva o perfil e
   gera); com perfil → resumo do perfil + "Alterar perfil"; com guia → mostra
   o guia salvo + "Gerar novo relatório" (dados atuais dos bancos).
4. Política: perfil e último guia guardados na conta; versão 2026-10-04.
5. Testes, docs, commit, push.
