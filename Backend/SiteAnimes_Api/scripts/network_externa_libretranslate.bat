@echo off
setlocal enabledelayedexpansion

set "NO_PAUSE=0"
if /I "%~1"=="--nopause" set "NO_PAUSE=1"

set "NETNAME=anime-net"
set "TMPPS=%TEMP%\animehub_docker_ps.tmp"
set "TMP5000=%TEMP%\animehub_5000.tmp"
set "TMP7118=%TEMP%\animehub_7118.tmp"
set "EXITCODE=0"
set "LIBRE="
set "API="

echo ===================================
echo  AnimeHub - Docker Network Setup
echo ===================================
echo.

REM [1/4] Verificar Docker
echo [1/4] Verificando Docker...
docker version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Docker nao disponivel ou nao esta rodando.
    set "EXITCODE=1"
    goto :END
)
echo [OK] Docker disponivel.
echo.

REM [2/4] Criar ou verificar rede
echo [2/4] Verificando rede %NETNAME%...
docker network inspect %NETNAME% >nul 2>&1
if errorlevel 1 (
    echo Criando rede %NETNAME%...
    docker network create %NETNAME%
    if errorlevel 1 (
        echo [ERRO] Falha ao criar rede %NETNAME%.
        set "EXITCODE=1"
        goto :END
    )
    echo [OK] Rede %NETNAME% criada com sucesso.
) else (
    echo [OK] Rede %NETNAME% ja existe.
)
echo.

REM [3/4] Detectar containers pelas portas
echo [3/4] Detectando containers pelas portas expostas...

REM Salva saida do docker ps em arquivo temporario (sem pipes)
if exist "%TMPPS%" del "%TMPPS%" >nul 2>&1
docker ps --format "{{.Names}} {{.Ports}}" > "%TMPPS%" 2>nul

REM Busca container na porta 5000 (LibreTranslate) via findstr no arquivo
if exist "%TMP5000%" del "%TMP5000%" >nul 2>&1
findstr /C:":5000" "%TMPPS%" > "%TMP5000%" 2>nul
for /f "usebackq tokens=1" %%A in ("%TMP5000%") do (
    if not defined LIBRE set "LIBRE=%%A"
)
if exist "%TMP5000%" del "%TMP5000%" >nul 2>&1

REM Busca container na porta 7118 (API) via findstr no arquivo
if exist "%TMP7118%" del "%TMP7118%" >nul 2>&1
findstr /C:":7118" "%TMPPS%" > "%TMP7118%" 2>nul
for /f "usebackq tokens=1" %%A in ("%TMP7118%") do (
    if not defined API set "API=%%A"
)
if exist "%TMP7118%" del "%TMP7118%" >nul 2>&1

if exist "%TMPPS%" del "%TMPPS%" >nul 2>&1

if defined LIBRE (
    echo [OK] LibreTranslate encontrado: %LIBRE%
) else (
    echo [AVISO] Nenhum container na porta 5000 encontrado. LibreTranslate esta rodando?
)
if defined API (
    echo [OK] API encontrada: %API%
) else (
    echo [AVISO] Nenhum container na porta 7118 encontrado. API esta rodando?
)
echo.

REM [4/4] Conectar containers a rede
echo [4/4] Conectando containers a rede %NETNAME%...

if defined LIBRE (
    docker network connect %NETNAME% %LIBRE% 2>nul
    if errorlevel 1 (
        echo [AVISO] %LIBRE% pode ja estar conectado a %NETNAME%.
    ) else (
        echo [OK] %LIBRE% conectado a %NETNAME%.
    )
) else (
    echo [SKIP] LibreTranslate nao encontrado, pulando.
)

if defined API (
    docker network connect %NETNAME% %API% 2>nul
    if errorlevel 1 (
        echo [AVISO] %API% pode ja estar conectado a %NETNAME%.
    ) else (
        echo [OK] %API% conectado a %NETNAME%.
    )
) else (
    echo [SKIP] API nao encontrada, pulando.
)

echo.
echo ===================================
echo  Containers na rede %NETNAME%:
docker network inspect %NETNAME% --format "{{range $k,$v := .Containers}}  - {{$v.Name}}{{println}}{{end}}"
echo.
if defined LIBRE (
    echo  Configure a API com:
    echo  TRANSLATION__BASEURL=http://%LIBRE%:5000
)
echo ===================================

:END
echo.
if "%NO_PAUSE%"=="0" (
    echo Pressione qualquer tecla para fechar...
    pause >nul
)
endlocal
exit /b %EXITCODE%