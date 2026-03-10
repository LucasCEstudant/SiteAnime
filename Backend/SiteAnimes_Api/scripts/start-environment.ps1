<#
.SYNOPSIS
    Start the AnimeHub development environment (SQL Server, LibreTranslate, API, Real-ESRGAN).

.DESCRIPTION
    - Checks Docker prerequisites (CLI + daemon).
    - Detects existing services on ports 1433, 5000, 7118, 8000.
    - LibreTranslate is started via imagem oficial (libretranslate/libretranslate),
      gerenciado pelo start-environment.bat antes deste script.
    - Starts/recreates core stack services from docker-compose.deploy.yml.
    - Always recreates the API container to pick up the latest code.
    - Detects NVIDIA GPU and configures Real-ESRGAN for GPU or CPU mode.
    - Shows a clear summary with endpoints and log commands.

.PARAMETER LibreTimeoutSec
    Maximum seconds to wait for LibreTranslate to become ready. Default: 600 (10 min).

.PARAMETER ApiTimeoutSec
    Maximum seconds to wait for the API to become ready. Default: 120 (2 min).

.NOTES
    Compatible with PowerShell 5.1 (Windows PowerShell) and PowerShell 7+.
    No ternary operators, no if-as-expression, no pipeline chains.
    LibreTranslate runs from the official Docker Hub image (no submodule needed).
#>

param(
    [int]$LibreTimeoutSec = 600,
    [int]$ApiTimeoutSec   = 120
)

$ErrorActionPreference = 'Stop'

# -- Configuration -------------------------------------------------------
$SqlPort          = 1433
$LibrePort        = 5000
$ApiPort          = 7118
$SqlContainer     = 'sqlserver-animehub'
$LibreContainer   = 'libretranslate'
$ApiContainer     = 'animehub-api'
$LibreHealthUrl   = "http://localhost:${LibrePort}/languages"
$ApiHealthUrl     = "http://localhost:${ApiPort}/health/live"
$LibreUid         = 1032
$LibreGid         = 1032
$VolumeName       = 'libretranslate_models'
$MaxPermFixRetries = 2

