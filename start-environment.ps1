param(
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn([string]$msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host "[-] $msg" -ForegroundColor Red }

function Test-DockerReady {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) { return $false }
    try {
        $null = docker info 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-DockerComposePlugin {
    try {
        $null = docker compose version 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

$repoRoot = $PSScriptRoot
$baseCompose = Join-Path $repoRoot 'docker-compose.yml'

Write-Step 'Checking Docker prerequisites...'
if (-not (Test-DockerReady)) {
    Write-Fail 'Docker is not ready. Start Docker Desktop and try again.'
    exit 1
}
if (-not (Test-DockerComposePlugin)) {
    Write-Fail "'docker compose' plugin not found. Update Docker Desktop."
    exit 1
}
Write-Ok 'Docker is ready.'

if (-not (Test-Path $baseCompose)) {
    Write-Fail "Compose file not found: $baseCompose"
    exit 1
}

Push-Location $repoRoot
try {
    # ── Step 1: Start postgres and libretranslate only if not already running ──
    # --no-recreate prevents "container name already in use" errors when the
    # containers exist from a previous run (even if stopped).
    $infraArgs = @('-f', $baseCompose, 'up', '-d', '--no-recreate', '--no-deps', 'postgres', 'libretranslate')
    Write-Step "Starting infrastructure services: docker compose $($infraArgs -join ' ')"
    & docker compose @infraArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "docker compose (infra) exited with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }

    # ── Step 2: Build and (re)create api and frontend ─────────────────────────
    $appArgs = @('-f', $baseCompose, 'up', '-d', '--remove-orphans', '--no-deps')
    if (-not $NoBuild) {
        $appArgs += '--build'
    }
    $appArgs += @('api', 'frontend')
    Write-Step "Starting application services: docker compose $($appArgs -join ' ')"
    & docker compose @appArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "docker compose (app) exited with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }

    # Realesrgan is no longer part of the default environment.
    # Stop/remove it if present to avoid unnecessary resource usage.
    try {
        & docker compose stop realesrgan | Out-Null
    } catch {
        # Ignore when service/container is absent.
    }
    try {
        & docker compose rm -f realesrgan | Out-Null
    } catch {
        # Ignore when service/container is absent.
    }
} finally {
    Pop-Location
}

Write-Ok 'Environment started successfully.'
Write-Host ''
Write-Host 'Endpoints:' -ForegroundColor Cyan
Write-Host '  Frontend:      http://localhost:32300'
Write-Host '  API Swagger:   http://localhost:32301/swagger'
Write-Host '  API Health:    http://localhost:32301/health/live'
Write-Host '  LibreTranslate:http://localhost:32304/languages'
Write-Host ''
# Pause so the console doesn't close immediately and the user can read output
$null = Read-Host -Prompt 'Press Enter to continue...'
