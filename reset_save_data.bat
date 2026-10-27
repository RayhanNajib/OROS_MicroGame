@echo off
chcp 65001 >nul
title O.R.O.S. - Reset Save Data

echo ========================================================
echo       O.R.O.S. - RESET SAVE DATA UTILITY
echo ========================================================
echo.
echo PERINGATAN: Tindakan ini akan menghapus file save data
echo dan mengembalikan progres game ke kondisi awal.
echo.

if "%1"=="/y" goto DO_RESET
if "%1"=="-y" goto DO_RESET
if "%1"=="/Y" goto DO_RESET

set /p confirm="Apakah Anda yakin ingin mereset save data? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo [BATAL] Reset save data dibatalkan.
    echo.
    pause
    exit /b 0
)

:DO_RESET
echo.
echo Sedang mereset save data...
set "FOUND=0"
set "USERDATA_DIR=%APPDATA%\Godot\app_userdata"

if exist "%USERDATA_DIR%\O.R.O.S.- Overclocked Roguelite On Survivor\oros_save.json" (
    del /f /q "%USERDATA_DIR%\O.R.O.S.- Overclocked Roguelite On Survivor\oros_save.json"
    echo [OK] File dihapus: "%USERDATA_DIR%\O.R.O.S.- Overclocked Roguelite On Survivor\oros_save.json"
    set "FOUND=1"
)

if exist "%USERDATA_DIR%\O.R.O.S.- Overclocked Roguelite On Survivor - Micro Game Intro\oros_save.json" (
    del /f /q "%USERDATA_DIR%\O.R.O.S.- Overclocked Roguelite On Survivor - Micro Game Intro\oros_save.json"
    echo [OK] File dihapus: "%USERDATA_DIR%\O.R.O.S.- Overclocked Roguelite On Survivor - Micro Game Intro\oros_save.json"
    set "FOUND=1"
)

for /d %%D in ("%USERDATA_DIR%\*O.R.O.S*") do (
    if exist "%%D\oros_save.json" (
        del /f /q "%%D\oros_save.json"
        echo [OK] File dihapus: "%%D\oros_save.json"
        set "FOUND=1"
    )
)

echo.
if "%FOUND%"=="1" (
    echo ========================================================
    echo  BERHASIL: Save data O.R.O.S. telah di-reset ke awal!
    echo ========================================================
) else (
    echo ========================================================
    echo  INFORMASI: Tidak ada file save data yang perlu di-reset.
    echo  Data game sudah dalam kondisi baru.
    echo ========================================================
)

echo.
if not "%1"=="/y" if not "%1"=="-y" pause
