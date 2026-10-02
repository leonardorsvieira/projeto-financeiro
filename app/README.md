# Meu Bolso

Aplicativo financeiro pessoal (Android, iPhone e web) para registrar gastos,
recebimentos e investimentos — principalmente **por voz**: você dita o
lançamento e a IA transcreve, classifica e preenche valor, categoria, forma de
pagamento, vencimento e itens.

Também lembra de faturas e contas a vencer, mostra um dashboard com saldo do
mês, gastos por categoria e próximos vencimentos, e permite definir metas de
gasto por categoria.

## Stack

- **Flutter** (Dart) — app mobile e web
- **Riverpod** — gerenciamento de estado
- **go_router** — navegação
- **Supabase** — autenticação e banco de dados (migrations em `../supabase/migrations`)
- **Gemini (Google AI Studio)** — transcrição e classificação dos ditados

## Configuração

As chaves são injetadas em tempo de compilação via `--dart-define`
(veja `lib/core/env.dart`). Copie o `.env.example` da raiz do repositório para
`.env` e preencha:

| Variável            | Descrição                          |
| ------------------- | ---------------------------------- |
| `SUPABASE_URL`      | URL do projeto Supabase            |
| `SUPABASE_ANON_KEY` | Chave anon do Supabase             |

Tudo que entra via `--dart-define` fica legível no bundle web publicado, então
**nenhuma chave secreta vai para o app**. As chaves do Gemini e da Pluggy ficam
nas Edge Functions (`supabase/functions/ditado` e `supabase/functions/pluggy`):

```bash
supabase secrets set GEMINI_API_KEY=... PLUGGY_CLIENT_ID=... PLUGGY_CLIENT_SECRET=...
```

Opcionais: `OWNER_USER_ID` (uuid que pode reivindicar items Pluggy criados antes
do proxy), `ALLOWED_ORIGINS` (origens web extras para CORS),
`LIMITE_DIARIO_DITADO` (padrão 150) e `LIMITE_DIARIO_PLUGGY` (padrão 3000).

## Controle de acesso (assinatura)

O Meu Bolso é liberado à mão, pelo e-mail. Quem está na tabela `acessos` com a
validade em dia (ou sem prazo, `valido_ate` nulo) usa o app. Quem está em
`administradores` passa direto e gerencia a lista no menu **Clientes e
acessos** (adicionar, editar, renovar +30 dias, bloquear e remover).

Com o acesso vencido a conta só consulta e exporta os próprios dados e pode
excluir a conta; não grava nada. Quem garante isso é o servidor (policies
`RESTRICTIVE` em `lancamentos`, `metas` e `investimentos` + checagem nas Edge
Functions `ditado`, `pluggy` e `pluggy-webhook`). A tela "Seu acesso não está
ativo" do app é só a parte visível.

Para tornar alguém administrador (SQL, no Dashboard do Supabase; nunca grave
e-mails reais no repositório):

```sql
insert into public.administradores (user_id)
select id from auth.users where email = '<e-mail-do-dono>';
```

**Hook de cadastro (opcional):** barra já no cadastro e-mails sem acesso. No
Dashboard, Authentication → Hooks → Before User Created → tipo Postgres →
`public.hook_antes_de_criar_usuario`. Sem o hook tudo funciona igual, só que a
pessoa consegue criar a conta e cai na tela sem acesso.

**Ordem de implantação:**

1. Aplicar a migration `20261001220000_controle_de_acesso.sql`.
2. Na mesma sessão, fazer o seed por SQL (o dono em `administradores` e as
   contas que já existem em `acessos`); senão todo mundo perde a escrita.
3. Só então publicar `ditado`, `pluggy` e `pluggy-webhook` (todas importam
   `_shared/seguranca.ts`; publicar antes da migration devolve 503 a todos).

## Como rodar

```bash
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## Testes

```bash
cd app
flutter test
```

## Build

- **APK Android:** na raiz do repositório, rode `.\build_apk.ps1` (debug) ou
  `.\build_apk.ps1 -Mode release`. O script lê as chaves do `.env`.
- **Web:** cada push na `main` que altera `app/**` publica o app no GitHub Pages
  (`.github/workflows/deploy.yml`).
- **iOS:** build via `.github/workflows/build-ios.yml`.
