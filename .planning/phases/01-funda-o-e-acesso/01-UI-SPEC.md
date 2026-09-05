# UI-SPEC — Phase 01: Fundação e Acesso

**Phase:** 1
**Generated:** 2026-09-05
**Scope:** Screens de auth (splash, login, cadastro) + home placeholder. Apenas o que a Fase 1 entrega.

---

## Design Tokens

| Token | Valor | Uso |
|-------|-------|-----|
| `colorPrimary` | Verde financeiro `#0B7A4B` | Botões primários, destaques |
| `colorPrimaryDark` | `#086B40` | AppBar, estados pressionados |
| `colorBackground` | `#111A16` (dark) / `#F7FAF8` (light) | Fundo — suporte a dark mode |
| `colorSurface` | `#1B2A22` / `#FFFFFF` | Cards, inputs |
| `colorText` | `#E8F1EC` / `#16211B` | Texto principal |
| `colorError` | `#E5484D` | Erros de validação |
| `radius` | 12 px | Cantos de inputs/botões |
| `spacing` | 4·8·16·24 px | Escala de espaçamento |
| `fontScale` | 1.0 (acessível) | Textos ≥ 14 pt; títulos 20-28 pt |

**Material 3** com `ColorScheme.fromSeed(seedColor: 0x0B7A4B)` + `useMaterial3: true`. Suporte claro/escuro via `ThemeMode.system`.

---

## Screens

### S1 — Splash
- Fundo `colorBackground`, logo centralizado ("Meu Bolso" + ícone de carteira/cifrão), spinner sutil.
- **Behaviors:** resolve a sessão persistida (máx ~2s) e redireciona → `/home` se logado, `/login` se não.

### S2 — Login (`/login`)
- Logo "Meu Bolso" no topo (hero).
- Campos: **E-mail** (`TextFormField`, keyboardType email, autofill) e **Senha** (`obscureText: true`, toggle visibility).
- Botão primário full-width **"Entrar"** com loading (spinner + disabled enquanto autentica).
- Link "Não tem conta? **Criar conta**" → `/signup`.
- **Erros:** mensagem inline abaixo do form (e-mail não encontrado / senha incorreta), `colorError`.

### S3 — Cadastro (`/signup`)
- Mesmo layout do Login: **E-mail**, **Senha** (min 6 caracteres, dica de regra), **Confirmar senha**.
- Botão **"Criar conta"** (loading state). Link "Já tem conta? **Entrar**" → `/login`.
- **Erros:** e-mail em uso / senha fraca / senhas não conferem — mensagens inline.

### S4 — Home placeholder (`/home`)
- AppBar "Meu Bolso", painel simples "Fase 2 em breve — seus gastos aparecem aqui", avatar do e-mail logado.
- **Item "Sair"** (menu ou botão) → confirma → `signOut()` → volta a `/login`.
- Acessível em todos os alvos; corpo responsivo (centralizado, máx 480 px no web).

---

## Componentes Reutilizáveis

| Componente | Spec |
|-----------|------|
| `PrimaryButton` | ElevatedButton, `colorPrimary`, radius 12, full-width, disabled+loading |
| `AppTextField` | TextFormField com label, errorText, radius 12, `colorSurface` |
| `AuthScaffold` | Base das telas S2/S3 (logo + form centralizado, scroll em telas pequenas) |

---

## Estados

- **Loading:** botão desabilitado + `CircularProgressIndicator` 18 px branco.
- **Erro:** mensagem inline (não snackbar) para ação clara.
- **Validação local:** e-mail regex simples `^\S+@\S+\.\S+$`; senha ≥ 6; confirmar == senha.
- **Sessão restaurada:** nenhum flash de tela de login antes do redirect do splash.

---

## Acessibilidade

- Contraste ≥ 4.5:1 (tokens acima cumprem em clear/escuro).
- Labels explícitos nos inputs; `tooltip` no toggle de visibilidade de senha.
- Alvos de toque ≥ 44 px; fonte mínima 14 px.

---

## Fora de Escopo (Fase 1)

- Recuperação de senha (reset por e-mail exige deep link — v2/fase futura)
- Magic link / OAuth social
- Onboarding, animações elaboradas
- Telas de dados (lançamentos, dashboard) — Fases 2-6

---
*Approval: pendente (checkpoint de execução — aprovado na revisão visual do plan 01-03)*