---
phase: quick-260930-kj5
plan: 01
status: complete
completed: 2026-09-30
commits: [50d70dd, fbf39ab, e500417, 8fbf49d]
---

# Quick 260930-kj5: voz Caderneta nos textos - Summary

Microcopy do app reescrito na voz Caderneta, com saudação por período do dia e nome opcional (nunca "Leonardo" fixo).

## Decisões

- Nome da conta: `primeiroNomeUsuarioProvider` (auth_controller.dart), lê `user_metadata.full_name`/`name` do Supabase, primeira palavra; com try/catch devolve null sem Supabase (testes). `AuthState` não foi alterado.
- `saudacao.dart` (funções puras `saudacaoPara`, `dataPorExtenso`) com tabela pt-BR própria, sem depender da inicialização de locale do intl (quebrava os testes de widget).
- Botão "Cancelar" da confirmação do ditado virou "Ditar novamente" (mesmo `context.pop()`); linha de botões passou a `Wrap` para não estourar em tela estreita.

## Commits

- 50d70dd resumo (saudação, abas Resumo/Livro-caixa, drawer, orçamento, vencimentos)
- fbf39ab ditado
- e500417 livro-caixa, formulário e notificações locais (emojis removidos)
- 8fbf49d demais telas (sentence case, sem "&", sem exclamações; auth_errors)

## Desvios

- Dashboard não tinha "alerta de vencimento" nem itens "Vence amanhã: descrição, R$"; usei "Vence hoje / amanhã / em N dias / Venceu em <data>" no subtítulo dos itens. A tela Próximos vencimentos manteve "Vence <data>".
- Título da lista "Livro-caixa" não existe (a lista não tem título próprio; o nome aparece na aba).
- Mantidos por serem domínio/dado: cabeçalhos do CSV (`exportar_service.dart`), `tipoConta` com "&" gravados localmente, validador "Valor inválido. Use números…", rótulos "Toque para gravar/parar", botão "Salvar" do formulário.
- Título da tela "Metas" mantido (rótulos de item viraram "Orçamento · Categoria").

## Verificação

- `flutter test`: 233 testes, todos passam.
- `flutter analyze`: 9 infos (todos pré-existentes: deprecated_member_use), sem erros/warnings novos.
- `grep "Leonardo" app/lib`: vazio; sem emojis em `app/lib`. supabase/, ícone, home_widget e domínio não tocados.
