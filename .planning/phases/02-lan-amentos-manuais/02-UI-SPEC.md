# Phase 02 — UI-SPEC (Flutter web-first)

**Phase:** 2 — Lançamentos Manuais | **Date:** 2026-09-06
**Base:** Material 3, seed `0xFF0B7A4B`, PT-BR, font padrão Flutter, app `br.com.meubolso`. Telas seguem `app_theme.dart` da Fase 1.

## Screen S5 — Lista de Lançamentos (Home)

- **AppBar**: título "Meu Bolso". Bolt/campo vazio (saldo é Fase 6).
- **Body**: 
  - Lista (`ListView.builder` via `StreamProvider<AsyncValue<List<Lancamento>>>`): cada tile = título `descricao`, subtítulo `data (dd/MM/yyyy) · categoria` , trailing valor `R$ x.xxx,xx` (cor vermelho `error`; despesa).
  - Categoria como chip/leading com rótulo curto.
  - **Empty state**: ícone + "Nenhum lançamento ainda" + hint "Toque em + para registrar".
  - **Pull-to-refresh** (RefreshIndicator) — força nova query (stream já dá sync).
  - Estado de erro da stream: message + botão "Tentar de novo".
- **FAB** (`+`) → rota `/lancamentos/novo`.
- **Menu do item** (⋮ popup): **Editar** → rota `/lancamentos/:id`, **Excluir** → `AlertDialog` confirm ("Excluir lançamento?" / Ação não pode ser desfeita / Cancelar+Excluir). Confirmar remove.
- **Seletor por data**: fora do escopo do MVP (lista ordenada por data desc).

## Screen S6 — Formulário de Lançamento (novo/editar)

- AppBar: "Novo lançamento" / "Editar lançamento". Salvar = action no AppBar (`Ícone check`).
- **Campo Descrição**: `TextFormField` , obrigatório, máx 200 chars, erro: "Informe uma descrição".
- **Campo Valor (R$)**: `TextFormField` keyboardType `numberWithOptions(decimal: true)`, prefix `R$`, valida vírgula/ponto decimal, máx 2 casas, >0; erro: "Informe um valor válido maior que zero". Parse estrito em centavos (rejeita 3+ casas).
- **Categoria**: `DropdownButtonFormField` (Alimentação, Transporte, Moradia, Saúde, Lazer, Educação, Mercado, Assinaturas, Outros), default "Outros".
- **Forma de pagamento**: dropdown (Pix, Cartão de Crédito, Cartão de Débito, Dinheiro, Boleto, Transferência, Outro), default "Pix".
- **Data**: `showDatePicker` default hoje (local locale pt-BR), exibida dd/MM/yyyy.
- **Vencimento (opcional)**: botão "Vencimento" + data ou "Remover"; não obrigatório.
- **Obs (opcional)**: `TextFormField` multiline máx 500.
- Botões: Cancelar (pop) / Salvar (valida + guarda; sucesso → pop; erro → snackbar "Não foi possível salvar").
- App em estado "saving" desabilita o botão.

## Tokens/UX

- Valores em BRL: `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`.
- Datas: `dd/MM/yyyy`.
- Despesa = cor `colorScheme.error`.
- Loader: CircularProgressIndicator central no primeiro carregamento.