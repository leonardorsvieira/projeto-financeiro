param(
  [ValidateSet("debug", "release")]
  [string]$Mode = "debug",
  [string]$OutDir = ""
)

# build_apk.ps1 — gera o APK do Meu Bolso com as defines do .env embutidas.
# Uso:
#   .\build_apk.ps1                  (debug)
#   .\build_apk.ps1 -Mode release    (release)
#   .\build_apk.ps1 -OutDir "C:\seu\caminho"   (copia o APK para um destino)

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
$geminiKey = Read-Env "GEMINI_API_KEY"

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
  Write-Host "ERRO: SUPABASE_URL/SUPABASE_ANON_KEY em branco no .env." -ForegroundColor Red
  exit 1
}

Write-Host "==> Meu Bolso: build $Mode APK" -ForegroundColor Cyan
Write-Host "    SUPABASE_URL  : $supabaseUrl"
Write-Host "    SUPABASE_ANON : $($supabaseAnonKey.Substring(0, 12))..."
if (-not [string]::IsNullOrWhiteSpace($geminiKey)) {
  Write-Host "    GEMINI_API_KEY: $($geminiKey.Substring(0, 8))..."
}

Push-Location (Join-Path $root "app")
try {
  $flutterArgs = @(
    "build", "apk", "--$Mode",
    "--dart-define=SUPABASE_URL=$supabaseUrl",
    "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"
  )
  if (-not [string]::IsNullOrWhiteSpace($geminiKey)) {
    $flutterArgs += "--dart-define=GEMINI_API_KEY=$geminiKey"
  }

  # flutter é um .bat; cmd /c evita que o stderr (warnings nativos do Gradle)
  # seja tratado como erro pelo $ErrorActionPreference = "Stop".
  $flutterCmd = "flutter $($flutterArgs -join ' ') 2>&1"
  & cmd /c $flutterCmd
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) { throw "flutter build falhou (exit $exitCode)" }
}
finally {
  Pop-Location
}

$externalApk = Join-Path "C:\build\meubolso\app\outputs\flutter-apk" "app-$Mode.apk"
$apk = Join-Path $root "app\build\app\outputs\flutter-apk\app-$Mode.apk"
if (Test-Path $externalApk) { $apk = $externalApk }

if (-not (Test-Path $apk)) {
  Write-Host "AVISO: APK nao encontrado em $apk" -ForegroundColor Yellow
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