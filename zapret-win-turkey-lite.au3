#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=bin\zapret\zapret-winws\winws2.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Zapret Windows Türkiye Lite
#AutoIt3Wrapper_Res_Fileversion=4.7.0.0
#AutoIt3Wrapper_Res_ProductVersion=4.7
#AutoIt3Wrapper_Res_LegalCopyright=Ali Mali
#AutoIt3Wrapper_Res_Language=1055
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <TrayConstants.au3>
#include <ComboConstants.au3>
#include <AutoItConstants.au3>
#include <Constants.au3>

Global Const $PBS_MARQUEE = 0x08

; --- ZIP / TEMP KLASÖRÜ KONTROLÜ ---
Local $currentDir = @ScriptDir
If StringInStr($currentDir, @TempDir) Or StringInStr($currentDir, "Temporary Internet Files") Or StringInStr($currentDir, "vfs") Then
    MsgBox(16, "Hata: Arşivden Çalıştırma Saptandı", _
            "Programı ZIP dosyasının içinden doğrudan çalıştırmayın!" & @CRLF & @CRLF & _
            "1. ZIP dosyasındaki tüm dosyaları normal bir klasöre çıkarın." & @CRLF & _
            "2. Ardından programı o klasörden tekrar başlatın.")
    Exit
EndIf

