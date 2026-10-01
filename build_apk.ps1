param(
  [ValidateSet("debug", "release")]
  [string]$Mode = "debug",
  [string]$OutDir = "",
  # Ex.: "android-arm64,android-x64" (sem o arm 32 bits). Vazio = todas.
  [string]$Plataformas = ""
)

# build_apk.ps1 — gera o APK do Meu Bolso com as defines do .env embutidas.
# Uso:
#   .\build_apk.ps1                  (debug)
#   .\build_apk.ps1 -Mode release    (release)
#   .\build_apk.ps1 -OutDir "C:\seu\caminho"   (copia o APK para um destino)
#   .\build_apk.ps1 -Mode release -Plataformas "android-arm64,android-x64"
#       (só 64 bits: quando o Controle Inteligente de Aplicativos do Windows
#        bloqueia o gen_snapshot do arm 32 bits)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$envPath = Join-Path $root ".env"

if (-not (Test-Path $envPath)) {
  Write-Host "ERRO: $envPath nao encontrado. Crie o .env baseado no .env.example." -ForegroundColor Red
  exit 1
}

function Read-Env([string]$key) {
  $line = Get-Content $envPath | Where-Object { $_ -match "^$key=" } | Select-Object -First 1
  if (-not $line) { return "" }
  return $line.Substring($line.IndexOf("=") + 1).Trim()
}

$supabaseUrl = Read-Env "SUPABASE_URL"
$supabaseAnonKey = Read-Env "SUPABASE_ANON_KEY"

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
  Write-Host "ERRO: SUPABASE_URL/SUPABASE_ANON_KEY em branco no .env." -ForegroundColor Red
  exit 1
}

$keyProps = Join-Path $root "app\android\key.properties"
if ($Mode -eq "release" -and -not (Test-Path $keyProps)) {
  Write-Host "AVISO: sem app\android\key.properties o release sai com a chave de DEBUG (so para testes, nao para distribuir)." -ForegroundColor Yellow
}

Write-Host "==> Meu Bolso: build $Mode APK" -ForegroundColor Cyan
Write-Host "    SUPABASE_URL  : $supabaseUrl"
Write-Host "    SUPABASE_ANON : $($supabaseAnonKey.Substring(0, 12))..."

$inicio = Get-Date

Push-Location (Join-Path $root "app")
try {
  $flutterArgs = @(
    "build", "apk", "--$Mode",
    "--dart-define=SUPABASE_URL=$supabaseUrl",
    "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"
  )
  if ($Plataformas) { $flutterArgs += "--target-platform=$Plataformas" }

  # flutter é um .bat; cmd /c evita que o stderr (warnings nativos do Gradle)
  # seja tratado como erro pelo $ErrorActionPreference = "Stop".
  $flutterCmd = "flutter $($flutterArgs -join ' ') 2>&1"
  & cmd /c $flutterCmd
  $exitCode = $LASTEXITCODE
}
finally {
  Pop-Location
}

$externalApk = Join-Path "C:\build\meubolso\app\outputs\flutter-apk" "app-$Mode.apk"
$apk = Join-Path $root "app\build\app\outputs\flutter-apk\app-$Mode.apk"
if (Test-Path $externalApk) { $apk = $externalApk }

# Com a pasta de build externa o Flutter sai com erro mesmo quando gera o APK,
# então vale o arquivo: ele precisa ter sido escrito por ESTE build (um APK
# antigo na pasta não conta).
if (-not (Test-Path $apk) -or (Get-Item $apk).LastWriteTime -lt $inicio) {
  Write-Host "ERRO: o build nao gerou um APK novo (exit $exitCode). Veja o log acima." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "OK: $apk" -ForegroundColor Green
Write-Host "    $([math]::Round((Get-Item $apk).Length / 1MB, 1)) MB"

if ($OutDir) {
  if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
  $dest = Join-Path $OutDir "meubolso-$Mode.apk"
  Copy-Item $apk $dest -Force
  Write-Host "    Copiado para: $dest" -ForegroundColor Green
}