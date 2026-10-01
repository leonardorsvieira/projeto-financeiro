# criar_chave_assinatura.ps1 — cria a chave de assinatura de produção do APK.
#
# Uso (uma vez só, na raiz do projeto):
#   powershell -ExecutionPolicy Bypass -File .\criar_chave_assinatura.ps1
#
# Pede a senha duas vezes (ela não aparece na tela), gera
# app\android\meubolso-producao.jks e escreve app\android\key.properties.
# Os dois ficam fora do git (app\android\.gitignore). Nunca sobrescreve uma
# chave existente: trocar a chave impede atualizar o app já instalado.

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$android = Join-Path $root "app\android"
$jks = Join-Path $android "meubolso-producao.jks"
$props = Join-Path $android "key.properties"
$alias = "meubolso"

if ((Test-Path $jks) -or (Test-Path $props)) {
  Write-Host "Ja existe uma chave ou key.properties em $android. Nada foi alterado." -ForegroundColor Yellow
  exit 1
}

$keytool = Join-Path $env:ProgramFiles "Android\Android Studio\jbr\bin\keytool.exe"
if (-not (Test-Path $keytool)) {
  $cmd = Get-Command keytool -ErrorAction SilentlyContinue
  if (-not $cmd) {
    Write-Host "keytool nao encontrado (instale o Android Studio)." -ForegroundColor Red
    exit 1
  }
  $keytool = $cmd.Source
}

function Ler-Senha([string]$rotulo) {
  $seguro = Read-Host -Prompt $rotulo -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($seguro)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

Write-Host "==> Chave de assinatura do Meu Bolso" -ForegroundColor Cyan
Write-Host "Escolha uma senha forte (minimo 8 caracteres, sem acentos)."
Write-Host "Guarde-a num gerenciador de senhas: sem ela nao da para atualizar o app."
while ($true) {
  $senha = Ler-Senha "Senha"
  $confirmacao = Ler-Senha "Repita a senha"
  if ($senha -ne $confirmacao) { Write-Host "As senhas nao conferem. Tente de novo." -ForegroundColor Yellow; continue }
  if ($senha.Length -lt 8) { Write-Host "Use pelo menos 8 caracteres." -ForegroundColor Yellow; continue }
  # key.properties é lido como ISO-8859-1 pelo Gradle: aceita só ASCII visível.
  if ($senha -notmatch '^[\x21-\x7E]+$') { Write-Host "Use apenas letras sem acento, numeros e simbolos (sem espacos)." -ForegroundColor Yellow; continue }
  break
}

& $keytool -genkeypair -v -keystore $jks -storetype PKCS12 -alias $alias `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -dname "CN=Meu Bolso, OU=CNPJ 68.018.160/0001-00, C=BR" `
  -storepass $senha -keypass $senha 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jks)) {
  Write-Host "keytool falhou; nenhuma chave foi criada." -ForegroundColor Red
  exit 1
}

# Escapa a barra invertida (formato .properties).
$senhaProps = $senha.Replace('\', '\\')
$conteudo = @(
  "storeFile=meubolso-producao.jks",
  "storePassword=$senhaProps",
  "keyAlias=$alias",
  "keyPassword=$senhaProps"
)
[IO.File]::WriteAllLines($props, $conteudo, (New-Object Text.ASCIIEncoding))
$senha = $null; $confirmacao = $null; $senhaProps = $null; $conteudo = $null

& $keytool -list -keystore $jks -storetype PKCS12 -alias $alias `
  -storepass (Get-Content $props | Where-Object { $_ -like "storePassword=*" }).Substring(14).Replace('\\', '\') 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "A chave foi criada, mas a conferencia falhou. Avise antes de gerar o APK." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "OK: chave criada e conferida." -ForegroundColor Green
Write-Host "    $jks"
Write-Host "    $props"
Write-Host ""
Write-Host "IMPORTANTE: copie meubolso-producao.jks para um pendrive ou nuvem privada" -ForegroundColor Yellow
Write-Host "e guarde a senha num gerenciador de senhas. Se perder os dois, nao da" -ForegroundColor Yellow
Write-Host "para publicar atualizacoes do app." -ForegroundColor Yellow