; --- GÜVENLİK UYARILARINI KALDIR ---
RunWait('powershell -Command "Get-ChildItem -Path ''' & @ScriptDir & ''' -Recurse | Unblock-File"', "", @SW_HIDE)

; --- ÇAKIŞMA KONTROLÜ (GoodbyeDPI) ---
If ProcessExists("goodbyedpi.exe") Then
    Local $iResponse = MsgBox(52, "Çakışma Saptandı", "GoodbyeDPI aktif gözüküyor, Zapret'in çalışması için GoodbyeDPI sonlandırılmalı." & @CRLF & @CRLF & _
            "GoodbyeDPI'ı kapatmak ve varsa servisini kaldırmak istiyor musunuz?")
    If $iResponse = 6 Then
        ProcessClose("goodbyedpi.exe")
        While ProcessExists("goodbyedpi.exe")
            Sleep(100)
        WEnd
        RunWait(@ComSpec & ' /c sc stop "GoodbyeDPI" & sc delete "GoodbyeDPI" & sc stop "WinDivert" & sc delete "WinDivert" & sc stop "WinDivert14" & sc delete "WinDivert14"', "", @SW_HIDE)
		MsgBox(64, "Bilgi", "GoodbyeDPI ve servisleri başarıyla kaldırıldı. Program başlatılıyor.")
	Else
        Exit
    EndIf
EndIf

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

; --- Ayarlar ve Dosya Yolları ---
Local $serviceName = "ZapretService"
Local $hostlistPath = @ScriptDir & "\config\autohostlist.txt"
Local $normalHostlistPath = @ScriptDir & "\config\hostlist.txt"
Local $iniPath = @ScriptDir & "\config\config.ini"
Local $exludelistPath = @ScriptDir & "\config\excludelist.txt"

; --- CONFIG DOSYASINDAN AYARLARI OKU ---
Local $iniEngine = IniRead($iniPath, "Settings", "ActiveEngine", "0") ; 0 = Zapret2, 1 = Zapret1
Local $iniStrategy = IniRead($iniPath, "Settings", "ActiveStrategy", "Turk Telekom")
; 0 = Kapalı, 1 = Auto, 2 = Manuel
Local $iniFilterMode = IniRead($iniPath, "Settings", "FilterMode", "1")

; --- DİNAMİK MOTOR DEĞİŞKENLERİ ---
Global $strategyFile = ""
Global $winwsPath = ""
Global $currentEngine = "Zapret2"

; --- Global Durum Değişkenleri ---
Global $isZapretRunning = False
Global $zapretPID = 0
Global $bServiceStoppedWarned = False

; Servis kurulum butonuna art arda tıklamayı engelleyen kilit.
Global $bInstallServiceBusy = False
Global $hInstallServiceUnlockTimer = 0
Global $bInstallServiceEnableAfterLock = True

; --- GUI Tasarımı ---
Global $hGUI = GUICreate("Zapret Windows Türkiye v4.7 Lite", 400, 396)
GUISetBkColor(0xFFFFFF)

; --- Tepsi Menüsü ---
Local $trayShow = TrayCreateItem("Göster")
TrayItemSetOnEvent(-1, "ShowGUI")
TrayCreateItem("")
Local $trayExit = TrayCreateItem("Kapat")
TrayItemSetOnEvent(-1, "_SaveConfigAndExit")
TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "ShowGUI")
TraySetClick(16)

; --- Üst Durum Paneli ---
Local $lblStatusBg = GUICtrlCreateLabel("", 15, 15, 370, 75)
GUICtrlSetBkColor(-1, 0xF2F4F7)
Local $lblStatusText = GUICtrlCreateLabel("SİSTEM HAZIRLANIYOR...", 15, 30, 370, 25, $SS_CENTER)
GUICtrlSetFont(-1, 12, 800, 0, "Segoe UI")
GUICtrlSetColor(-1, 0xE67E22)

Local $pBar = GUICtrlCreateProgress(15, 75, 370, 15, $PBS_MARQUEE)
GUICtrlSetState(-1, $GUI_HIDE)

Local $lblStrategyInfo = GUICtrlCreateLabel("Strateji Durumu: Kontrol Ediliyor...", 15, 55, 370, 20, $SS_CENTER)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x666666)

; =========================================================================
; --- 1. ANA BUTON (EN ÜSTE ALINDI) ---
; =========================================================================
Local $btnRunZapret = GUICtrlCreateButton("ZAPRET'İ BAŞLAT", 50, 95, 300, 55)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetFont(-1, 11, 800, 0, "Segoe UI")

; MOTOR
GUICtrlCreateLabel("Motor:", 50, 168, 120, 20)
GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI")
Local $cmbEngine = GUICtrlCreateCombo("Zapret2 (Yeni LUA Motoru)", 175, 165, 175, 25, $CBS_DROPDOWNLIST)
GUICtrlSetData(-1, "Zapret (Eski Klasik Motor)")
If $iniEngine == "1" Then GUICtrlSetData($cmbEngine, "Zapret (Eski Klasik Motor)", "Zapret (Eski Klasik Motor)")
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetState(-1, $GUI_DISABLE)

; STRATEJİ
GUICtrlCreateLabel("Strateji:", 50, 212, 120, 20)
GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI")
Global $cmbStrategy = GUICtrlCreateCombo("Turk Telekom", 175, 200, 175, 25, $CBS_DROPDOWNLIST)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetState(-1, $GUI_DISABLE)

; FİLTRE
GUICtrlCreateLabel("Filtre:", 50, 247, 120, 20)
GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI")
Global $cmbFilter = GUICtrlCreateCombo("Kapalı (Tüm trafik)", 175, 235, 175, 25, $CBS_DROPDOWNLIST)
Global $sFilterSelectionBeforeOOB = ""
Global $bFilterWasEnabledBeforeOOB = False
Global $bOOBFilterLock = False
GUICtrlSetData(-1, "Auto (Zapret oluşturur)|Manuel ('hostlist.txt' İçeriği)")

; INI'den okunan değere göre varsayılanı seç
If $iniFilterMode == "1" Then
    GUICtrlSetData($cmbFilter, "Auto (Zapret oluşturur)", "Auto (Zapret oluşturur)")
ElseIf $iniFilterMode == "2" Then
    GUICtrlSetData($cmbFilter, "Manuel ('hostlist.txt' İçeriği)", "Manuel ('hostlist.txt' İçeriği)")
Else
    GUICtrlSetData($cmbFilter, "Kapalı (Tüm trafik)", "Kapalı (Tüm trafik)")
EndIf
$sFilterSelectionBeforeOOB = GUICtrlRead($cmbFilter)

GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetState(-1, $GUI_DISABLE)

; =========================================================================
; --- LITE SÜRÜMÜNÜN TEMEL İŞLEMLERİ ---
; =========================================================================
Local $btnInstallService = GUICtrlCreateButton("Servis Olarak Yükle (Otomatik Başlat)", 50, 281, 300, 35)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Local $btnRemoveService = GUICtrlCreateButton("Servis ve Kalıntıları Temizle", 50, 326, 300, 35)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Global $lblFooter = GUICtrlCreateLabel("Zapret Windows Türkiye Lite", 0, 371, 400, 20, $SS_CENTER)
GUICtrlSetFont(-1, 10, 400, 0, "Consolas")
GUICtrlSetColor(-1, 0xBDC3C7)

Local $aCriticalButtons[5] = [$btnRunZapret, $btnInstallService, $cmbEngine, $cmbStrategy, $cmbFilter]
Local $aOtherButtons[5] = [$btnInstallService, $btnRemoveService, $cmbEngine, $cmbStrategy, $cmbFilter]

GUISetState(@SW_SHOW)

; --- İLK YOLLARI VE STRATEJİ LİSTESİNİ DOĞRULA ---
_UpdateEnginePaths(GUICtrlRead($cmbEngine))
_LoadStrategyList($iniStrategy)
_RefreshStrategyLabel()
_UpdateFilterForStrategy()

; --- GÜVENLİ AÇILIŞ AKIŞI VE DİNAMİK DNS ZEHİRLENMESİ KONTROL DÖNGÜSÜ ---
RunWait(@ComSpec & " /c sc stop WinDivert & sc delete WinDivert & sc stop WinDivert14 & sc delete WinDivert14 & sc stop monkey & sc delete monkey", "", @SW_HIDE)
GUICtrlSetData($lblStatusText, "DNS KONTROL EDİLİYOR...")

Local $isDnsChangedByApp = False

While 1
    Local $isPoisoned = CheckDnsPoisoningSilent()

    If $isPoisoned Then
        _SetButtonsState($aCriticalButtons, $GUI_DISABLE)
        GUICtrlSetData($lblStatusText, "DNS ZEHİRLENMESİ SAPTANDI!")
        GUICtrlSetColor($lblStatusText, 0xC0392B)

        ; 2. TUR: Uygulama DNS değiştirdi ama hala zehirliyse (TT engelliyorsa)
        If $isDnsChangedByApp Then
            MsgBox(48 + 8192, "Kritik Uyarı", "Düz DNS değişikliği işe yaramadı, port 53'e müdahale var." & @CRLF & @CRLF & _
                    "Düz DNS değişikliği işe yaramadı. YogaDNS gibi harici bir DNS istemcisi kullanmayı deneyebilirsiniz.")
            ExitLoop
        EndIf

        ; 1. TUR: Zehirlenme ilk kez saptandıysa soru sor
        Local $iAsk = MsgBox(36 + 8192, "DNS Zehirlenmesi Saptandı", _
                "ISS tarafından DNS Zehirlenmesi saptandı!" & @CRLF & @CRLF & _
                "Sistem DNS adresiniz Cloudflare (1.1.1.1 / 1.0.0.1) olarak ayarlansın mı?")

        If $iAsk = 6 Then ; EVET
            GUICtrlSetData($lblStatusText, "DNS AYARLANIYOR...")
            _SetSystemDNS()
            $isDnsChangedByApp = True
            GUICtrlSetData($lblStatusText, "DNS TEST EDİLİYOR...")
            Sleep(1000)
            ContinueLoop ; Döngüyü başa sar, nslookup ile yeni DNS'i test et
        Else ; HAYIR
            ExitLoop
        EndIf
    Else
        ; Zehirlenme yoksa her şey normal devam etsin
        CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
        _RefreshStrategyLabel()
        ExitLoop
    EndIf
WEnd

; --- Ana Döngü ---
Local $hProcessTimer = TimerInit()

While 1
    Local $nMsg = GUIGetMsg()

    ; Servis kurulumu sırasında kuyruğa alınan tıklamaları atla.
    If $nMsg = $btnInstallService And $bInstallServiceBusy Then ContinueLoop

    If $bInstallServiceBusy And $hInstallServiceUnlockTimer <> 0 Then
        If TimerDiff($hInstallServiceUnlockTimer) >= 1500 Then
            $bInstallServiceBusy = False
            $hInstallServiceUnlockTimer = 0
            If $bInstallServiceEnableAfterLock And GUICtrlRead($lblStatusText) = "ÇALIŞMAYA HAZIR" Then
                GUICtrlSetState($btnInstallService, $GUI_ENABLE)
            EndIf
        EndIf
    EndIf

    ; Zapret motorunun beklenmedik kapanmasını izle.
    If TimerDiff($hProcessTimer) > 1000 Then
        Local $bZapretAlive = ProcessExists("winws.exe") Or ProcessExists("winws2.exe")
        If Not $bZapretAlive Then
            If $isZapretRunning Then
                StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
                MsgBox(16 + 8192, "Uyarı: Zapret Kapatıldı", "Zapret motoru beklenmedik bir şekilde kapandı veya dışarıdan sonlandırıldı!" & @CRLF & @CRLF & _
                    "Sisteminizdeki Anti-Cheat yazılımları Zapret'i kapatmış olabilir.")
            EndIf
            If GUICtrlRead($lblStatusText) = "SERVİS MODU AKTİF" Then
                CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
            EndIf
        EndIf
        $hProcessTimer = TimerInit()
    EndIf

    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            _SaveConfigAndExit()

        Case $GUI_EVENT_MINIMIZE
            GUISetState(@SW_HIDE, $hGUI)
            TraySetToolTip("Zapret Windows Türkiye Lite")

        Case $cmbEngine
            _UpdateEnginePaths(GUICtrlRead($cmbEngine))
            _LoadStrategyList("Turk Telekom")
            CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
            _RefreshStrategyLabel()

        Case $cmbStrategy
            _RefreshStrategyLabel()
            _UpdateFilterForStrategy()

        Case $btnRunZapret
            If $isZapretRunning = False Then
                StartWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
            Else
                StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
            EndIf

        Case $btnInstallService
            If $bInstallServiceBusy Then ContinueLoop
            $bInstallServiceBusy = True
            $hInstallServiceUnlockTimer = 0
            $bInstallServiceEnableAfterLock = (BitAND(GUICtrlGetState($btnInstallService), $GUI_ENABLE) <> 0)
            GUICtrlSetState($btnInstallService, $GUI_DISABLE)
            InstallServiceClean($cmbFilter)
            CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
            GUICtrlSetState($btnInstallService, $GUI_DISABLE)
            $hInstallServiceUnlockTimer = TimerInit()

        Case $btnRemoveService
            RemoveService()
            GUICtrlSetData($lblStatusText, "SİSTEM SIFIRLANIYOR...")
            _ResetSystemDNS()
            Local $isPoisonedAfterCleanup = CheckDnsPoisoningSilent()
            If Not $isPoisonedAfterCleanup Then CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
            _RefreshStrategyLabel()
            MsgBox(64 + 8192, "Bilgi", "Zapret servisleri ve kalıntıları temizlendi. DNS ayarları otomatiğe (DHCP) alındı.")
            If $isPoisonedAfterCleanup Then
                _SetButtonsState($aCriticalButtons, $GUI_DISABLE)
                GUICtrlSetData($lblStatusText, "DNS ZEHİRLENMESİ SAPTANDI!")
                GUICtrlSetColor($lblStatusText, 0xC0392B)
            Else
                CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
                _RefreshStrategyLabel()
            EndIf
    EndSwitch
WEnd

; --- YENİ YARDIMCI FONKSİYONLAR ---

Func _SetSystemDNS()
    Local $psScript = "$ErrorActionPreference = 'SilentlyContinue'; " & _
        "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Virtual*' -and $_.InterfaceDescription -notlike '*Hyper-V*' -and $_.InterfaceDescription -notlike '*WSL*' -and $_.Name -notlike '*vEthernet*' -and $_.InterfaceDescription -notlike '*TAP*' -and $_.InterfaceDescription -notlike '*TUN*' -and $_.InterfaceDescription -notlike '*VPN*'} | Select-Object -First 1; " & _
        "if ($adapter) { " & _
        "Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses @('1.1.1.1','1.0.0.1','2606:4700:4700::1111','2606:4700:4700::1001'); " & _
        "if ([Environment]::OSVersion.Version.Build -ge 22000) { " & _
        "$doh = Get-DnsClientDohServerAddress; " & _
        "foreach ($ip in @('1.1.1.1','1.0.0.1','2606:4700:4700::1111','2606:4700:4700::1001')) { " & _
        "if ($doh.ServerAddress -contains $ip) { " & _
        "Set-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate 'https://cloudflare-dns.com/dns-query' -AutoUpgrade $true -AllowFallbackToUdp $false " & _
        "} else { " & _
        "Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate 'https://cloudflare-dns.com/dns-query' -AutoUpgrade $true -AllowFallbackToUdp $false " & _
        "} " & _
        "} " & _
        "}; " & _
        "ipconfig /flushdns " & _
        "}"

    RunWait('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "' & $psScript & '"', "", @SW_HIDE)
EndFunc

Func _ResetSystemDNS()

    ; Aktif ağ bağdaştırıcısını bul
    Local $psScript = "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Virtual*' -and $_.InterfaceDescription -notlike '*Hyper-V*' -and $_.InterfaceDescription -notlike '*WSL*' -and $_.Name -notlike '*vEthernet*' -and $_.InterfaceDescription -notlike '*TAP*' -and $_.InterfaceDescription -notlike '*TUN*' -and $_.InterfaceDescription -notlike '*VPN*'} | Select-Object -First 1; "

    ; Her iki sistem için: DNS'i otomatiğe (DHCP) al ve DNS önbelleğini sıfırla
    $psScript &= "Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses; " & _
                 "ipconfig /flushdns;"

    RunWait('powershell -NoProfile -ExecutionPolicy Bypass -Command "' & $psScript & '"', "", @SW_HIDE)
EndFunc

; --- MOTORA GÖRE HAZIR STRATEJİ LİSTESİNİ DOLDURAN FONKSİYON ---
Func _LoadStrategyList($sDefaultToSelect)
    GUICtrlSetData($cmbStrategy, "")
    If $currentEngine == "Zapret2" Then
        GUICtrlSetData($cmbStrategy, "Turk Telekom|Superonline|Vodafone|Turksat Kablonet|Telekom Mobil|Turkcell Mobil|Vodafone Mobil|Benim Stratejim", $sDefaultToSelect)
    Else
        GUICtrlSetData($cmbStrategy, "Turk Telekom|TT Alternatif|Superonline|SOL Alternatif|Vodafone|Turkcell Mobil|Vodafone Mobil|Telekom Mobil|Benim Stratejim", $sDefaultToSelect)
    EndIf
EndFunc

Func _GetActiveStrategyString()
    Local $sel = GUICtrlRead($cmbStrategy)
    If $sel == "Benim Stratejim" Then
        Return StringStripWS(FileRead($strategyFile), 3)
    EndIf

    If $currentEngine == "Zapret2" Then
        Switch $sel
            Case "Turk Telekom"
                Return "--payload=tls_client_hello --lua-desync=multidisorder:pos=2:seqovl=1"
            Case "Superonline"
                Return "--payload=tls_client_hello --lua-desync=multidisorder:pos=2:seqovl=1"
            Case "Vodafone"
                Return '--payload=tls_client_hello --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=5:pos=2:nodrop:repeats=1'
			Case "Turksat Kablonet"
                Return "--payload=tls_client_hello --lua-desync=multidisorder:pos=2:seqovl=1"
			Case "Telekom Mobil"
                Return '--payload=tls_client_hello --lua-desync=fake:blob=0x00000000:ip_ttl=5:repeats=1'
			Case "Turkcell Mobil"
                Return "--payload=tls_client_hello --lua-desync=multidisorder:pos=2:seqovl=1"
			Case "Vodafone Mobil"
                Return "--payload=tls_client_hello --lua-desync=multidisorder:pos=2:seqovl=1"
			EndSwitch
    Else
        Switch $sel
            Case "Turk Telekom"
                Return "--dpi-desync=fake --dpi-desync-ttl=4"
            Case "TT Alternatif"
                Return "--dpi-desync=fake --dpi-desync-ttl=3"
            Case "Superonline"
                Return "--dpi-desync=fake --dpi-desync-fooling=md5sig"
            Case "SOL Alternatif"
                Return "--dpi-desync=fake --dpi-desync-fooling=md5sig --dpi-desync-ttl=3"
			Case "Vodafone"
                Return "--dpi-desync=fake,multisplit --dpi-desync-fooling=badseq --dpi-desync-split-pos=1,midsld"
            Case "Turkcell Mobil"
                Return "--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=3"
            Case "Vodafone Mobil"
                Return "--dpi-desync=multisplit --dpi-desync-split-pos=2"
			Case "Telekom Mobil"
                Return "--dpi-desync=fake --dpi-desync-ttl=5"
        EndSwitch
    EndIf
    Return ""
EndFunc

Func _UpdateFilterForStrategy()
    Local $sStrategy = _GetActiveStrategyString()
    Local $bHasOOB = StringInStr($sStrategy, "oob") > 0

    If $bHasOOB Then
        If Not $bOOBFilterLock Then
            $sFilterSelectionBeforeOOB = GUICtrlRead($cmbFilter)
            $bOOBFilterLock = True
        EndIf
        GUICtrlSetData($cmbFilter, "")
        GUICtrlSetData($cmbFilter, "Filtre Uygulanamaz", "Filtre Uygulanamaz")
        GUICtrlSetColor($cmbFilter, 0xCC0000)
        GUICtrlSetState($cmbFilter, $GUI_DISABLE)
    ElseIf $bOOBFilterLock Then
        GUICtrlSetData($cmbFilter, "")
        GUICtrlSetData($cmbFilter, "Kapalı (Tüm trafik)|Auto (Zapret oluşturur)|Manuel ('hostlist.txt' İçeriği)", $sFilterSelectionBeforeOOB)
        GUICtrlSetColor($cmbFilter, 0x000000)
        GUICtrlSetState($cmbFilter, $GUI_ENABLE)
        $bOOBFilterLock = False
    EndIf
EndFunc

Func _RefreshStrategyLabel()
    Local $sel = GUICtrlRead($cmbStrategy)
    If $sel == "Benim Stratejim" Then
        GUICtrlSetData($lblStrategyInfo, "Strateji Durumu: " & (HasValidStrategy() ? "Mevcut" : "Mevcut Değil"))
    Else
        GUICtrlSetData($lblStrategyInfo, "Strateji Durumu: Hazır Profil (" & $sel & ")")
    EndIf
EndFunc

Func HasValidStrategy()
    If Not FileExists($strategyFile) Then Return False
    Local $sContent = StringStripWS(FileRead($strategyFile), 3)
    Return ($sContent <> "")
EndFunc

Func _SaveConfigAndExit()
    Local $engineVal = ($currentEngine == "Zapret2") ? "0" : "1"
    Local $stratVal = GUICtrlRead($cmbStrategy)

    ; OOB stratejisinde filtre kutusu geçici olarak "Filtre Uygulanamaz" olur.
    ; Config'e bu geçici metni değil, OOB öncesindeki gerçek filtre seçimini kaydet.
    Local $filterSel = GUICtrlRead($cmbFilter)
    If $bOOBFilterLock And $sFilterSelectionBeforeOOB <> "" Then
        $filterSel = $sFilterSelectionBeforeOOB
    EndIf

    Local $filterModeVal = "0"
    If StringInStr($filterSel, "Auto") Then
        $filterModeVal = "1"
    ElseIf StringInStr($filterSel, "Manuel") Then
        $filterModeVal = "2"
    EndIf

    IniWrite($iniPath, "Settings", "ActiveEngine", $engineVal)
    IniWrite($iniPath, "Settings", "ActiveStrategy", $stratVal)
    IniWrite($iniPath, "Settings", "FilterMode", $filterModeVal)

    ExitApp()
EndFunc

Func _UpdateEnginePaths($sEngineSelected)
    If StringInStr($sEngineSelected, "Zapret2") Then
        $currentEngine = "Zapret2"
		$strategyFile = @ScriptDir & "\config\strategy2.txt"
        $winwsPath = @ScriptDir & "\bin\zapret\zapret-winws\winws2.exe"
        GUICtrlSetData($lblFooter, "Zapret2 v1.0.5.2")
    Else
        $currentEngine = "Zapret1"
		$strategyFile = @ScriptDir & "\config\strategy.txt"
        $winwsPath = @ScriptDir & "\bin\zapret\zapret-winws\winws.exe"
        GUICtrlSetData($lblFooter, "Zapret v72.12")
    EndIf
EndFunc

Func ShowGUI()
    GUISetState(@SW_SHOW, $hGUI)
    GUISetState(@SW_RESTORE, $hGUI)
EndFunc

Func ExitApp()
    If $isZapretRunning Then StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
    Exit
EndFunc

Func _SetButtonsState(ByRef $aBtnArray, $iState)
    For $i = 0 To UBound($aBtnArray) - 1
        GUICtrlSetState($aBtnArray[$i], $iState)
    Next
EndFunc

Func CheckDnsPoisoningSilent()

	; Gizli ayar: checkdns=0 ise DNS kontrolünü tamamen atla.
    Local $checkDns = IniRead(@ScriptDir & "\config\config.ini", "Settings", "checkdns", "1")
    If StringStripWS($checkDns, 3) = "0" Then Return False

    Local $safePrefix = "162.159"
    Local $ttPoisonIP = "195.175.254.2"
	Local $iPID = 0
	Local $sIP = ""
	Local $testDomain = "updates.discord.com"

    ; DNS önbelleğini temizle
    RunWait(@ComSpec & " /c ipconfig /flushdns", "", @SW_HIDE)

	; 1. deneme: PATH üzerinden PowerShell
	$iPID = Run( _
		'powershell.exe -NoProfile -NonInteractive -Command "[System.Net.Dns]::GetHostAddresses(' & "'" & $testDomain & "'" & ') | Select-Object -ExpandProperty IPAddressToString | Select-Object -First 1"', _
		"", @SW_HIDE, $STDOUT_CHILD + $STDERR_MERGED)

	; 2. deneme: PowerShell tam yolu

	If $iPID = 0 Then
		$iPID = Run( _
			'"' & @SystemDir & '\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -Command "[System.Net.Dns]::GetHostAddresses(' & "'" & $testDomain & "'" & ') | Select-Object -ExpandProperty IPAddressToString | Select-Object -First 1"', _
			"", @SW_HIDE, $STDOUT_CHILD + $STDERR_MERGED)
	EndIf

	; 3. deneme: nslookup

	If $iPID = 0 Then
		$iPID = Run( _
			@ComSpec & ' /c nslookup ' & $testDomain, _
			"", @SW_HIDE, $STDOUT_CHILD + $STDERR_MERGED)
	EndIf

    If $iPID = 0 Then Return True

    Local $hTimer = TimerInit()

    ; En fazla 5 saniye bekle
    While ProcessExists($iPID)
        $sIP &= StdoutRead($iPID)

        If TimerDiff($hTimer) > 5000 Then
            ProcessClose($iPID)
            Return True
        EndIf

        Sleep(50)
    WEnd

    $sIP &= StdoutRead($iPID)
    $sIP = StringStripWS($sIP, 3)

    If StringInStr($sIP, $safePrefix) Then Return False
    If StringInStr($sIP, $ttPoisonIP) Then Return True

    Return True
EndFunc

Func CheckServiceStatus($manualBtn, $statusID, $lockArray, $chkID)
    Local $iPid = Run(@ComSpec & " /c sc query " & $serviceName, "", @SW_HIDE, $STDOUT_CHILD)
    ProcessWaitClose($iPid)
    Local $sOutput = StdoutRead($iPid)

    If StringInStr($sOutput, "SERVICE_NAME") Then
        Local $iPidCfg = Run(@ComSpec & " /c sc qc " & $serviceName, "", @SW_HIDE, $STDOUT_CHILD)
        ProcessWaitClose($iPidCfg)
        Local $sCfgOut = StdoutRead($iPidCfg)

        ; Servis çalışıyorsa menüyü ayarla
        If StringInStr($sCfgOut, "--hostlist-auto") Then
            GUICtrlSetData($chkID, "Auto (Zapret oluşturur)")
        ElseIf StringInStr($sCfgOut, "--hostlist=") Then
            GUICtrlSetData($chkID, "Manuel ('hostlist.txt' İçeriği)")
        Else
            GUICtrlSetData($chkID, "Kapalı (Tüm trafik)")
        EndIf

        GUICtrlSetState($manualBtn, $GUI_DISABLE)
        _SetButtonsState($lockArray, $GUI_DISABLE)

        ; --- YENİ EKLENEN KISIM: SERVİS DURUMUNU (RUNNING/STOPPED) KONTROL ET ---
        If StringInStr($sOutput, "RUNNING") Then
            GUICtrlSetData($statusID, "SERVİS MODU AKTİF")
            GUICtrlSetColor($statusID, 0x27AE60)
        Else
            ; Servis yüklü ama durmuş!
            GUICtrlSetData($statusID, "SERVİS YÜKLÜ - DURDU")
            GUICtrlSetColor($statusID, 0xC0392B) ; Kırmızı renkle uyar

            ; Kullanıcıyı yalnızca bir kez uyar (sürekli MsgBox çıkıp darlamasın)
            If Not $bServiceStoppedWarned Then
                $bServiceStoppedWarned = True
                MsgBox(16 + 8192, "Uyarı: Servis Durdurulmuş", "Zapret servisi sisteme yüklü ancak şu anda DURMUŞ durumda!" & @CRLF & @CRLF & _
                        "Sisteminizdeki Anti-Cheat yazılımları Zapret'i tehdit olarak algılayıp kapatmış olabilir.")
            EndIf
        EndIf
    Else
        GUICtrlSetState($manualBtn, $GUI_ENABLE)
        _SetButtonsState($lockArray, $GUI_ENABLE)

        GUICtrlSetData($statusID, "ÇALIŞMAYA HAZIR")
        GUICtrlSetColor($statusID, 0x2C3E50)
    EndIf
    _UpdateFilterForStrategy()
EndFunc

Func StartWinws($ctrlID, $statusID, $aBtns)
    Local $activeStrategy = _GetActiveStrategyString()
    If $activeStrategy = "" Then Return MsgBox(48 + 8192, "Hata", "Strateji dosyanız boş.")

    Local $fullCommand = ""

    Local $bStrategyHasOOB = StringInStr($activeStrategy, "oob") > 0
    If $currentEngine = "Zapret2" Then
        Local $luaBaseDir = StringRegExpReplace($winwsPath, "\\[^\\]+$", "") & "\lua\"
        Local $luaParams = ' --lua-init="@' & $luaBaseDir & 'zapret-lib.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-antidpi.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-auto.lua"'
        $fullCommand = '"' & $winwsPath & '" --wf-l3=ipv4 --wf-tcp-out=0-65535 --wf-udp-out=0-65535 '
        If Not $bStrategyHasOOB Then $fullCommand &= '--hostlist-exclude="' & $exludelistPath & '" '
        $fullCommand &= $activeStrategy & $luaParams
    Else
        $fullCommand = '"' & $winwsPath & '" --wf-tcp=0-65535 --wf-udp=0-65535 '
        If Not $bStrategyHasOOB Then $fullCommand &= '--hostlist-exclude="' & $exludelistPath & '" '
        $fullCommand &= $activeStrategy
    EndIf

    ; OOB stratejilerinde hostlist filtreleri uygulanmaz.
    If Not $bStrategyHasOOB Then
        Local $filterSelection = GUICtrlRead($cmbFilter)
        If StringInStr($filterSelection, "Auto") Then
            If Not FileExists($hostlistPath) Then FileWrite($hostlistPath, "")
            $fullCommand &= ' --hostlist-auto="' & $hostlistPath & '"'
        ElseIf StringInStr($filterSelection, "Manuel") Then
            If Not FileExists($normalHostlistPath) Then FileWrite($normalHostlistPath, "discord.com" & @CRLF & "updates.discord.com")
            $fullCommand &= ' --hostlist="' & $normalHostlistPath & '"'
        EndIf
    EndIf

    ;ClipPut($fullCommand)
    $zapretPID = Run($fullCommand, @ScriptDir & "\bin\zapret\zapret-winws\", @SW_HIDE)

    If $zapretPID > 0 Then
        ; --- 1. ARAYÜZÜ ANINDA GÜNCELLE (Kullanıcıya anında tepki ver) ---
        $isZapretRunning = True
        GUICtrlSetData($ctrlID, "DURDUR")
        GUICtrlSetData($statusID, "MANUEL MOD AKTİF")
        GUICtrlSetColor($statusID, 0xE67E22)
        _SetButtonsState($aBtns, $GUI_DISABLE)

        ; --- 2. ARKA PLANDA 1 SANİYE BEKLE VE KONTROL ET ---
        Sleep(500)

        If Not ProcessExists($zapretPID) Then
            ; --- 3. EĞER EXE ÇÖKTÜYSE HER ŞEYİ ESKİ HALİNE (SİSTEM HAZIR) DÖNDÜR ---
            $isZapretRunning = False
            $zapretPID = 0

            GUICtrlSetData($ctrlID, "ZAPRET'İ BAŞLAT")
            ; CheckServiceStatus fonksiyonumuz zaten yazıları yeşil yapıp butonları açma işini kusursuz yapıyor
            CheckServiceStatus($ctrlID, $statusID, $aBtns, $cmbFilter)

            MsgBox(16 + 8192, "Başlatma Hatası", "Zapret motoru başlatılamadı veya anında çöktü!" & @CRLF & @CRLF & _
                    "Sisteminizdeki Anti-Cheat yazılımları Zapret'i tehdit olarak algılayıp kapatmış olabilir.")
        EndIf
    Else
        MsgBox(16 + 8192, "Dosya Bulunamadı", "WinWS exe dosyası bulunamadı veya çalıştırılamadı!")
    EndIf
EndFunc

Func StopWinws($ctrlID, $statusID, $aBtns)
    If ProcessExists($zapretPID) Then ProcessClose($zapretPID)
    While ProcessExists("winws2.exe") Or ProcessExists("winws.exe")
        ProcessClose("winws2.exe")
        ProcessClose("winws.exe")
    WEnd
    RunWait(@ComSpec & " /c sc stop WinDivert & sc delete WinDivert & sc stop WinDivert14 & sc delete WinDivert14 & sc stop monkey & sc delete monkey", "", @SW_HIDE)
    $isZapretRunning = False
    GUICtrlSetData($ctrlID, "ZAPRET'İ BAŞLAT")
    CheckServiceStatus($ctrlID, $statusID, $aBtns, $cmbFilter)
EndFunc

Func InstallServiceClean($chkID)
    Local $activeStrategy = _GetActiveStrategyString()
    If $activeStrategy = "" Then Return MsgBox(48 + 8192, "Hata", "Lütfen hazır stratejilerden birini seçin.")

    Local $binArgs = ""

    Local $bStrategyHasOOB = StringInStr($activeStrategy, "oob") > 0
    If $currentEngine = "Zapret2" Then
        Local $luaBaseDir = StringRegExpReplace($winwsPath, "\\[^\\]+$", "") & "\lua\"
        Local $luaParams = ' --lua-init="@' & $luaBaseDir & 'zapret-lib.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-antidpi.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-auto.lua"'
        $binArgs = '--wf-l3=ipv4 --wf-tcp-out=0-65535 --wf-udp-out=0-65535 '
        If Not $bStrategyHasOOB Then $binArgs &= '--hostlist-exclude="' & $exludelistPath & '" '
        $binArgs &= $activeStrategy & $luaParams
    Else
        $binArgs = '--wf-tcp=0-65535 --wf-udp=0-65535 '
        If Not $bStrategyHasOOB Then $binArgs &= '--hostlist-exclude="' & $exludelistPath & '" '
        $binArgs &= $activeStrategy
    EndIf

    ; OOB stratejilerinde hostlist filtreleri uygulanmaz.
    If Not $bStrategyHasOOB Then
        Local $filterSelection = GUICtrlRead($cmbFilter)
        If StringInStr($filterSelection, "Auto") Then
            If Not FileExists($hostlistPath) Then FileWrite($hostlistPath, "")
            $binArgs &= ' --hostlist-auto="' & $hostlistPath & '"'
        ElseIf StringInStr($filterSelection, "Manuel") Then
            If Not FileExists($normalHostlistPath) Then FileWrite($normalHostlistPath, "discord.com" & @CRLF & "updates.discord.com")
            $binArgs &= ' --hostlist="' & $normalHostlistPath & '"'
        EndIf
    EndIf

    Local $fullBinPath = '"' & $winwsPath & '" ' & $binArgs
    $fullBinPath = StringReplace($fullBinPath, '"', '\"')

    RemoveService()
    Sleep(500)

    If RunWait(@ComSpec & " /c sc create " & $serviceName & ' binPath= "' & $fullBinPath & '" start= auto', "", @SW_HIDE) = 0 Then
        RunWait(@ComSpec & " /c sc start " & $serviceName, "", @SW_HIDE)
        MsgBox(64 + 8192, "Başarılı", "Seçilen profil servis olarak kuruldu.")
    EndIf
EndFunc

Func RemoveService()
    RunWait(@ComSpec & " /c sc stop " & $serviceName & " & sc delete " & $serviceName & " & sc stop WinDivert & sc delete WinDivert & sc stop WinDivert14 & sc delete WinDivert14 & sc stop monkey & sc delete monkey", "", @SW_HIDE)
EndFunc
