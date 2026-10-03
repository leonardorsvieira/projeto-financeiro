// Intro em vídeo da versão web (no celular ela é do próprio app:
// lib/features/intro). Toca enquanto o Flutter carrega e some com fade quando
// o vídeo acabou (ou o usuário tocou) E o app já desenhou a primeira tela
// (evento "flutter-first-frame"). Sempre muda: o navegador não deixa tocar
// som sem um toque antes. Se o navegador nem deixar tocar, fica só o fundo
// até o app abrir. Versão clara ou escura conforme o tema do app.
(function () {
  if (window.meuBolsoDesviando) return; // retorno-email.js já está saindo

  // Tema escolhido no app (shared_preferences guarda em JSON no
  // localStorage); sem escolha ("Sistema"), o tema do aparelho.
  function temaEscuro() {
    var salvo = null;
    try {
      salvo = JSON.parse(localStorage.getItem("flutter.app_theme_mode"));
    } catch (e) {}
    if (salvo === "dark") return true;
    if (salvo === "light") return false;
    return !!(window.matchMedia &&
      window.matchMedia("(prefers-color-scheme: dark)").matches);
  }

  var escuro = temaEscuro();
  var FUNDO = escuro ? "#14203A" : "#F1E8D7"; // mesmo fundo de cada vídeo
  document.body.style.background = FUNDO;
  var VIDEO_TRAVADO_MS = 10000;
  var APP_SEM_SINAL_MS = 60000;

  var capa = document.createElement("div");
  capa.id = "intro";
  capa.setAttribute("aria-hidden", "true");
  var c = capa.style;
  c.position = "fixed";
  c.inset = "0";
  c.zIndex = "2147483647";
  c.background = FUNDO;
  c.display = "flex";
  c.alignItems = "center";
  c.justifyContent = "center";
  c.transition = "opacity 0.4s ease";

  var video = document.createElement("video");
  video.muted = true;
  video.defaultMuted = true;
  video.playsInline = true;
  video.setAttribute("muted", "");
  video.setAttribute("playsinline", "");
  video.preload = "auto";
  // Asset do Flutter (pubspec), relativo ao <base href>.
  video.src = escuro
    ? "assets/assets/intro/intro_escuro.mp4"
    : "assets/assets/intro/intro.mp4";
  var v = video.style;
  v.width = "min(100vw, 100vh)";
  v.height = "min(100vw, 100vh)";
  v.objectFit = "contain";

  capa.appendChild(video);
  document.body.appendChild(capa);

  var videoAcabou = false;
  var appPronto = false;
  var saindo = false;

  function talvezSair() {
    if (saindo || !videoAcabou || !appPronto) return;
    saindo = true;
    capa.style.opacity = "0";
    capa.style.pointerEvents = "none";
    setTimeout(function () {
      video.pause();
      video.removeAttribute("src");
      video.load();
      capa.remove();
    }, 450);
  }

  function fimDoVideo() {
    videoAcabou = true;
    talvezSair();
  }

  video.addEventListener("ended", fimDoVideo);
  video.addEventListener("error", fimDoVideo);
  capa.addEventListener("click", function () {
    video.pause();
    fimDoVideo();
  });
  window.addEventListener("flutter-first-frame", function () {
    appPronto = true;
    talvezSair();
  });

  var tocando = video.play();
  if (tocando && tocando.catch) tocando.catch(fimDoVideo);

  setTimeout(fimDoVideo, VIDEO_TRAVADO_MS);
  // Se o sinal do Flutter nunca vier, a intro não prende ninguém.
  setTimeout(function () {
    appPronto = true;
    fimDoVideo();
  }, APP_SEM_SINAL_MS);
})();
