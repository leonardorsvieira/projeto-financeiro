# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Meu Bolso**

Aplicativo financeiro pessoal do Leonardo, **usado também por convidados/clientes** (cada um com a própria conta e dados isolados), usado no celular (Android e iPhone) e no navegador do PC, acessível de qualquer lugar. Registra gastos, recebimentos e investimentos — principalmente **falando**: o usuário dita o lançamento e a IA transcreve, classifica e preenche (valor, categoria, forma de pagamento, vencimento e itens detalhados). Lembra de faturas e contas a vencer, mostra um dashboard com saldo do mês, gastos por categoria e próximos vencimentos, e permite metas de gasto por categoria.

**Core Value:** O usuário pode ditar um gasto, recebimento ou investimento com a voz e ele é registrado corretamente, no lugar certo, pronto para acompanhar — sem digitação manual.

### Constraints

- **Mobile multiplataforma**: Android, iPhone e web a partir de um único código Flutter
- **IA gratuita**: a captura de voz deve usar serviço/API com tier gratuito viável (hoje: Gemini via Google AI Studio)
- **Dados sensíveis**: dados financeiros pessoais — criptografia e privacidade. O repositório GitHub é **público** e o bundle web também: nenhum segredo no código nem em `--dart-define`; nenhum usuário pode ver dados de outro
- **Acesso de qualquer lugar**: backend em nuvem (Supabase)
- **Custo**: projeto pessoal — hospedagem e serviços o mais baratos possíveis

## Commands

O app Flutter fica em `app/`; rode os comandos `flutter` a partir de lá. Scripts de build ficam na raiz. O README do projeto é `app/README.md` (não existe README na raiz).

