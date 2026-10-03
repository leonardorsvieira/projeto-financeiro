// Retorno do link de confirmação de e-mail (Supabase Auth) NUNCA abre o app.
//
// Um link de cadastro pode voltar para a raiz do site com ?code=..., com
// #access_token=... ou com ?error=...&error_code=otp_expired (e-mails antigos,
// versões em cache do site). Se o app carregasse, mostraria a sessão que já
// estiver salva NESTE navegador (por exemplo a do dono, num computador
// compartilhado). Este script roda antes do Flutter e desvia para a página
// "Cadastro confirmado", sem levar códigos nem tokens.
(function () {
  var busca = new URLSearchParams(window.location.search);
  var fragmento = new URLSearchParams(
    window.location.hash.replace(/^#\/?/, "")
  );
  var temRetorno = ["code", "access_token", "error", "error_code"].some(
    function (chave) {
      return busca.has(chave) || fragmento.has(chave);
    }
  );
  if (!temRetorno) return;

  var erro =
    busca.get("error_code") || fragmento.get("error_code") ||
    busca.get("error") || fragmento.get("error");
  window.meuBolsoDesviando = true; // intro.js não toca a intro
  // Relativo ao <base href>: funciona em /projeto-financeiro/ e localmente.
  window.location.replace(
    "confirmado.html" + (erro ? "#error_code=" + encodeURIComponent(erro) : "")
  );
})();
