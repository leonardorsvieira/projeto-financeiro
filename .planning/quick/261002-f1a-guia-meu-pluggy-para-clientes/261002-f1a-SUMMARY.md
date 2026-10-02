---
status: complete
quick_id: 261002-f1a
date: 2026-10-02
---

# Quick 261002-f1a: guia do Meu Pluggy para clientes

Pedido: com a venda começando, um passo a passo para o cliente criar a conta no Meu Pluggy e ligar ao Meu Bolso, divulgado só por link.

- `app/web/conectar-bancos-o3um1bnu.html` → `https://leonardorsvieira.github.io/projeto-financeiro/conectar-bancos-o3um1bnu.html`. Página estática no estilo Caderneta (claro/escuro, fontes do build, sem JavaScript, CSP sem chamadas externas).
- "Não listada": nenhum link para ela no site, sufixo aleatório no nome, `robots noindex/nofollow/noarchive` e `referrer no-referrer` (o endereço não vaza ao clicar em meu.pluggy.ai). **Não é privada de verdade**: o repositório é público, então quem olhar o código acha o arquivo. O conteúdo não tem nada sigiloso.
- Conteúdo: antes de começar → Parte 1 (conta no meu.pluggy.ai) → Parte 2 ("Conectar Minha Conta", aprovar no app do banco, repetir por banco) → Parte 3 (menu ⋮ → Bancos e Open Finance → "Conectar meu.pluggy.ai" → login no Meu Pluggy → Permitir → "Sincronizar agora" / "Importar últimos 12 meses") → o que acontece depois → perguntas frequentes (pop-up bloqueado, nada sincronizado, banco faltando, duplicado manual, consentimento vencido, desconectar, privacidade).
- Rótulos do app conferidos no código (`open_finance_screen.dart`, `abrir_autorizacao.dart`, `home_screen.dart`). Fluxo do Meu Pluggy conferido em pluggy.ai/meu-pluggy e github.com/pluggyai/meu-pluggy (o cliente **não** precisa do dashboard.pluggy.ai: o conector MeuPluggy já está habilitado na aplicação do dono).
- Verificado no navegador em 375 px, claro e escuro: sem rolagem horizontal, numeração 1–12 contínua entre as partes, fontes carregadas, console sem erros.

Se os rótulos dos botões do Open Finance mudarem no app, atualizar esta página junto. A mensagem de divulgação (site + APK) foi entregue no chat, fora do repositório.
