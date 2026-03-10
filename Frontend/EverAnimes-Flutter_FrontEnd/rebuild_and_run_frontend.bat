@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

color 0A
cls

echo.
echo  =====================================================
echo    EverAnimes  ^|  Rebuild Frontend + Docker
echo  =====================================================
echo    Diretorio: %CD%
echo  =====================================================
echo.

:: ─── Passo 1: flutter clean ───────────────────────────
echo  [1/4] Limpando build anterior...
echo  -----------------------------------------------------
call flutter clean
if errorlevel 1 goto :ERRO

echo.
echo  [OK] flutter clean concluido.
echo.

:: ─── Passo 2: flutter pub get ─────────────────────────
echo  [2/4] Baixando dependencias...
echo  -----------------------------------------------------
call flutter pub get
if errorlevel 1 goto :ERRO

echo.
echo  [OK] flutter pub get concluido.
echo.

:: ─── Passo 3: flutter build web --release ─────────────
echo  [3/4] Compilando para web (release)...
echo  -----------------------------------------------------
call flutter build web --release
if errorlevel 1 goto :ERRO

echo.
echo  [OK] Build web concluido.
echo.

:: ─── Passo 4: Docker down + up ────────────────────────
echo  [4/4] Parando container antigo e subindo versao nova...
echo  -----------------------------------------------------

docker compose down --remove-orphans 2>nul || docker-compose down --remove-orphans 2>nul

docker compose up --build -d
if errorlevel 1 (
  docker-compose up --build -d
  if errorlevel 1 goto :ERRO
)

echo.
echo  [OK] Container iniciado.
echo.
echo  =====================================================
echo    SUCESSO! Frontend rebuiltado e container rodando.
echo  =====================================================
echo.
echo  Pressione qualquer tecla para fechar...
pause > nul
endlocal
exit /b 0

:ERRO
echo.
echo  =====================================================
echo    ERRO! Veja a mensagem acima para mais detalhes.
echo  =====================================================
echo.
echo  Pressione qualquer tecla para fechar...
pause > nul
endlocal
exit /b 1
