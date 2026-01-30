@echo off
:: Altera para UTF-8 para aceitar emojis
chcp 65001 >nul
setlocal enabledelayedexpansion
cls

:: =======================================================
:: 1. CONFIGURACOES DE CAMINHO
:: =======================================================
set "MT5_DATA=C:\MT5"
set "METAEDITOR_PATH=%MT5_DATA%\metaeditor64.exe"

:: Pastas de Origem
set "SOURCE_PATH=src"
set "MAIN_FILE=SyncObjects.mq5"

:: Pastas de Destino no MetaTrader 5
set "DEST_IND=%MT5_DATA%\MQL5\Indicators\All_Uteis\SyncObjects"
set "DEST_INC=%DEST_IND%\Includes"

echo.
echo [DEPLOY] Iniciando: SyncObjects

:: =======================================================
:: 2. SINCRONIZACAO
:: =======================================================
if not exist "%DEST_IND%" mkdir "%DEST_IND%"
if not exist "%DEST_INC%" mkdir "%DEST_INC%"

echo [COPIA] mq5...
copy /Y "%SOURCE_PATH%\%MAIN_FILE%" "%DEST_IND%\" >nul

echo [COPIA] mqh...
copy /Y "%SOURCE_PATH%\Includes\*.mqh" "%DEST_INC%\" >nul

:: =======================================================
:: 3. COMPILACAO
:: =======================================================
echo [BUILD] Compilando com MetaEditor...
set "LOG_FILE=%DEST_IND%\build.log"

"%METAEDITOR_PATH%" /compile:"%DEST_IND%\%MAIN_FILE%" /log:"%LOG_FILE%"

:: =======================================================
:: 4. VALIDACAO
:: =======================================================
findstr /C:"0 error(s)" "%LOG_FILE%" >nul
if %errorlevel% equ 0 (
    echo SUCESSO: Arquivo .ex5 gerado!
    del "%LOG_FILE%"
) else (
    echo ERRO NA COMPILACAO:
    echo -------------------------------------------------------
    type "%LOG_FILE%"
    echo -------------------------------------------------------
)

echo.
echo Fim do processo.