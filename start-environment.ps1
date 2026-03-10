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

function Test-NvidiaRuntime {
    try {
        $info = (docker info 2>&1) -join ' '
        return ($info -match '\bnvidia\b')
    } catch {
        return $false
    }
}

$repoRoot = $PSScriptRoot
$baseCompose = Join-Path $repoRoot 'docker-compose.yml'
$gpuCompose = Join-Path $repoRoot 'docker-compose.gpu.yml'

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

$useGpu = $false
if ((Test-Path $gpuCompose) -and (Test-NvidiaRuntime)) {
    $useGpu = $true
    Write-Ok 'NVIDIA runtime detected. Real-ESRGAN will run with GPU reservation.'
} else {
    Write-Warn 'NVIDIA runtime not detected (or GPU override file missing). Real-ESRGAN will run in auto mode with CPU fallback.'
}

$composeArgs = @('-f', $baseCompose)
if ($useGpu) {
    $composeArgs += @('-f', $gpuCompose)
}
$composeArgs += @('up', '-d')
 $composeArgs += '--remove-orphans'
if (-not $NoBuild) {
    $composeArgs += '--build'
}

Write-Step "Running: docker compose $($composeArgs -join ' ')"
Push-Location $repoRoot
try {
    & docker compose @composeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "docker compose exited with code $LASTEXITCODE"
        exit $LASTEXITCODE
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
Write-Host '  Real-ESRGAN:   http://localhost:32305/health'