```bash
cd app
flutter pub get
flutter analyze                     # lint (flutter_lints; build/android/ios/web excluídos)
flutter test                        # suíte inteira
flutter test test/features/ditado/data/gemini_prompt_test.dart   # um arquivo
flutter test --plain-name "trecho do nome do teste"               # um teste pelo nome
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

- **APK Android:** na raiz, `.\build_apk.ps1` (debug) ou `.\build_apk.ps1 -Mode release [-OutDir <pasta>]`. Lê as chaves do `.env` da raiz (modelo em `.env.example`). O APK pode sair em `C:\build\meubolso\...` em vez de `app\build\...` — o script verifica os dois.
- **Web:** push na `main` que toque `app/**` publica no GitHub Pages (`.github/workflows/deploy.yml`, `--base-href=/projeto-financeiro/`, chaves vindas dos secrets do repositório; `404.html` é cópia do `index.html` para o fallback da SPA). Republicar sem commit: `gh workflow run deploy.yml` (não use "re-run" do mesmo run: duplica o artefato `github-pages`). O link de confirmação de cadastro termina em `web/confirmado.html` (Site URL do Supabase Auth); `web/retorno-email.js` roda antes do Flutter e desvia para lá qualquer retorno (`?code=`, `#access_token=`, `error_code=`) — o app web nunca deve abrir a partir de um link de e-mail.
- **iOS:** `.github/workflows/build-ios.yml`.
- **Banco:** migrations SQL em `supabase/migrations/` (projeto Supabase `tkfhthotspehsgvmpsjm`, região `sa-east-1`). O nome do arquivo deve casar com a versão registrada no projeto remoto.
- **Edge Functions:** `supabase/functions/{ditado,indicadores,pluggy,excluir-conta}` + `_shared/seguranca.ts` (Deno). Deploy com `supabase functions deploy <nome> --use-api` (ou MCP), sempre com verificação de JWT. `ditado` aceita só os modelos `gemini-3.5-flash-lite`, `gemini-3.5-flash` e `gemini-3.1-flash-lite` (os 2.x não servem: o 2.5 ficou restrito a quem já o usava e responde 404 para esta chave; mantenha em sincronia com `GeminiCliente`) e só a ferramenta `google_search`, que ela **só repassa ao Gemini com o segredo `BUSCA_GOOGLE=1`** — no plano gratuito (o atual) a Busca Google não existe para os modelos 3.x e responde 429; ligue só com faturamento. O pedido do guia (o que traz `tools`) tem cota própria `consultoria` (`LIMITE_DIARIO_CONSULTORIA`, padrão 10/dia, conferida antes e consumida só quando o Gemini responde) e tempo de 80 s. `indicadores` devolve meta Selic (histórico do Copom em `www.bcb.gov.br/api/servico/sitebcb/historicotaxasjuros`), Focus e PTAX (Olinda) e IPCA 12 meses (SIDRA/IBGE); o SGS `api.bcb.gov.br` saiu do DNS em 2026. Cada indicador falha sozinho (null). `excluir-conta` apaga o usuário do JWT (LGPD): desconecta os itens Pluggy e deleta em `auth.users` (tabelas em cascata). Exceções sem JWT (`--no-verify-jwt`): `pluggy-webhook` (chamado pela Pluggy) e `atualizar-bancos` — autenticada pelo cabeçalho `x-cron-secret` com um segredo gerado no Vault (`cron_atualizar_bancos`, conferido pela RPC `cron_atualizar_bancos_confere`, só service role; nunca no repo). Ela pede `PATCH /items/{id}` às conexões de quem tem acesso ativo e loga, sem ids nem valores, `lastUpdatedAt`/`nextAutoSyncAt` de cada uma. **Agendamento desligado** (migration `20261003171809`): todas as conexões são Meu Pluggy, que **não aceitam** o PATCH ("MeuPluggy item cant be updated") — a Pluggy as sincroniza sozinha a cada 24 h, contadas da última atualização de cada conexão (não há horário fixo). Religar (só faz sentido com conexões diretas/plano pago): repetir o `cron.schedule` da migration `20261003162629`. Diagnóstico manual: `net.http_post` com o segredo do Vault e `{"somente_usuario": <uuid>}`.
- **APK comercial:** assinado com `app/android/key.properties` + `.jks` (fora do git; modelo em `key.properties.example`). Sem eles o release sai com a chave de debug. Documentos legais e dados do controlador (CNPJ, e-mail) em `app/lib/features/privacidade/domain/`; mudar `versaoDocumentos` pede novo aceite de todos.
- **CI:** `.github/workflows/secret-scan.yml` roda gitleaks em todo push/PR.

## Configuração / segredos

Não existe leitura de `.env` em runtime: `SUPABASE_URL`/`SUPABASE_ANON_KEY` (públicas) entram em **tempo de compilação** via `--dart-define` (`app/lib/core/env.dart`). Sem elas o app sobe, mas não inicializa o Supabase (só um aviso no log).

**Nunca** coloque chave secreta no app nem em `--dart-define`: o repo e o bundle web são públicos. Segredos (`GEMINI_API_KEY`, `PLUGGY_CLIENT_ID`, `PLUGGY_CLIENT_SECRET`, opcionais `OWNER_USER_ID`, `ALLOWED_ORIGINS`, `LIMITE_DIARIO_*`) ficam em `supabase secrets` e só as Edge Functions os leem.

## Architecture

**Feature-first + camadas.** Cada pasta em `app/lib/features/<feature>/` segue `domain/` (modelos + interfaces de repositório) → `data/` (implementações: Supabase, HTTP, SharedPreferences) → `application/` (providers/Notifiers Riverpod, serviços) → `presentation/` (telas e widgets). Código e nomes em **português** (ex.: `lancamentos`, `rascunho`, `reconhecer`, `vencimento`).

**Estado e injeção de dependência: Riverpod 3.** Todo repositório é exposto por um `Provider` (ex.: `lancamentosRepositoryProvider`, `ditadoRepositoryProvider`, `audioRecorderServiceProvider`), e os testes trocam essas implementações por fakes via `ProviderScope(overrides: [...])`. Até o relógio é injetável (`ditadoRelogioProvider`). Ao criar um repositório/serviço novo, exponha-o por provider para manter isso testável. Não há geração de código (sem `build_runner`, `riverpod_generator`, `freezed` ou `json_serializable`): providers, modelos e `fromJson`/`toJson` são escritos à mão — siga esse padrão em vez de adicionar anotações `@riverpod`.

**Inicialização e isolamento de sessão** (`app/lib/main.dart`): `_SessaoIsolada` cria o `ProviderContainer` (`UncontrolledProviderScope`) e inicia o `lembretesControllerProvider` (notificações locais, só Android/iOS). Quando o usuário sai, a sessão expira ou outra conta entra, ela chama `limparDadosLocais()` (SharedPreferences, notificações agendadas, widget) e **recria o container inteiro** — os providers de dados não dependem do usuário, então é isso que impede dados de uma conta aparecerem para outra no mesmo aparelho. O `BiometricLockWrapper` envolve todo o app via `MaterialApp.router(builder:)`. Locale fixo `pt_BR`.

**Navegação** (`app/lib/router/app_router.dart`): `GoRouter` num provider, com `refreshListenable` ligado ao `authControllerProvider` para redirecionar login/logout. Constantes de rota em `features/home/domain/app_routes.dart`. As telas de confirmação do ditado recebem o rascunho por `state.extra` (`RascunhoLancamento`), não pela URL.

**Fluxo de voz (núcleo do produto)** — `features/ditado/`:
`DitadoController` (máquina de estados selada: `Idle → Gravando → Processando → Sucesso|Erro`) grava via `AudioRecorderService` (pacote `record`; leitura do arquivo tem implementações condicionais `_io`/`_web`/`_stub`), descarta gravações < 500 ms, e envia o áudio ao `GeminiDitadoRepository`, que manda `{modelo, corpo}` para a Edge Function `ditado` (via `core/edge_function.dart`, com o JWT do usuário); a função confere login + e-mail confirmado, aplica cota diária (`consumir_cota`), valida o modelo numa allowlist e repassa ao `generateContent` do Gemini com o prompt de `gemini_prompt.dart`. O cliente (`GeminiCliente`, também usado pela análise do mês e pelo guia) tem retry em 429/5xx e **fallback por uma lista de modelos candidatos** (o 429 `limite_diario` da função não é repetido). O resultado vira um rascunho que o usuário revisa numa tela de confirmação antes de salvar em `lancamentos` (o ditado não registra investimentos).

**Análise do mês e Guia de investimentos (IA):** a análise manda ao Gemini só o texto de `dadosAnaliseDoMes` (números do mês selecionado, **em reais** — nunca interpole objetos ou centavos crus no prompt: a IA lia centavos como reais); o card é recriado a cada mês. O guia (`features/consultoria/`) é **conteúdo educativo, não recomendação** (Termos seção 5; recomendação individual de valores mobiliários exige registro na CVM): o prompt de `consultoria_prompt.dart` proíbe "compre/venda", preço-alvo e promessa de rentabilidade — mantenha isso. Dados de mercado: `IndicadoresMercado` da Edge Function `indicadores`, buscados antes de cada guia (o guia sai mesmo sem eles); o pedido leva `tools: [{google_search: {}}]`, mas a busca só acontece com `BUSCA_GOOGLE=1` — o prompt manda não inventar dados de hoje sem ela. Recebe só totais/médias (`DadosConsultoria.paraPrompt`, sem descrições de lançamentos) e o perfil escolhido; o guia fica só na memória (`guiaInvestimentosProvider`).

**Onde os dados moram — dois lugares diferentes:**
- **Supabase (Postgres, RLS por `auth.uid() = user_id` em todas as tabelas):** `lancamentos` (despesa/receita via coluna `tipo`, itens e recorrência), `metas`, `investimentos`, `cartoes` (cartões de crédito do usuário; sem cartões padrão — a pergunta "quais cartões você usa?" fica em `user_metadata.cartoes_perguntado`). `user_id` tem default `auth.uid()`. Tabelas só de servidor: `pluggy_items` (dono de cada conexão Pluggy; cliente só lê as próprias) e `uso_diario` (cotas; sem acesso do cliente). O papel `anon` não tem privilégio nenhum no schema `public`.
- **Local no dispositivo (`SharedPreferences`), não sincronizado:** contas conectadas do Open Finance (só metadados, sem credenciais), preferências de lembrete, biometria, tema e partes de investimentos. Tudo é apagado no logout. Mudar isso para o Supabase exige migration nova.

**Open Finance (Pluggy) — isolamento entre usuários:** a conta Pluggy é única e compartilhada, então o isolamento é feito pela Edge Function `pluggy`: o `PluggyOpenFinanceService` manda `{metodo, caminho, corpo}` e a função só repassa rotas de uma allowlist, injeta `clientUserId = auth.uid()` em connect tokens/items e só devolve items/contas/transações cujo item está em `pluggy_items` para aquele usuário. Nunca chame `api.pluggy.ai` direto do app. Transações usam `GET /v2/transactions` (cursor `next`/`after`); o `/transactions` antigo responde 410 para a aplicação Pluggy atual. O botão "Sincronizar agora" sincroniza (30 dias na 1ª vez, depois 7) e, quando termina, importa os últimos 12 meses (`importarHistorico12Meses`, sem refazer os investimentos; falha nele não desfaz a sincronização) — não há botão separado de histórico. Importação automática: `SincronizacaoAutomatica` (app aberto: ao entrar, a cada 30 min e ao voltar ao app) + Edge Function `pluggy-webhook` (sem JWT; não confia no payload, confere dono em `pluggy_items` e grava via service role). No plano grátis da Pluggy items só nascem pelo widget Connect (`POST /items` → 400 `CREATE_ITEMS_API_FREE_DISABLED`) e a Pluggy não deixa listar items (`GET /items` → 401): o app nunca recebe o id do item novo, então é o `item/created` do webhook que o registra em `pluggy_items`, pelo `clientUserId` lido na própria Pluggy. Dedup por `obs = 'pluggy_id:<tx>'` com índice único parcial `lancamentos_pluggy_unico` — trate `23505` como "já importada".

**Integrações HTTP externas:** Gemini, Pluggy e os indicadores do Banco Central/IBGE só via Edge Functions; o app não chama nenhuma outra API externa. A web tem CSP em `app/web/index.html` — um domínio novo chamado pelo app precisa entrar no `connect-src`.

**Importação Pluggy — regras de dinheiro:** no **cartão de crédito** o sinal é invertido (positivo = compra/saída, negativo = estorno); pagamento de fatura é ignorado (as compras já vêm pelo cartão). Transferências entre contas do próprio titular (categoria "mesma titularidade", contraparte com CPF/nome do titular, ou um nome que o usuário marcou como conta dele — `user_metadata.contas_proprias`, via "Transferência entre minhas contas" → "Sempre" no formulário) e aplicação/resgate de investimento viram as **categorias neutras** `Transferência entre contas` / `Investimento (aplicação/resgate)` (`categoriasNeutras` em `lancamento.dart`), que aparecem na lista mas não contam como entrada/saída. Exceção: aplicação/resgate entram no **saldo do mês** como no extrato (resgate soma, aplicação subtrai — `resumoDoMes` em `dashboard_providers.dart`, linha própria no card; `investimentosCents` nos relatórios), nunca em receitas/despesas, donut, metas ou patrimônio. Recarga de celular nunca é neutra (vira `Assinaturas`). Compra parcelada no cartão grava o número da parcela na descrição (`descricaoComParcela`: "MERCADOLIVRE (2/8)", via `creditCardMetadata`); a sincronização renomeia importados antigos que ainda têm a descrição do banco. Regras duplicadas em `pluggy_open_finance_service.dart` (`ehEntrada`, `ehPagamentoDeFatura`, `categoriaNeutra`, `descricaoComParcela`) e em `supabase/functions/pluggy-webhook` — mude os dois juntos. **Estorno de cartão** (entrada com forma "Cartão…", `Lancamento.ehEstornoDeCartao`) continua `tipo = receita` no banco, mas abate as despesas em todo cálculo (`valorDespesaCents`): fora das receitas, diminui saídas, categoria, metas e o cartão no painel.

**Patrimônio (investimentos) só vem do Open Finance:** a tela é só leitura (sem cadastro, edição, movimentos, proventos ou cotações manuais; a Pluggy só entrega compra/venda como transação de investimento, então não há calendário de proventos). No fim de cada sincronização Pluggy, `buscarInvestimentos` (rota `/investments` da função `pluggy`) + `InvestimentosRepository.sincronizarOpenFinance` espelham as posições por `investimentos.pluggy_id`; resgatados somem, e ativos sem `pluggy_id` (legado manual) são apagados assim que vier algum investimento. Rendimento = valor atual − `valor_investido_cents` (`amountOriginal` da Pluggy, ou `amount − amountProfit`); sem esse dado o ativo fica fora do rendimento (`ResumoRendimentos`: totais, ranking, maior ganho/perda).

**Dashboard/relatórios** derivam receitas/despesas de `lancamentosContabeisProvider` (lançamentos sem as categorias neutras) e do stream de `investimentos` via providers (`dashboard_providers.dart`, `relatorios_providers.dart`); gráficos com `fl_chart`, PDF com `pdf`/`printing`, widget de tela inicial com `home_widget`. Donut, metas e próximos vencimentos consideram só `tipo = despesa`. Formas de pagamento dependem dos cartões de cada usuário: use `formasPagamentoProvider` e as regras de `cartoes/domain/formas_pagamento.dart` (nunca uma lista fixa); o painel por forma de pagamento usa `agruparPorFormaPagamento` (Pix + débito em conta juntos, cada cartão separado, nunca atribui gasto a um cartão que não é o dele). Cartão do Open Finance entra pela **fatura que vence no mês** (`faturasDoMes` em `open_finance/domain/fatura_cartao.dart`): fechada = `totalAmount` de `GET /bills` (buscado na sincronização e guardado em `ContaBancariaConectada.cartoes`); a seguinte à última fechada = a do banco (`faturaAbertaDasTransacoes`: transações do cartão ainda sem `creditCardMetadata.billId`, antes do próximo vencimento, sem pagamento de fatura; em `CartaoOpenFinance.faturaAbertaCents`) ou, se o banco não informa `billId`, a estimativa por compras − estornos importados desde o fechamento (sem data de fechamento na Pluggy: vencimento − 7 dias); sem fatura no mês, soma as compras do mês. O `balance` de cartão Open Finance é o limite usado (inclui parcelas futuras), nunca a fatura. O cartão casa com as compras pelos dois rótulos de importação (app: `nomeBancoDaConta`; webhook: nome da conta no Meu Pluggy ou o do conector). **Patrimônio** (relatórios/PDF) = saldo das contas + investimentos − faturas em aberto (`saldoContasCents`/`faturaCartoesCents` da última sincronização, em `ContaBancariaConectada`), e a evolução é reconstruída para trás a partir desse valor (`evolucaoPatrimonialPorMes`); nunca some entradas − saídas do histórico com os investimentos (conta o mesmo dinheiro duas vezes). Sem banco conectado, a tela mostra só "Saldo acumulado" do período. O card **"Saldo nas contas"** (topo do Resumo, `saldoNasContasProvider`) soma o `saldoContasCents` de cada conexão, sem faturas, com a data da atualização mais antiga — é o número que o cliente compara com o app do banco (o "Saldo do mês" é só o fluxo do mês).

## Testes

`app/test/` espelha `lib/features/`. Fakes reutilizáveis em `app/test/support/` (`fake_*_repository.dart`, `fake_auth.dart`, `fake_ditado_providers.dart`); `wrapWithFakes(...)` em `fake_wrappers.dart` monta o `ProviderScope` com overrides para testes de widget. Testes de repositórios HTTP (Gemini, Pluggy, cotações) injetam um `http.Client` falso pelo construtor.

## Conventions

- Mensagens de commit no estilo Conventional Commits, em português, com escopo opcional: `feat(open-finance): ...`, `fix(ui): ...`, `docs: ...`, `chore: ...`.
- Planejamento GSD vive em `.planning/` (`STATE.md`, `ROADMAP.md`, `phases/`); `docs:` commits geralmente atualizam esses arquivos.

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
