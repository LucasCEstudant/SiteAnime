@echo off
REM ================================================================
REM  AnimeHub - Start Development Environment
REM  Calls scripts\start-environment.ps1 with proper PS settings.
REM  Works on Windows 10/11 with PowerShell 5.1+.
REM  Requests elevation when needed to avoid Docker/network permission issues.
REM ================================================================
setlocal enabledelayedexpansion

set "NO_PAUSE=0"
set "SKIP_ELEVATION=0"
set "PS_ARGS="

for %%A in (%*) do (
    if /I "%%~A"=="--nopause" (
        set "NO_PAUSE=1"
    ) else if /I "%%~A"=="--skip-elevation" (
        set "SKIP_ELEVATION=1"
    ) else (
        set "PS_ARGS=!PS_ARGS! %%~A"
    )
)

if "%SKIP_ELEVATION%"=="0" (
    powershell.exe -NoProfile -Command "if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
    if errorlevel 1 (
        echo [INFO] Solicitando permissao de administrador para continuar...
        if "%*"=="" (
            set "RELAUNCH_ARGS=--skip-elevation"
        ) else (
            set "RELAUNCH_ARGS=%* --skip-elevation"
        )
        REM Use delayed expansion to ensure ArgumentList is not empty and expands correctly
        powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '!RELAUNCH_ARGS!' -Verb RunAs"
        if errorlevel 1 (
            echo [ERROR] Nao foi possivel solicitar permissao de administrador.
            if "%NO_PAUSE%"=="0" pause
            exit /b 1
        )
        exit /b 0
    )
)

set "PS_SCRIPT=%~dp0scripts\start-environment.ps1"
set "REPO_ROOT=%~dp0"
set "LIBRE_CONTAINER=libretranslate"
set "LIBRE_IMAGE=libretranslate/libretranslate"
set "EXIT_CODE=0"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] Script not found: %PS_SCRIPT%
    echo Make sure you are running this from the repository root.
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
)

echo ================================================================
echo  AnimeHub - Inicializacao automatizada do ambiente
echo ================================================================
echo.

echo [1/5] Verificando container LibreTranslate...

REM Check if container already exists (running or stopped)
set "LIBRE_RUNNING=0"
set "LIBRE_EXISTS=0"
for /f "usebackq delims=" %%C in (`docker ps --filter "name=^%LIBRE_CONTAINER%$" --format "{{.Names}}" 2^>nul`) do (
    set "LIBRE_RUNNING=1"
)
for /f "usebackq delims=" %%C in (`docker ps -a --filter "name=^%LIBRE_CONTAINER%$" --format "{{.Names}}" 2^>nul`) do (
    set "LIBRE_EXISTS=1"
)

if "%LIBRE_RUNNING%"=="1" (
    echo [OK] LibreTranslate ja esta rodando na porta 5000.
    goto :libre_ok
)

if "%LIBRE_EXISTS%"=="1" (
    echo [INFO] Container LibreTranslate existe mas esta parado. Iniciando...
    docker start %LIBRE_CONTAINER%
    if %ERRORLEVEL% neq 0 (
        echo [WARN] Falha ao iniciar container existente. Recriando...
        docker rm -f %LIBRE_CONTAINER% >nul 2>&1
        goto :libre_create
    )
    echo [OK] Container LibreTranslate iniciado.
    goto :libre_ok
)

:libre_create
echo [INFO] Criando container LibreTranslate a partir da imagem oficial...
echo        docker run -d --name %LIBRE_CONTAINER% -p 5000:5000 %LIBRE_IMAGE%
docker run -d --name %LIBRE_CONTAINER% -p 5000:5000 %LIBRE_IMAGE%
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Falha ao criar container LibreTranslate.
    echo         Verifique se a porta 5000 esta livre e se o Docker esta rodando.
    set "EXIT_CODE=1"
    goto :end
)
echo [OK] Container LibreTranslate criado com sucesso.

:libre_ok

echo [2/5] Validando LibreTranslate na porta 5000...
set "PORT_OK=0"
for /f "usebackq delims=" %%C in (`docker ps --filter "name=^%LIBRE_CONTAINER%$" --filter "publish=5000" --format "{{.Names}}" 2^>nul`) do (
    set "PORT_OK=1"
)
if "%PORT_OK%"=="0" (
    echo [ERROR] Container LibreTranslate nao esta publicando porta 5000.
    echo         Verifique com: docker logs %LIBRE_CONTAINER%
    set "EXIT_CODE=1"
    goto :end
)
echo [OK] LibreTranslate ativo na porta 5000.

echo [3/5] Aviso importante:
echo        Na primeira execucao, o LibreTranslate precisa baixar todos os
echo        pacotes de idiomas. Isso pode levar varios minutos.
echo        Acompanhe: docker logs -f %LIBRE_CONTAINER%
echo.

echo [4/5] Inicializando API, Real-ESRGAN e demais servicos...

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %PS_ARGS%

set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% neq 0 (
    echo.
    echo [ERROR] Script exited with code %EXIT_CODE%.
    echo See output above for details.
    if "%NO_PAUSE%"=="0" (
        echo Press any key to close...
        pause
    )
    exit /b %EXIT_CODE%
)

echo.
echo [5/5] Ambiente inicializado!
echo.
echo Nota:
echo - LibreTranslate roda via imagem oficial: %LIBRE_IMAGE%
echo - Aguarde o download dos pacotes de idioma; somente depois o endpoint de traducao estara disponivel.
echo - Acompanhe os logs com: docker logs -f %LIBRE_CONTAINER%
echo - Se necessario, reinicie: docker restart %LIBRE_CONTAINER%
echo - O site funciona normalmente sem traducao; apenas as traducoes ficam indisponiveis ate os modelos serem baixados.

echo.
if "%NO_PAUSE%"=="0" (
    echo Press any key to close...
    pause
)
:end
exit /b %EXIT_CODE%
