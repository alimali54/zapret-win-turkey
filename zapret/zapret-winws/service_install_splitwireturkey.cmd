@echo off
setlocal enabledelayedexpansion

rem Zapret hizmeti kurulum scripti
rem Bu script SplitWireTurkey tarafından otomatik olarak oluşturulur

set SERVICE_NAME=zapret
set EXE_PATH=%~dp0winws.exe
set DISPLAY_NAME=Zapret Açıklaması DPI bypassing software

rem Mevcut hizmeti durdur ve sil
echo Mevcut %SERVICE_NAME% hizmeti kontrol ediliyor...
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo %SERVICE_NAME% hizmeti bulundu, durduruluyor...
    net stop %SERVICE_NAME% >nul 2>&1
    echo %SERVICE_NAME% hizmeti siliniyor...
    sc delete %SERVICE_NAME% >nul 2>&1
    echo %SERVICE_NAME% hizmeti silindi.
) else (
    echo %SERVICE_NAME% hizmeti bulunamadı.
)

rem Yeni hizmeti oluştur
echo Yeni %SERVICE_NAME% hizmeti oluşturuluyor...
sc create %SERVICE_NAME% binPath= "\"%EXE_PATH%\" %ARGS%" DisplayName= "%DISPLAY_NAME%" start= auto

if %errorlevel% equ 0 (
    echo %SERVICE_NAME% hizmeti başarıyla oluşturuldu.
    
    rem Hizmet açıklamasını ayarla
    echo Hizmet açıklaması ayarlanıyor...
    sc description %SERVICE_NAME% "zapret DPI bypass software"
    
    rem Hizmeti başlat
    echo %SERVICE_NAME% hizmeti başlatılıyor...
    sc start %SERVICE_NAME%
    
    if %errorlevel% equ 0 (
        echo %SERVICE_NAME% hizmeti başarıyla başlatıldı.
        echo Hizmet kurulumu tamamlandı.
    ) else (
        echo %SERVICE_NAME% hizmeti başlatılamadı. Hata kodu: %errorlevel%
    )
) else (
    echo %SERVICE_NAME% hizmeti oluşturulamadı. Hata kodu: %errorlevel%
)

echo.
echo Hizmet kurulum işlemi tamamlandı.
pause