# -- Output helpers -------------------------------------------------------
function Write-Step  ([string]$msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Ok    ([string]$msg) { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn  ([string]$msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Fail  ([string]$msg) { Write-Host "[-] $msg" -ForegroundColor Red }

# -- Functions ------------------------------------------------------------

function Test-DockerReady {
    <# Returns $true if docker CLI exists AND daemon responds. #>
    $cli = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $cli) { return $false }
    try {
        $null = docker info 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Get-ComposeCommand {
    <# Returns 'plugin' if 'docker compose' works, 'standalone' if 'docker-compose' works, or $null. #>
    try {
        $null = docker compose version 2>&1
        if ($LASTEXITCODE -eq 0) { return 'plugin' }
    } catch { }
    try {
        $null = & docker-compose version 2>&1
        if ($LASTEXITCODE -eq 0) { return 'standalone' }
    } catch { }
    return $null
}

function Test-PortUsedByDocker ([int]$port) {
    <# Returns $true if any running Docker container publishes the given host port. #>
    $lines = docker ps --format '{{.Ports}}' 2>$null
    if (-not $lines) { return $false }
    foreach ($line in $lines) {
        if ($line -match "0\.0\.0\.0:${port}->" -or $line -match ":::${port}->") {
            return $true
        }
    }
    return $false
}

function Test-PortListening ([int]$port) {
    <# Returns $true if anything (Docker or not) is listening on the port. #>
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($conn) { return $true }
    } catch { }
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect('127.0.0.1', $port)
        $tcp.Close()
        return $true
    } catch {
        return $false
    }
}

function Test-ContainerRunning ([string]$name) {
    $out = docker ps --filter "name=^${name}$" --format '{{.Names}}' 2>$null
    if ($out -and ($out.Trim() -eq $name)) { return $true }
    return $false
}

function Test-ContainerRestarting ([string]$name) {
    try {
        $out = docker inspect --format '{{.State.Status}}' $name 2>$null
        if ($LASTEXITCODE -eq 0 -and $out -eq 'restarting') { return $true }
    } catch { }
    return $false
}

function Test-Wsl2Available {
    <# Returns $true if WSL 2 is available on the host. #>
    $cmd = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    try {
        $null = wsl --status 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch { return $false }
}

function Test-NvidiaGpuOnHost {
    <# Returns $true if nvidia-smi runs successfully on the host. #>
    $cmd = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    try {
        $null = nvidia-smi 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch { return $false }
}

function Test-DockerNvidiaRuntime {
    <# Fast check: returns $true if 'nvidia' runtime appears in 'docker info' (no image pull needed). #>
    try {
        $info = (docker info 2>&1) -join ' '
        return ($info -match '\bnvidia\b')
    } catch { return $false }
}

function Test-DockerGpuSupport {
    <# Returns $true if Docker can use the NVIDIA GPU.
       Uses 'docker info' as the primary fast check (avoids pulling a large CUDA image).
       Falls back to a container test only when docker info does not show the nvidia runtime. #>
    # Fast path: check 'docker info' for nvidia runtime
    if (Test-DockerNvidiaRuntime) {
        return $true
    }
    # Fallback: try running nvidia-smi inside a container (will pull image on first use)
    try {
        $out = docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch { return $false }
}

function Get-WslUserDistros {
    <# Returns list of WSL2 distro names accessible to the user (excludes docker-desktop internals). #>
    $result = @()
    try {
        $raw = wsl -l --verbose 2>&1
        foreach ($line in $raw) {
            $clean = ($line -replace '\x00', '' -replace '\*', '').Trim()
            if (-not $clean -or $clean -match '^NAME\s') { continue }
            $name = ($clean -split '\s+')[0]
            if ($name -and $name -ne 'docker-desktop' -and $name -ne 'docker-desktop-data') {
                $result += $name
            }
        }
    } catch { }
    return $result
}

function Invoke-NvidiaToolkitSetup {
    <# Attempts to install NVIDIA Container Toolkit when the nvidia runtime is missing from Docker.
       - If a WSL2 Ubuntu/Debian distro exists: installs toolkit and reconfigures Docker runtime.
       - If only docker-desktop WSL2 is present: Docker Desktop has built-in GPU, emits guidance.
       Returns $true if GPU becomes available after the operation. #>

    Write-Step 'Tentando configurar suporte a GPU NVIDIA no Docker...'

    if (-not (Test-NvidiaGpuOnHost)) {
        Write-Warn 'GPU NVIDIA nao encontrada no host (nvidia-smi nao disponivel).'
        Write-Warn 'Instale o driver NVIDIA para Windows: https://www.nvidia.com/drivers'
        return $false
    }
    Write-Ok 'GPU NVIDIA detectada no host via nvidia-smi.'

    if (Test-DockerNvidiaRuntime) {
        Write-Ok 'Runtime nvidia ja registrado no Docker. GPU disponivel!'
        return $true
    }

    # Find a user-accessible Ubuntu/Debian WSL2 distro
    $userDistros = Get-WslUserDistros
    $ubuntuDistro = $null
    foreach ($d in $userDistros) {
        if ($d -match 'Ubuntu|Debian|kali|linuxmint|Pop') {
            $ubuntuDistro = $d
            break
        }
    }

    if ($ubuntuDistro) {
        Write-Step "Instalando NVIDIA Container Toolkit em WSL2 ($ubuntuDistro)..."

        # Build installation script as temp file (Windows path -> WSL path)
        $installScript = @'
set -e
echo "[+] Atualizando pacotes..."
apt-get update -qq
apt-get install -y --no-install-recommends curl gnupg ca-certificates
echo "[+] Adicionando repositorio NVIDIA Container Toolkit..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update -qq
echo "[+] Instalando nvidia-container-toolkit..."
apt-get install -y nvidia-container-toolkit
echo "[+] Configurando runtime Docker..."
nvidia-ctk runtime configure --runtime=docker
echo "[+] NVIDIA Container Toolkit instalado com sucesso!"
'@
        try {
            $tmpFile = [System.IO.Path]::GetTempFileName() + '.sh'
            [System.IO.File]::WriteAllText($tmpFile, ($installScript -replace '`r`n', '`n'))
            $drive   = $tmpFile.Substring(0, 1).ToLower()
            $relPath = $tmpFile.Substring(2) -replace '\\', '/'
            $wslPath = "/mnt/$drive$relPath"

            wsl -d $ubuntuDistro -u root -- bash $wslPath
            $exitCode = $LASTEXITCODE
            Remove-Item $tmpFile -ErrorAction SilentlyContinue

            if ($exitCode -ne 0) {
                Write-Fail "Instalacao falhou (exit $exitCode). Tentando continuar em modo CPU."
                return $false
            }
            Write-Ok 'NVIDIA Container Toolkit instalado!'
        } catch {
            Write-Fail "Excecao durante instalacao: $_"
            return $false
        }

        # Restart Docker Desktop to pick up the new runtime
        Write-Warn 'Reiniciando Docker Desktop para registrar o runtime nvidia...'
        Stop-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        $ddExe = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
        if (Test-Path $ddExe) { Start-Process $ddExe -ErrorAction SilentlyContinue }

        $waited = 0
        while ($waited -lt 90) {
            Start-Sleep -Seconds 3
            $waited += 3
            if (Test-DockerReady) { break }
            Write-Host "    Aguardando Docker reiniciar... (${waited}s / 90s)" -ForegroundColor DarkGray
        }

        if (Test-DockerNvidiaRuntime) {
            Write-Ok 'Runtime nvidia registrado apos reinicio do Docker Desktop!'
            return $true
        } else {
            Write-Warn 'Runtime nvidia ainda nao detectado. GPU continuara em modo CPU nesta sessao.'
            Write-Warn 'Reinicie o Docker Desktop manualmente e execute o script novamente para usar GPU.'
            return $false
        }
    } else {
        # Docker Desktop only (no Ubuntu WSL2 distro) - built-in GPU support should work
        $ddVersion   = docker version --format '{{.Server.Version}}' 2>&1
        $driverVer   = nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1
        Write-Warn ''
        Write-Warn 'Runtime nvidia nao detectado, mas GPU esta presente no host.'
        Write-Warn "  Docker Desktop versao: $ddVersion (necessario >= 4.3.0)"
        Write-Warn "  Driver NVIDIA Windows: $driverVer"
        Write-Warn ''
        Write-Warn 'Nenhuma distro Ubuntu/Debian WSL2 encontrada para instalar NVIDIA Container Toolkit.'
        Write-Warn 'Com Docker Desktop >= 4.3.0, GPU deve funcionar sem toolkit adicional.'
        Write-Warn ''
        Write-Warn 'Acoes recomendadas:'
        Write-Warn '  1. Atualize o Docker Desktop para >= 4.3.0'
        Write-Warn '  2. Reinicie o Docker Desktop completamente'
        Write-Warn '  3. Ou instale Ubuntu no WSL2 para suporte avancado:'
        Write-Warn '       wsl --install -d Ubuntu'
        Write-Warn '     E entao execute este script novamente.'
        return $false
    }
}

function Wait-ForEndpoint ([string]$url, [int]$timeoutSec, [string]$label) {
    <# Polls an HTTP endpoint until it returns 2xx or timeout is reached. Returns $true on success. #>
    $elapsed  = 0
    $interval = 5
    while ($elapsed -lt $timeoutSec) {
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($resp -and $resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300) {
                return $true
            }
        } catch { }
        Write-Host "    Waiting for $label... (${elapsed}s / ${timeoutSec}s)" -ForegroundColor DarkGray
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }
    return $false
}

function Test-LibrePermissionError {
    <# Checks recent LibreTranslate logs for the known PermissionError (issue #669). #>
    try {
        $logs = docker logs --tail 300 $LibreContainer 2>&1
        if (-not $logs) { return $false }
        $text = $logs -join "`n"
        if ($text -match 'PermissionError') { return $true }
        if ($text -match 'Permission denied' -and $text -match '/home/libretranslate') { return $true }
    } catch { }
    return $false
}

function Repair-LibrePermissions {
    <# Attempts to fix volume permissions using an ephemeral alpine container. Returns $true on success. #>
    Write-Warn "Attempting to fix volume permissions (UID $LibreUid) on '$VolumeName'..."

    # Check volume exists (exact match)
    $volList = docker volume ls --format '{{.Name}}' 2>$null
    $volFound = $false
    if ($volList) {
        foreach ($v in $volList) {
            if ($v.Trim() -eq $VolumeName) { $volFound = $true; break }
        }
    }
    if (-not $volFound) {
        Write-Warn "Volume '$VolumeName' not found. If using a bind mount, fix permissions on the host manually:"
        Write-Warn "  chown -R ${LibreUid}:${LibreGid} <your-host-path>"
        return $false
    }

    # Run ephemeral chown
    docker run --rm -v "${VolumeName}:/data" alpine sh -c "chown -R ${LibreUid}:${LibreGid} /data" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to chown volume. Try manually:"
        Write-Fail "  docker run --rm -v ${VolumeName}:/data alpine chown -R ${LibreUid}:${LibreGid} /data"
        return $false
    }

    # Restart container
    docker restart $LibreContainer 2>&1 | Out-Null
    Write-Ok "Volume permissions fixed and container restarted."
    return $true
}

# =========================================================================
# STEP 1 - Prerequisites
# =========================================================================
Write-Step "Checking prerequisites..."

if (-not (Test-DockerReady)) {
    Write-Fail "Docker is not available. Ensure Docker Desktop is installed, running, and 'docker' is in PATH."
    exit 1
}
Write-Ok "Docker CLI and daemon are ready."

$composeMode = Get-ComposeCommand
if (-not $composeMode) {
    Write-Fail "Neither 'docker compose' (plugin) nor 'docker-compose' (standalone) found."
    exit 1
}
Write-Ok "Compose mode: $composeMode"

$repoRoot    = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$composeFile = Join-Path $repoRoot 'docker-compose.deploy.yml'
if (-not (Test-Path $composeFile)) {
    Write-Fail "Compose file not found: $composeFile"
    exit 1
}

# =========================================================================
# STEP 2 - Detect what is already running
# =========================================================================
Write-Step "Detecting existing services..."

$sqlInDocker   = Test-PortUsedByDocker $SqlPort

$sqlBusy   = $false
if (-not $sqlInDocker) { $sqlBusy = Test-PortListening $SqlPort }

$skipSql   = $false
$skipLibre = $false

if ($sqlInDocker) {
    Write-Ok "SQL Server: port $SqlPort in use by a Docker container - will SKIP."
    $skipSql = $true
} elseif ($sqlBusy) {
    Write-Warn "Port $SqlPort is in use by a NON-Docker process. Skipping sqlserver, but the API may fail to connect."
    $skipSql = $true
} else {
    Write-Ok "SQL Server: port $SqlPort is free - will START."
}

Write-Ok "API: will ALWAYS be recreated to use the latest code."

# Real-ESRGAN container (used by image upscale). If already running, skip; otherwise we will start it.
$skipRealesrgan    = $false
$realesrganError   = $null
$RealesrganPort    = 8000
$RealesrganContainer = 'realesrgan'
try {
    if (Test-ContainerRunning 'realesrgan') {
        Write-Ok "Real-ESRGAN: container 'realesrgan' is already running - will SKIP."
        $skipRealesrgan = $true
    } else {
        Write-Ok "Real-ESRGAN: will START (build may take a few minutes on first run)."
    }
} catch {
    # Defensive: do not fail the whole script if detection has an issue
    Write-Warn "Could not determine Real-ESRGAN container state. Will attempt to start if not present."
}

# =========================================================================
# STEP 2.5 - Detect GPU availability for Real-ESRGAN
# =========================================================================
$gpuAvailable    = $false
$gpuNote         = $null
$gpuComposeFile  = Join-Path $repoRoot 'docker-compose.gpu.yml'

if (-not $skipRealesrgan) {
    Write-Step "Detecting GPU availability for Real-ESRGAN..."

    if (-not (Test-Wsl2Available)) {
        $gpuNote = "WSL 2 nao detectado. GPU passthrough requer WSL 2."
        Write-Warn $gpuNote
    } elseif (-not (Test-NvidiaGpuOnHost)) {
        $gpuNote = "NVIDIA GPU/driver nao detectado no host (nvidia-smi nao encontrado ou falhou)."
        Write-Warn $gpuNote
    } else {
        Write-Host "    Verificando runtime NVIDIA no Docker (verificacao rapida via docker info)..." -ForegroundColor DarkGray
        if (Test-DockerGpuSupport) {
            $gpuAvailable = $true
            Write-Ok "GPU NVIDIA detectada e funcionando dentro do Docker!"
        } else {
            $gpuNote = "Runtime NVIDIA nao detectado no Docker."
            Write-Warn $gpuNote
            Write-Warn "Tentando configurar automaticamente..."
            # Attempt automatic setup (install toolkit or guide user)
            $setupOk = Invoke-NvidiaToolkitSetup
            if ($setupOk) {
                $gpuAvailable = $true
                $gpuNote = $null
                Write-Ok "GPU configurada com sucesso!"
            } else {
                Write-Warn "Configuracao automatica nao foi possivel. Real-ESRGAN usara modo CPU."
            }
        }
    }

    if ($gpuAvailable) {
        Write-Ok "Real-ESRGAN usara modo GPU (RTX detectada)."
    } else {
        Write-Warn "Real-ESRGAN usara modo CPU (Pillow Lanczos). Qualidade sera inferior ao modo GPU."
    }
} else {
    Write-Host "    GPU detection skipped (Real-ESRGAN already running)." -ForegroundColor DarkGray
}

# =========================================================================
# STEP 3 - Start services via Docker Compose
# =========================================================================
Write-Step "Starting services..."

# LibreTranslate is started by start-environment.bat using the official Docker Hub image
# (docker run -d --name libretranslate -p 5000:5000 libretranslate/libretranslate).
# Here we only validate runtime state and report clearly.
$libreStartedFresh = $false
if (Test-ContainerRunning $LibreContainer) {
    Write-Ok "LibreTranslate container detected and running (imagem oficial)."
    $skipLibre = $true
} else {
    Write-Warn "LibreTranslate container not detected. Translation endpoint may be unavailable."
    $skipLibre = $false
}

# Build core services list (without realesrgan — started separately for resilience)
$services    = @()
$needProfile = $false

if (-not $skipSql) {
    $services   += 'sqlserver'
    $needProfile = $true
}
# LibreTranslate runs independently via Docker Hub image (not in compose stack).
$services += 'api'

# Build argument list depending on compose mode
if ($composeMode -eq 'plugin') {
    $cmdArgs = @('compose')
    if ($needProfile) { $cmdArgs += '--profile'; $cmdArgs += 'withdb' }
    $cmdArgs += '-f'; $cmdArgs += $composeFile
    $cmdArgs += 'up'; $cmdArgs += '-d'; $cmdArgs += '--no-deps'; $cmdArgs += '--build'; $cmdArgs += '--force-recreate'
    $cmdArgs += $services
    $cmdExe = 'docker'
} else {
    $cmdArgs = @()
    if ($needProfile) { $cmdArgs += '--profile'; $cmdArgs += 'withdb' }
    $cmdArgs += '-f'; $cmdArgs += $composeFile
    $cmdArgs += 'up'; $cmdArgs += '-d'; $cmdArgs += '--no-deps'; $cmdArgs += '--build'; $cmdArgs += '--force-recreate'
    $cmdArgs += $services
    $cmdExe = 'docker-compose'
}

Write-Host "    Running: $cmdExe $($cmdArgs -join ' ')" -ForegroundColor DarkGray

Push-Location $repoRoot
try {
    & $cmdExe @cmdArgs
    $composeExit = $LASTEXITCODE
} catch {
    Write-Fail "Compose command threw an exception: $_"
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

if ($composeExit -ne 0) {
    Write-Fail "Compose exited with code $composeExit. Check the output above."
    exit $composeExit
}
Write-Ok "Core services started successfully."

# --- Start Real-ESRGAN separately (non-blocking on failure) ---
if (-not $skipRealesrgan) {
    $gpuLabel = 'CPU fallback'
    if ($gpuAvailable) { $gpuLabel = 'GPU' }
    Write-Step "Starting Real-ESRGAN service in $gpuLabel mode (build may take a few minutes on first run)..."

    if ($composeMode -eq 'plugin') {
        $esrganArgs = @('compose', '-f', $composeFile)
        if ($gpuAvailable) { $esrganArgs += '-f'; $esrganArgs += $gpuComposeFile }
        $esrganArgs += @('up', '-d', '--no-deps', '--build', '--force-recreate', 'realesrgan')
        $esrganExe = 'docker'
    } else {
        $esrganArgs = @('-f', $composeFile)
        if ($gpuAvailable) { $esrganArgs += '-f'; $esrganArgs += $gpuComposeFile }
        $esrganArgs += @('up', '-d', '--no-deps', '--build', '--force-recreate', 'realesrgan')
        $esrganExe = 'docker-compose'
    }

    Push-Location $repoRoot
    try {
        & $esrganExe @esrganArgs 2>&1 | Out-Null
        $esrganExit = $LASTEXITCODE
        if ($esrganExit -ne 0) {
            $realesrganError = "Compose exited with code $esrganExit for realesrgan service."
            Write-Warn $realesrganError
        } else {
            Write-Ok "Real-ESRGAN service started."
        }
    } catch {
        $realesrganError = "Exception starting realesrgan: $_"
        Write-Warn $realesrganError
    } finally {
        Pop-Location
    }

    # Post-start verification: sometimes compose emits build messages but the
    # container still comes up. If we recorded an error, double-check the
    # container and health endpoint and clear the error if healthy.
    if ($realesrganError) {
        Start-Sleep -Seconds 3
        if (Test-ContainerRunning $RealesrganContainer) {
            $esrganHealthy = $false
            try {
                $esrganHealthy = Wait-ForEndpoint ("http://localhost:${RealesrganPort}/health") 10 "Real-ESRGAN"
            } catch { $esrganHealthy = $false }

            if ($esrganHealthy) {
                $realesrganError = $null
                Write-Ok "Real-ESRGAN service started and health endpoint is responding."
            } else {
                Write-Warn "Real-ESRGAN container is running but health endpoint did not respond within 10s."
            }
        } else {
            Write-Warn "Real-ESRGAN container not running after compose attempt."
        }
    }
}

# Give containers a moment to initialize
Start-Sleep -Seconds 3

# =========================================================================
# STEP 4 - Health checks and PermissionError handling
# =========================================================================
Write-Step "Running health checks..."

$libreReady = $false
if (Test-ContainerRunning $LibreContainer) {
    if (Test-PortUsedByDocker $LibrePort) {
        $libreReady = $true
        Write-Ok "LibreTranslate container is running and publishing port ${LibrePort}."
    } else {
        Write-Warn "LibreTranslate container is running but port ${LibrePort} is not published yet."
    }
} else {
    Write-Warn "LibreTranslate container is not running right now."
}

# --- API readiness ---
$apiReady = $false

if (Test-ContainerRunning $ApiContainer) {
    Write-Host "    Waiting for API health check..." -ForegroundColor DarkGray
    $apiReady = Wait-ForEndpoint $ApiHealthUrl $ApiTimeoutSec "API"
    if ($apiReady) {
        Write-Ok "API is ready!"
    } else {
        Write-Warn "API did not respond within ${ApiTimeoutSec}s. Check logs: docker logs $ApiContainer"
    }
} else {
    Write-Fail "API container '$ApiContainer' is not running. Check logs: docker logs $ApiContainer"
}

# =========================================================================
# STEP 4.4 - Configure external network integration
# =========================================================================
Write-Step "Configuring external Docker network integration..."
$networkScript = Join-Path $repoRoot 'scripts\network_externa_libretranslate.bat'
if (Test-Path $networkScript) {
    try {
        & $networkScript '--nopause'
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "network_externa_libretranslate.bat exited with code $LASTEXITCODE."
        } else {
            Write-Ok "External network integration script executed successfully."
        }
    } catch {
        Write-Warn "Failed to execute network_externa_libretranslate.bat: $_"
    }
} else {
    Write-Warn "Network integration script not found: $networkScript"
}

# =========================================================================
# STEP 4.5 - Network integration status (API <-> LibreTranslate)
# =========================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " NETWORK INTEGRATION STATUS (API <-> LIBRETRANSLATE)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$networkName = 'anime-net'
$networkExists = $false
try {
    docker network inspect $networkName 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $networkExists = $true }
} catch { }

if ($networkExists) {
    Write-Ok "Docker network '$networkName' is available."
    $netContainers = @()
    try {
        $rawContainers = docker network inspect $networkName --format '{{range $k,$v := .Containers}}{{$v.Name}}{{println}}{{end}}' 2>$null
        if ($rawContainers) {
            foreach ($line in $rawContainers) {
                $name = $line.Trim()
                if ($name) { $netContainers += $name }
            }
        }
    } catch { }

    if ($netContainers.Count -gt 0) {
        Write-Host "  Containers connected:" -ForegroundColor Cyan
        foreach ($containerName in $netContainers) {
            Write-Host "    - $containerName"
        }
    } else {
        Write-Warn "No containers listed on '$networkName' at the moment."
    }

    if ($netContainers -contains $ApiContainer) {
        Write-Ok "API container is connected to '$networkName'."
    } else {
        Write-Warn "API container is NOT connected to '$networkName'."
    }

    if ($netContainers -contains $LibreContainer) {
        Write-Ok "LibreTranslate container is connected to '$networkName'."
    } else {
        Write-Warn "LibreTranslate container is NOT connected to '$networkName'."
    }
} else {
    Write-Warn "Docker network '$networkName' was not found."
}

Write-Host "  Recommended Translation BaseUrl: http://host.docker.internal:5000" -ForegroundColor DarkGray
Write-Host ""

# =========================================================================
# STEP 5 - Summary
# =========================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " ENVIRONMENT SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# SQL Server status
$sqlStatus = 'NOT RUNNING'
if ($skipSql) {
    $sqlStatus = 'SKIPPED (pre-existing on port {0})' -f $SqlPort
} elseif (Test-ContainerRunning $SqlContainer) {
    $sqlStatus = 'RUNNING'
}
Write-Host ("  SQL Server:     {0}" -f $sqlStatus)

# LibreTranslate status
$libreStatus = 'NOT RUNNING'
if ($libreStartedFresh -and $libreReady) {
    $libreStatus = 'RUNNING (pronto)'
} elseif ($libreStartedFresh) {
    $libreStatus = 'RUNNING (baixando modelos - pode levar varios minutos)'
} elseif ($skipLibre -and $libreReady) {
    $libreStatus = 'RUNNING (pronto - ja estava rodando)'
} elseif ($skipLibre) {
    $libreStatus = 'RUNNING (nao respondendo ainda)'
} elseif ($libreReady) {
    $libreStatus = 'RUNNING (pronto)'
} elseif (Test-ContainerRunning $LibreContainer) {
    $libreStatus = 'RUNNING (carregando)'
}
Write-Host ("  LibreTranslate: {0}" -f $libreStatus)

# API status
$apiStatus = 'NOT RUNNING'
if ($apiReady) {
    $apiStatus = 'RUNNING (ready)'
} elseif (Test-ContainerRunning $ApiContainer) {
    $apiStatus = 'RUNNING (not yet responding)'
}
Write-Host ("  API:            {0}" -f $apiStatus)

# Real-ESRGAN status
$esrganStatus = 'NOT RUNNING'
if ($skipRealesrgan) {
    $esrganStatus = 'SKIPPED (pre-existing)'
} elseif ($realesrganError) {
    $esrganStatus = 'FAILED'
} elseif (Test-ContainerRunning $RealesrganContainer) {
    $modeLabel = 'CPU'
    if ($gpuAvailable) { $modeLabel = 'GPU' }
    $esrganStatus = "RUNNING ($modeLabel mode)"
}
Write-Host ("  Real-ESRGAN:    {0}" -f $esrganStatus)

Write-Host ""
Write-Host "  Endpoints:" -ForegroundColor Cyan
Write-Host "    API Swagger:    http://localhost:${ApiPort}/swagger"
Write-Host "    API Health:     http://localhost:${ApiPort}/health/live"
Write-Host "    LibreTranslate: http://localhost:${LibrePort}/"
Write-Host "    Real-ESRGAN:    http://localhost:${RealesrganPort}/health"
Write-Host ""
Write-Host "  Logs:" -ForegroundColor Cyan
Write-Host "    docker logs -f $ApiContainer"
Write-Host "    docker logs -f $LibreContainer"
Write-Host "    docker logs -f $RealesrganContainer"

# Show warning banner if Real-ESRGAN failed
if ($realesrganError) {
    Write-Host ""
    Write-Host "  [AVISO]" -ForegroundColor Yellow
    Write-Host "  Falha ao iniciar o container realesrgan." -ForegroundColor Yellow
    Write-Host "  Motivo: $realesrganError" -ForegroundColor Yellow
    Write-Host "  O recurso de upscale de imagens estara indisponivel." -ForegroundColor Yellow
    Write-Host "  Todos os outros servicos foram iniciados normalmente." -ForegroundColor Yellow
}

# Show GPU info banner when running in CPU fallback mode
if (-not $skipRealesrgan -and -not $realesrganError -and -not $gpuAvailable) {
    Write-Host ""
    Write-Host "  [INFO GPU]" -ForegroundColor Yellow
    Write-Host "  GPU NVIDIA nao disponivel para o container de upscaling." -ForegroundColor Yellow
    if ($gpuNote) {
        Write-Host "  Motivo: $gpuNote" -ForegroundColor Yellow
    }
    Write-Host "  Real-ESRGAN esta rodando em modo CPU (Pillow Lanczos)." -ForegroundColor Yellow
    Write-Host "  Para usar GPU com qualidade superior, certifique-se de ter:" -ForegroundColor Yellow
    Write-Host "    - GPU NVIDIA com driver compativel com WSL 2" -ForegroundColor Yellow
    Write-Host "    - WSL 2 instalado e atualizado" -ForegroundColor Yellow
    Write-Host "    - Docker Desktop com backend WSL 2" -ForegroundColor Yellow
    Write-Host "    - NVIDIA Container Toolkit instalado" -ForegroundColor Yellow
    Write-Host "  Diagnostico: docker info | findstr nvidia" -ForegroundColor Yellow
    Write-Host "  Teste container: docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi" -ForegroundColor Yellow
    Write-Host "  Instalar Ubuntu WSL2 para toolkit: wsl --install -d Ubuntu" -ForegroundColor Yellow
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  [TRADUCAO] Importante" -ForegroundColor Yellow
Write-Host "  O endpoint de traducao so fica pronto apos o download dos pacotes de idiomas." -ForegroundColor Yellow
Write-Host "  Acompanhe: docker logs -f $LibreContainer" -ForegroundColor Yellow
Write-Host "  Se necessario, reinicie: docker restart $LibreContainer" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

# If LibreTranslate was just started for the first time, offer to tail its logs
if ((Test-ContainerRunning $LibreContainer) -and -not $libreReady) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  [LIBRETRANSLATE] Container ativo, ainda preparando modelos de idioma." -ForegroundColor Yellow
    Write-Host "  Isso pode levar varios minutos dependendo da conexao e do host." -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Deseja acompanhar os logs do LibreTranslate em tempo real?" -ForegroundColor Cyan
    Write-Host "  (Pressione Ctrl+C a qualquer momento para sair dos logs)" -ForegroundColor DarkGray
    Write-Host ""
    $resp = Read-Host "  [S/N]"
    if ($resp -match '^[sSyY]') {
        Write-Host ""
        Write-Host "  Acompanhando logs de $LibreContainer (Ctrl+C para sair)..." -ForegroundColor Cyan
        Write-Host ""
        docker logs -f $LibreContainer
    }
}

<#
.NOTES
    HOW TO RUN:
      .\start-environment.bat                              (from repo root, recommended)
      powershell -File scripts\start-environment.ps1       (direct)

    WHAT HAPPENS:
      1. Docker daemon and compose are verified.
      2. Ports 1433, 5000, 7118, 8000 are checked for existing services.
      3. LibreTranslate is started via Docker Hub image by start-environment.bat.
      4. SQL Server and API are orchestrated by docker-compose.deploy.yml.
      5. API is always rebuilt and recreated.
      6. GPU NVIDIA is detected; Real-ESRGAN starts in GPU or CPU mode.
      7. Network integration status is displayed (anime-net).
      8. Summary with status and endpoints is displayed.

    HOW TO SEE LOGS:
      docker logs -f libretranslate
      docker logs -f animehub-api
      docker logs -f realesrgan

    LIBRETRANSLATE:
      Uses the official Docker Hub image: libretranslate/libretranslate
      No submodule is required.
      docker restart libretranslate     (restart if needed)
#>
