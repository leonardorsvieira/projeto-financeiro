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
| `GEMINI_API_KEY`    | Chave de API do Google AI Studio   |

## Como rodar

```bash
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=GEMINI_API_KEY=...
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
