#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=bin\zapret\zapret-winws\winws2.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Zapret Multi-Engine Windows Türkiye - Zapret & Zapret2 Kontrol Aracı
#AutoIt3Wrapper_Res_Fileversion=4.7.0.0
#AutoIt3Wrapper_Res_ProductVersion=4.7
#AutoIt3Wrapper_Res_LegalCopyright=Ali Mali
#AutoIt3Wrapper_Res_Language=1055
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <File.au3>
#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ProgressConstants.au3>
#include <TrayConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GuiListView.au3>
#include <Constants.au3>

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
Local $iniStrategy = IniRead($iniPath, "Settings", "ActiveStrategy", "Analiz Sonucu")
; 0 = Kapalı, 1 = Auto, 2 = Manuel
Local $iniFilterMode = IniRead($iniPath, "Settings", "FilterMode", "1")
Local $iniDnscryptInstalled = IniRead($iniPath, "Settings", "DnscryptInstalled", "0") ; <--- YENİ EKLENEN

; --- DİNAMİK MOTOR DEĞİŞKENLERİ ---
Global $strategyFile = ""
Global $winwsPath = ""
Global $blockcheckPath = ""
Global $logPath = ""
Global $currentEngine = "Zapret2"

; --- Global Durum Değişkenleri ---
Global $isZapretRunning = False
Global $zapretPID = 0
Global $pcapPID = 0
Global $v2rayPID = 0
Global $maraPID = 0
Global $lanShareMethod = 0 ; 1 = go-pcap2socks, 2 = v2ray + maradns
Global $bServiceStoppedWarned = False
Global $strategyTestPID = 0

; Blockcheck butonuna art arda tıklanmasını engelleyen kilit.
Global $bBlockcheckBusy = False
Global $hBlockcheckUnlockTimer = 0
Global $bBlockcheckEnableAfterLock = True

; DNSCrypt butonuna art arda tıklamayı engelleyen kilit.
Global $bDnscryptBusy = False
Global $hDnscryptUnlockTimer = 0

; Servis kurulum butonuna art arda tıklamayı engelleyen kilit.
Global $bInstallServiceBusy = False
Global $hInstallServiceUnlockTimer = 0
Global $bInstallServiceEnableAfterLock = True

; --- GUI Tasarımı ---
Global $hGUI = GUICreate("Zapret Windows Türkiye v4.7", 400, 535)
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

; =========================================================================
; --- 2. AYARLAR (DROPDOWN MENÜLER) ---
; =========================================================================
; MOTOR
GUICtrlCreateLabel("Motor:", 50, 168, 120, 20)
GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI")
Local $cmbEngine = GUICtrlCreateCombo("Zapret2 (Yeni LUA Motoru)", 175, 165, 175, 25, $CBS_DROPDOWNLIST)
GUICtrlSetData(-1, "Zapret (Eski Klasik Motor)")
If $iniEngine == "1" Then GUICtrlSetData($cmbEngine, "Zapret (Eski Klasik Motor)", "Zapret (Eski Klasik Motor)")
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetState(-1, $GUI_DISABLE)

; STRATEJİ
GUICtrlCreateLabel("Strateji:", 50, 203, 120, 20)
GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI")
Global $cmbStrategy = GUICtrlCreateCombo("Analiz Sonucu", 175, 200, 175, 25, $CBS_DROPDOWNLIST)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetState(-1, $GUI_DISABLE)

; FİLTRE
GUICtrlCreateLabel("Filtre:", 50, 238, 120, 20)
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
; --- 3. AĞ PAYLAŞIMI VE DİĞER BUTONLAR ---
; =========================================================================
Global $btnLanShare = GUICtrlCreateButton("Ağdaki Cihazlarla Paylaş", 50, 280, 300, 35)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")
GUICtrlSetState(-1, $GUI_DISABLE)

Local $btnAnalyze = GUICtrlCreateButton("ISS Analizi (Blockcheck) Yap", 50, 325, 300, 35)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Local $btnInstallService = GUICtrlCreateButton("Servis Olarak Yükle (Otomatik Başlat)", 50, 370, 300, 35)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

; --- DNSCRYPT BUTONU ---
Local $sInitialDnscryptText = ($iniDnscryptInstalled == "1") ? "[ ✓ ] Dnscrypt-proxy Aktif / Kaldır" : "Dnscrypt-proxy servisi kur"
Global $btnDnscrypt = GUICtrlCreateButton($sInitialDnscryptText, 50, 415, 300, 35)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Local $btnRemoveService = GUICtrlCreateButton("Servis ve Kalıntıları Temizle", 50, 460, 300, 35)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Global $lblFooter = GUICtrlCreateLabel("Zapret Multi-Engine v2.7.0", 0, 505, 400, 20, $SS_CENTER)
GUICtrlSetFont(-1, 10, 400, 0, "Consolas")
GUICtrlSetColor(-1, 0xBDC3C7)

; Düğme Array'lerine yeni butonu ekledik ki sistem hazır olduğunda kilitleri otomatik açılsın
Local $aCriticalButtons[7] = [$btnRunZapret, $btnAnalyze, $btnInstallService, $cmbEngine, $cmbStrategy, $cmbFilter, $btnDnscrypt]
Local $aOtherButtons[7] = [$btnAnalyze, $btnInstallService, $btnRemoveService, $cmbEngine, $cmbStrategy, $cmbFilter, $btnDnscrypt]

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
		GUICtrlSetState($btnDnscrypt, $GUI_ENABLE) ; <--- DNS zehirlense bile bu buton hep tıklanabilir olsun!
        GUICtrlSetData($lblStatusText, "DNS ZEHİRLENMESİ SAPTANDI!")
        GUICtrlSetColor($lblStatusText, 0xC0392B)

        ; 2. TUR: Uygulama DNS değiştirdi ama hala zehirliyse (TT engelliyorsa)
        If $isDnsChangedByApp Then
            MsgBox(48 + 8192, "Kritik Uyarı", "Düz DNS değişikliği işe yaramadı, port 53'e müdahale var." & @CRLF & @CRLF & _
                    "Yapabilecekleriniz şunlar:" & @CRLF & @CRLF & _
                    "1- Program içinden dnscrypt-proxy servisi kurmak" & @CRLF & @CRLF & _
                    "2- YogaDNS gibi harici bir DNS client'i kullanmak")
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
			GUICtrlSetState($btnDnscrypt, $GUI_ENABLE) ; <--- HAYIR dese bile bu buton açık kalsın!
            ExitLoop
        EndIf
    Else
        ; Zehirlenme yoksa her şey normal devam etsin
        CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
		GUICtrlSetState($btnDnscrypt, $GUI_ENABLE) ; <--- Sistem hazır olduğunda butonu aktif et!
        _RefreshStrategyLabel()
        ExitLoop
    EndIf
WEnd

; --- Ana Döngü ---
Local $hProcessTimer = TimerInit() ; ZAMANLAYICIYI BAŞLAT (Bunu While 1'in hemen üstüne koy)

; --- AÇILIŞTA DNSCRYPT SERVİS DURUMUNU KONTROL ET ---
_CheckDnscryptStatus()

While 1
    Local $nMsg = GUIGetMsg()

    ; DNSCrypt çalışırken kuyruğa alınan tıklamaları da atla.
    If $nMsg = $btnDnscrypt And $bDnscryptBusy Then ContinueLoop

    ; Servis kurulumu sırasında kuyruğa alınan tıklamaları da atla.
    If $nMsg = $btnInstallService And $bInstallServiceBusy Then ContinueLoop

    ; Servis kurulum işlemi bittikten 1,5 saniye sonra butonu uygun durumdaysa aç.
    If $bInstallServiceBusy And $hInstallServiceUnlockTimer <> 0 Then
        If TimerDiff($hInstallServiceUnlockTimer) >= 1500 Then
            $bInstallServiceBusy = False
            $hInstallServiceUnlockTimer = 0
            If $bInstallServiceEnableAfterLock And GUICtrlRead($lblStatusText) = "ÇALIŞMAYA HAZIR" Then
                GUICtrlSetState($btnInstallService, $GUI_ENABLE)
            EndIf
        EndIf
    EndIf

    ; DNSCrypt işlemi bittikten sonra 1,5 saniye daha kilitli tut.
    If $bDnscryptBusy And $hDnscryptUnlockTimer <> 0 Then
        If TimerDiff($hDnscryptUnlockTimer) >= 1500 Then
            $bDnscryptBusy = False
            $hDnscryptUnlockTimer = 0
            GUICtrlSetState($btnDnscrypt, $GUI_ENABLE)
        EndIf
    EndIf

    ; Kilitliyken kuyruğa girmiş eski tıklamaları da işlemeden atla.
    If $nMsg = $btnAnalyze And $bBlockcheckBusy Then ContinueLoop

    ; İşlem tamamlandıktan sonra kısa bir süre daha kilidi koru; hızlı/önceden kuyruğa alınmış
    ; tıklamalar bu aralıkta etkisiz kalır.
    If $bBlockcheckBusy And $hBlockcheckUnlockTimer <> 0 Then
        If TimerDiff($hBlockcheckUnlockTimer) >= 1500 Then
            $bBlockcheckBusy = False
            $hBlockcheckUnlockTimer = 0
            If $bBlockcheckEnableAfterLock Then GUICtrlSetState($btnAnalyze, $GUI_ENABLE)
        EndIf
    EndIf

	; --- ZAPRET ÇALIŞMA DURUMU VE ÇÖKME KONTROLÜ ---
    ; Sadece 1000 milisaniyede (1 saniyede) bir kontrol et! CPU'yu yorma.
    If TimerDiff($hProcessTimer) > 1000 Then
		Local $bZapretAlive = ProcessExists("winws.exe") Or ProcessExists("winws2.exe")

		If $bZapretAlive Then
			; 1. Zapret yaşıyorsa LAN Paylaşım butonunu aktif et
			If BitAND(GUICtrlGetState($btnLanShare), $GUI_DISABLE) Then GUICtrlSetState($btnLanShare, $GUI_ENABLE)
		Else
			; 2. Zapret ölmüşse LAN Paylaşım butonunu devre dışı bırak, yazısını sıfırla ve go-pcap2socks'u kapat
			If BitAND(GUICtrlGetState($btnLanShare), $GUI_ENABLE) Then
				GUICtrlSetState($btnLanShare, $GUI_DISABLE)

				If GUICtrlRead($btnLanShare) = "[ ✓ ] Paylaşım Aktif / Durdur" Then
					GUICtrlSetData($btnLanShare, "Ağdaki Cihazlarla Paylaş")
                    GUICtrlSetFont($btnLanShare, 10, 600, 0, "Segoe UI")
                    _StopLanShareProcesses()
				EndIf
			EndIf

			; 3. Zapret ölmüşse VE bizim arayüz hala "Çalışıyor" modundaysa (Çökme veya Harici Kapatma durumu)
			If $isZapretRunning Then
				StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
				; Kullanıcıya Fortnite ve Anti-Cheat uyarısını ver
				MsgBox(16 + 8192, "Uyarı: Zapret Kapatıldı", "Zapret motoru beklenmedik bir şekilde çöktü veya dışarıdan sonlandırıldı!" & @CRLF & @CRLF & _
                    "Sisteminizdeki Anti-Cheat yazılımları Zapret'i tehdit olarak algılayıp kapatmış olabilir.")
			EndIf

			; 4. YENİ: Zapret ölmüşse VE arayüz hala "SERVİS MODU AKTİF" diyorsa (Servis Modu Çökme durumu)
			If GUICtrlRead($lblStatusText) = "SERVİS MODU AKTİF" Then
				; Sistemi kontrol fonksiyonuna yolla, o zaten "DURDU" yazdırıp ortak uyarıyı verecek!
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
            TraySetToolTip("Zapret Windows Türkiye Çalışıyor")

        Case $cmbEngine
            _UpdateEnginePaths(GUICtrlRead($cmbEngine))
            _LoadStrategyList("Analiz Sonucu")
            CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
            _RefreshStrategyLabel()

        Case $cmbStrategy
            _RefreshStrategyLabel()
            _UpdateFilterForStrategy()

		Case $btnAnalyze
            ; Kilit ilk iş olarak, herhangi bir MsgBox açılmadan önce konur.
            If Not $bBlockcheckBusy Then
                $bBlockcheckBusy = True
                $hBlockcheckUnlockTimer = 0
                $bBlockcheckEnableAfterLock = (BitAND(GUICtrlGetState($btnAnalyze), $GUI_ENABLE) <> 0)
                GUICtrlSetState($btnAnalyze, $GUI_DISABLE)

            ; Zapret2 için önceki analiz sonuçları saklanır ve tekrar açılabilir.
            Local $bStartNewAnalysis = True
            If $currentEngine = "Zapret2" And FileExists(_BlockcheckResultsPath()) Then
                Local $iPreviousChoice = MsgBox(35 + 8192, "Önceki Blockcheck Sonucu", _
                    "Önceki analizde bulunan stratejiler açılsın mı?" & @CRLF & @CRLF & _
                    "Evet: Önceki sonuçları aç" & @CRLF & _
                    "Hayır: Yeni analiz başlat" & @CRLF & _
                    "İptal: Vazgeç")

                If $iPreviousChoice = 6 Then
                    Local $aPreviousStrategies[1] = [0]
                    _LoadBlockcheckResults($aPreviousStrategies)
                    If $aPreviousStrategies[0] > 0 Then
                        _ShowStrategyTestWindow($aPreviousStrategies)
                    Else
                        MsgBox(48 + 8192, "Sonuç Bulunamadı", "Kayıtlı sonuç dosyası boş veya okunamadı. Yeni analiz başlatabilirsiniz.")
                    EndIf
                    $bStartNewAnalysis = False
                ElseIf $iPreviousChoice = 2 Then
                    $bStartNewAnalysis = False
                EndIf
                ; Hayır (7) seçilirse yeni analiz akışına devam edilir.
            EndIf

            If $bStartNewAnalysis Then
                If $currentEngine = "Zapret2" Then
					Local $iConfirm = 1
				Else
					Local $iConfirm = MsgBox(33 + 8192, "Bilgi", "Analiz işlemi 5-10 dakika sürebilir." & @CRLF & "Lütfen bitene kadar bekleyin.")
				EndIf

				If $iConfirm = 1 Then
                    _SetButtonsState($aCriticalButtons, $GUI_DISABLE)
                    GUICtrlSetState($btnRemoveService, $GUI_DISABLE)
                    GUICtrlSetData($lblStatusText, "ANALİZ YAPILIYOR...")
                    GUICtrlSetState($pBar, $GUI_SHOW)
                    GUICtrlSetData($lblStrategyInfo, "")
                    GUICtrlSendMsg($pBar, $PBM_SETMARQUEE, True, 50)

                    If $currentEngine = "Zapret2" Then
                        RunBlockcheck2($btnAnalyze)
                    Else
                        RunBlockcheck($btnAnalyze)
                    EndIf

                    GUICtrlSendMsg($pBar, $PBM_SETMARQUEE, False, 0)
                    GUICtrlSetState($pBar, $GUI_HIDE)
                    _SetButtonsState($aCriticalButtons, $GUI_ENABLE)
                    GUICtrlSetState($btnRemoveService, $GUI_ENABLE)
                    CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
                    GUICtrlSetData($lblStatusText, "ANALİZ TAMAMLANDI")
                    _RefreshStrategyLabel()
                EndIf
            EndIf

			GUISetState(@SW_SHOW, $hGUI)
            GUISetState(@SW_RESTORE, $hGUI)
            WinActivate($hGUI)
            WinWaitActive($hGUI, "", 2)

            ; Analiz akışı içindeki genel buton açma işlemleri kilidi kaldıramasın.
            If GUICtrlRead($lblStatusText) = "DNS ZEHİRLENMESİ SAPTANDI!" Then $bBlockcheckEnableAfterLock = False
            GUICtrlSetState($btnAnalyze, $GUI_DISABLE)
            $hBlockcheckUnlockTimer = TimerInit()
            EndIf ; $bBlockcheckBusy kilit bloğu

        Case $btnLanShare
            If GUICtrlRead($btnLanShare) = "Ağdaki Cihazlarla Paylaş" Then
                Local $iShareChoice = _ChooseLanShareMethod()
                If $iShareChoice = 0 Then ContinueLoop
                If $iShareChoice = 2 Then
                    If Not _StartV2rayMaraDNS() Then ContinueLoop
                    $lanShareMethod = 2
                    GUICtrlSetData($btnLanShare, "[ ✓ ] Paylaşım Aktif / Durdur")
                    GUICtrlSetFont($btnLanShare, 10, 800, 0, "Segoe UI")
                    ContinueLoop
                EndIf

                ; Mevcut go-pcap2socks yöntemi
                If Not FileExists(@SystemDir & "\Packet.dll") Then
                    MsgBox(8208, "Eksik Bileşen", "HATA: Sistemde Npcap sürücüsü bulunamadı!" & @CRLF & @CRLF & _
                            "go-pcap2socks motorunun çalışabilmesi için Npcap kurulmalıdır." & @CRLF & _
                            "Lütfen npcap.com adresinden indirip kurun.")
                    ContinueLoop
                EndIf

                Local $hSplash = GUICreate("Lütfen Bekleyin", 280, 80, -1, -1, $WS_POPUP, $WS_EX_TOPMOST)
                GUISetBkColor(0xF2F4F7, $hSplash)
                GUICtrlCreateLabel("Güvenlik Duvarı" & @CRLF & "Kontrolleri Yapılıyor...", 10, 20, 260, 40, $SS_CENTER)
                GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
                GUICtrlSetColor(-1, 0x2C3E50)
                GUISetState(@SW_SHOW, $hSplash)
                Local $targetPcapExe = @ScriptDir & "\bin\go-pcap2socks\go-pcap2socks.exe"

                If Not HasFirewallRule($targetPcapExe) Then
                    GUISetState(@SW_HIDE, $hSplash)
                    RunWait('powershell -NoProfile -Command "Remove-NetFirewallRule -Program ''' & $targetPcapExe & ''' -ErrorAction SilentlyContinue"', "", @SW_HIDE)
                    RunWait(@ComSpec & ' /c netsh advfirewall firewall delete rule name=all program="' & $targetPcapExe & '"', "", @SW_HIDE)
                    MsgBox(8256, "Güvenlik Duvarı İzni", "go-pcap2socks için ağ izni gerekiyor." & @CRLF & @CRLF & _
                            "1. Birazdan Windows Güvenlik Duvarı uyarısı gelecektir." & @CRLF & _
                            "2. Gelen ekranda kutucukları işaretleyip 'Erişime izin ver' butonuna basın.")
                    Local $tmpPID = Run('"' & $targetPcapExe & '"', @ScriptDir & "\bin\go-pcap2socks", @SW_HIDE)
                    MsgBox(8256, "Onay", "Güvenlik duvarı iznini onayladıysanız Tamam'a basın.")
                    If $tmpPID > 0 Then ProcessClose($tmpPID)
                    GUISetState(@SW_SHOW, $hSplash)
                EndIf

                If Not ProcessExists("go-pcap2socks.exe") Then
                    $pcapPID = Run('"' & $targetPcapExe & '"', @ScriptDir & "\bin\go-pcap2socks", @SW_HIDE)
                EndIf
                Sleep(500)
                If Not ProcessExists("go-pcap2socks.exe") Then
                    GUIDelete($hSplash)
                    $pcapPID = 0
                    MsgBox(16 + 8192, "Başlatma Hatası", "HATA: go-pcap2socks başlatılamadı!" & @CRLF & @CRLF & _
                            "Sanal ağ kartı oluşturan VPN vb. programları kapatıp tekrar deneyin.")
                    ContinueLoop
                EndIf
                GUIDelete($hSplash)
                $lanShareMethod = 1
                GUICtrlSetData($btnLanShare, "[ ✓ ] Paylaşım Aktif / Durdur")
                GUICtrlSetFont($btnLanShare, 10, 800, 0, "Segoe UI")
                MsgBox(8256, "go-pcap2socks Ağ Yapılandırması", _
                        "Ağdaki diğer cihazınızda şu IP ayarlarını giriniz:" & @CRLF & @CRLF & _
                        "• IP Aralığı: 172.24.2.10 - 172.24.2.255" & @CRLF & _
                        "• Ağ Geçidi (Gateway): 172.24.2.1" & @CRLF & _
                        "• Alt Ağ Maskesi (Maske): 255.255.0.0" & @CRLF & _
                        "• DNS 1: 1.1.1.1" & @CRLF & "• DNS 2: 8.8.8.8")
            Else
                _StopLanShareProcesses()
                GUICtrlSetData($btnLanShare, "Ağdaki Cihazlarla Paylaş")
                GUICtrlSetFont($btnLanShare, 10, 600, 0, "Segoe UI")
            EndIf

        Case $btnRunZapret
            If $isZapretRunning = False Then
                StartWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
            Else
                StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
            EndIf

        Case $btnInstallService
            ; Kilidi fonksiyonlardan ve olası mesaj pencerelerinden önce koy.
            If $bInstallServiceBusy Then ContinueLoop
            $bInstallServiceBusy = True
            $hInstallServiceUnlockTimer = 0
            $bInstallServiceEnableAfterLock = (BitAND(GUICtrlGetState($btnInstallService), $GUI_ENABLE) <> 0)
            GUICtrlSetState($btnInstallService, $GUI_DISABLE)

            InstallServiceClean($cmbFilter)
            CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)

            ; Yardımcı fonksiyonlar butonu yeniden açmış olsa bile kilit süresince kapalı tut.
            GUICtrlSetState($btnInstallService, $GUI_DISABLE)
            $hInstallServiceUnlockTimer = TimerInit()

        Case $btnDnscrypt
            ; Kilidi ilk iş olarak, dosya kontrolü veya uzun işlemler başlamadan önce koy.
            If $bDnscryptBusy Then ContinueLoop
            $bDnscryptBusy = True
            $hDnscryptUnlockTimer = 0
            GUICtrlSetState($btnDnscrypt, $GUI_DISABLE)

            Local $sProxyDir = @ScriptDir & "\bin\dnscrypt-proxy"
            Local $sProxyPath = $sProxyDir & "\dnscrypt-proxy.exe"

            If Not FileExists($sProxyPath) Then
                MsgBox(16, "Hata", "DNSCrypt dosyası bulunamadı!" & @CRLF & $sProxyPath)
                $hDnscryptUnlockTimer = TimerInit()
                ContinueLoop
            EndIf

            Local $btnText = GUICtrlRead($btnDnscrypt)

            If StringInStr($btnText, "servisi kur") Then
                GUICtrlSetData($lblStatusText, "DNSCRYPT KURULUYOR...")

                RunWait('"' & $sProxyPath & '" -service install', $sProxyDir, @SW_HIDE)
                RunWait('"' & $sProxyPath & '" -service start', $sProxyDir, @SW_HIDE)
                _SetDNS_Localhost()

                GUICtrlSetData($btnDnscrypt, "[ ✓ ] Dnscrypt-proxy Aktif / Kaldır")
                IniWrite($iniPath, "Settings", "DnscryptInstalled", "1")
                ;MsgBox(64 + 8192, "Başarılı", "DNSCrypt servisi kuruldu.")
            Else
                GUICtrlSetData($lblStatusText, "DNSCRYPT KALDIRILIYOR...")

                RunWait('"' & $sProxyPath & '" -service stop', $sProxyDir, @SW_HIDE)
                RunWait('"' & $sProxyPath & '" -service uninstall', $sProxyDir, @SW_HIDE)
                _ResetSystemDNS()

                GUICtrlSetData($btnDnscrypt, "Dnscrypt-proxy servisi kur")
                IniWrite($iniPath, "Settings", "DnscryptInstalled", "0")
                ;MsgBox(64 + 8192, "Bilgi", "DNSCrypt servisi kaldırıldı ve DNS otomatiğe (DHCP) alındı.")
            EndIf

            ; --- AÇILIŞTAKİ GÜVENLİ KONTROL AKIŞININ AYNISI (BAŞTAN AÇILMIŞ GİBİ) ---
            GUICtrlSetData($lblStatusText, "DNS TEST EDİLİYOR...")
            Sleep(1000) ; Ağın ve adaptörün kendine gelmesi için bekleme

			Local $isPoisoned = CheckDnsPoisoningSilent()

            If $isPoisoned Then
				_SetButtonsState($aCriticalButtons, $GUI_DISABLE)
				GUICtrlSetState($btnDnscrypt, $GUI_ENABLE) ; DNS zehirlense bile bu buton hep tıklanabilir olsun
				GUICtrlSetData($lblStatusText, "DNS ZEHİRLENMESİ SAPTANDI!")
				GUICtrlSetColor($lblStatusText, 0xC0392B)
			Else
				; Zehirlenme yoksa her şey normal devam etsin
				CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
				GUICtrlSetState($btnDnscrypt, $GUI_ENABLE)
				_RefreshStrategyLabel()
			EndIf

            ; Yardımcı fonksiyonlar butonu tekrar açmış olsa bile işlem sonunda kilitle.
            ; Kuyrukta bekleyen tıklamalar kilit süresince ana döngüde atlanır.
            GUICtrlSetState($btnDnscrypt, $GUI_DISABLE)
            $hDnscryptUnlockTimer = TimerInit()

		Case $btnRemoveService
            RemoveService()

			; --- DNSCRYPT SERVİSİNİ VE KALINTILARINI DA TEMİZLE ---
            Local $sProxyDir = @ScriptDir & "\bin\dnscrypt-proxy"
            Local $sProxyPath = $sProxyDir & "\dnscrypt-proxy.exe"
            If FileExists($sProxyPath) Then
                RunWait('"' & $sProxyPath & '" -service stop', $sProxyDir, @SW_HIDE)
                RunWait('"' & $sProxyPath & '" -service uninstall', $sProxyDir, @SW_HIDE)
            EndIf
            GUICtrlSetData($btnDnscrypt, "Dnscrypt-proxy servisi kur")
            IniWrite($iniPath, "Settings", "DnscryptInstalled", "0")

            ; --- YENİ EKLENEN ADIM: DNS'i Otomatiğe (DHCP) Al ---
            GUICtrlSetData($lblStatusText, "SİSTEM SIFIRLANIYOR...")
            _ResetSystemDNS()

            $isPoisoned = CheckDnsPoisoningSilent()
            If Not $isPoisoned Then CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
            _RefreshStrategyLabel()
            MsgBox(64 + 8192, "Bilgi", "WinDivert, Zapret, Dnscrypt temizlendi ve DNS ayarları otomatiğe (DHCP) alındı.")

			If $isPoisoned Then
				_SetButtonsState($aCriticalButtons, $GUI_DISABLE)
				GUICtrlSetState($btnDnscrypt, $GUI_ENABLE) ; <--- Servisler temizlense ve zehirlenme olsa bile bu buton hep açık kalacak!
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
    Local $oWMI = ObjGet("winmgmts:\\.\root\cimv2")
    If Not IsObj($oWMI) Then Return False

    Local $oAdapters = $oWMI.ExecQuery( _
        "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True")

    If Not IsObj($oAdapters) Then Return False

    Local $bReset = False

    For $oAdapter In $oAdapters
        If Not IsArray($oAdapter.DefaultIPGateway) Then ContinueLoop

        Local $sDesc = String($oAdapter.Description)
        If StringRegExp($sDesc, _
            "(?i)Virtual|Hyper-V|WSL|TAP|TUN|VPN|VirtualBox|VMware|Loopback|WireGuard|Wintun") Then ContinueLoop

        ; Dinamik arayüz adını bul
        Local $sAdapterName = ""
        Local $oNetAdapters = $oWMI.ExecQuery( _
            "SELECT * FROM Win32_NetworkAdapter WHERE Index=" & $oAdapter.Index)

        For $oNetAdapter In $oNetAdapters
            $sAdapterName = $oNetAdapter.NetConnectionID
            If Not IsString($sAdapterName) Then $sAdapterName = ""
        Next

        If $sAdapterName = "" Then ContinueLoop

        ; IPv4 DNS: DHCP üzerinden otomatik al
        Local $iIPv4 = RunWait(@ComSpec & ' /c netsh interface ipv4 set dnsservers name="' & _
            $sAdapterName & '" source=dhcp', "", @SW_HIDE)

        ; IPv6 DNS: DHCP üzerinden otomatik al
        Local $iIPv6 = RunWait(@ComSpec & ' /c netsh interface ipv6 set dnsservers name="' & _
            $sAdapterName & '" source=dhcp', "", @SW_HIDE)

        If $iIPv4 = 0 And $iIPv6 = 0 Then $bReset = True
    Next

    ; DNS önbelleğini temizle
    RunWait(@ComSpec & " /c ipconfig /flushdns", "", @SW_HIDE)

    Return $bReset
EndFunc

; --- MOTORA GÖRE HAZIR STRATEJİ LİSTESİNİ DOLDURAN FONKSİYON ---
Func _LoadStrategyList($sDefaultToSelect)
    GUICtrlSetData($cmbStrategy, "")
    If $currentEngine == "Zapret2" Then
        GUICtrlSetData($cmbStrategy, "Analiz Sonucu|Turk Telekom|Superonline|Vodafone|Turksat Kablonet|Telekom Mobil|Turkcell Mobil|Vodafone Mobil", $sDefaultToSelect)
    Else
        GUICtrlSetData($cmbStrategy, "Analiz Sonucu|Turk Telekom|TT Alternatif|Superonline|SOL Alternatif|Vodafone|Turkcell Mobil|Vodafone Mobil|Telekom Mobil", $sDefaultToSelect)
    EndIf
EndFunc

Func _GetActiveStrategyString()
    Local $sel = GUICtrlRead($cmbStrategy)
    If $sel == "Analiz Sonucu" Then
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
    If $sel == "Analiz Sonucu" Then
        GUICtrlSetData($lblStrategyInfo, "Strateji Durumu: " & (HasValidStrategy() ? "Mevcut" : "Mevcut Değil (Analiz Gerekli)"))
    Else
        GUICtrlSetData($lblStrategyInfo, "Strateji Durumu: Hazır Profil (" & $sel & ")")
    EndIf
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

    ; Değişkeni burada 'Local' olarak tanımlıyoruz
    Local $dnscryptVal = (StringInStr(GUICtrlRead($btnDnscrypt), "aktif")) ? "1" : "0"

    IniWrite($iniPath, "Settings", "ActiveEngine", $engineVal)
    IniWrite($iniPath, "Settings", "ActiveStrategy", $stratVal)
    IniWrite($iniPath, "Settings", "FilterMode", $filterModeVal)
    IniWrite($iniPath, "Settings", "DnscryptInstalled", $dnscryptVal)

    ExitApp()
EndFunc

Func _UpdateEnginePaths($sEngineSelected)
    If StringInStr($sEngineSelected, "Zapret2") Then
        $currentEngine = "Zapret2"
        $strategyFile = @ScriptDir & "\config\strategy2.txt"
        $winwsPath = @ScriptDir & "\bin\zapret\zapret-winws\winws2.exe"
        $blockcheckPath = @ScriptDir & "\bin\zapret\blockcheck\blockcheck2.cmd"
        $logPath = @ScriptDir & "\bin\zapret\blockcheck\blockcheck2.log"
        GUICtrlSetData($lblFooter, "Zapret2 v1.0.5.2")
    Else
        $currentEngine = "Zapret1"
        $strategyFile = @ScriptDir & "\config\strategy.txt"
        $winwsPath = @ScriptDir & "\bin\zapret\zapret-winws\winws.exe"
        $blockcheckPath = @ScriptDir & "\bin\zapret\blockcheck\blockcheck.cmd"
        $logPath = @ScriptDir & "\bin\zapret\blockcheck\blockcheck.log"
        GUICtrlSetData($lblFooter, "Zapret v72.12")
    EndIf
EndFunc

Func ShowGUI()
    GUISetState(@SW_SHOW, $hGUI)
    GUISetState(@SW_RESTORE, $hGUI)
EndFunc


Func _ChooseLanShareMethod()
    ; Kompakt seçim penceresi: seçenekler yan yana, açıklamalar ayrı satırlarda ortalı.
    Local $hChoice = GUICreate("Ağdaki Cihazlarla Paylaş", 340, 310, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), 0, $hGUI)
    GUISetBkColor(0xF4F6F9, $hChoice)

    Local $lblTitle = GUICtrlCreateLabel("Paylaşım yöntemini seç", 12, 12, 316, 24, $SS_CENTER)
    GUICtrlSetFont($lblTitle, 11, 700, 0, "Segoe UI")
    GUICtrlSetColor($lblTitle, 0x243247)

    Local $radPcap = GUICtrlCreateRadio("go-pcap2socks", 28, 46, 140, 24)
    GUICtrlSetFont($radPcap, 10, 600, 0, "Segoe UI")
    Local $radV2ray = GUICtrlCreateRadio("v2ray && maradns", 176, 46, 140, 24)
    GUICtrlSetFont($radV2ray, 10, 600, 0, "Segoe UI")
    GUICtrlSetState($radPcap, $GUI_CHECKED)

    ; Her madde ayrı Label kontrolünde: AutoIt'in metni yatay birleştirmesi/yorumlaması önlenir.
    Local $lblInfoBg = GUICtrlCreateLabel("", 25, 82, 290, 112)
    GUICtrlSetBkColor($lblInfoBg, 0xDCEBFF)
    Local $lblInfo1 = GUICtrlCreateLabel("", 30, 91, 280, 22, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    Local $lblInfo2 = GUICtrlCreateLabel("", 30, 116, 280, 22, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    Local $lblInfo3 = GUICtrlCreateLabel("", 30, 141, 280, 22, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    Local $lblInfo4 = GUICtrlCreateLabel("", 30, 166, 280, 22, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont($lblInfo1, 10, 600, 0, "Segoe UI")
    GUICtrlSetColor($lblInfo1, 0x173D75)
    GUICtrlSetBkColor($lblInfo1, 0xDCEBFF)
    GUICtrlSetFont($lblInfo2, 10, 600, 0, "Segoe UI")
    GUICtrlSetColor($lblInfo2, 0x173D75)
    GUICtrlSetBkColor($lblInfo2, 0xDCEBFF)
    GUICtrlSetFont($lblInfo3, 10, 600, 0, "Segoe UI")
    GUICtrlSetColor($lblInfo3, 0x173D75)
    GUICtrlSetBkColor($lblInfo3, 0xDCEBFF)
    GUICtrlSetFont($lblInfo4, 10, 600, 0, "Segoe UI")
    GUICtrlSetColor($lblInfo4, 0x173D75)
    GUICtrlSetBkColor($lblInfo4, 0xDCEBFF)
    GUICtrlSetData($lblInfo1, "Trafik sorunsuz aktarılır.")
    GUICtrlSetData($lblInfo2, "NAT bozulmaz.")
    GUICtrlSetData($lblInfo3, "WiFi ile yavaş olabilir.")
	GUICtrlSetData($lblInfo4, "Yavaşsa PC-Modem Kablolu kullanın.")

    Local $btnStart = GUICtrlCreateButton("Başlat", 25, 208, 290, 36)
    GUICtrlSetFont($btnStart, 10, 700, 0, "Segoe UI")

    Local $btnScanDevices = GUICtrlCreateButton("Ağdaki Cihazları Tara", 25, 252, 290, 34)
    GUICtrlSetFont($btnScanDevices, 9, 600, 0, "Segoe UI")

	; Seçim penceresi açıkken ana pencerenin tıklanmasını engelle.
    GUISetState(@SW_DISABLE, $hGUI)


    GUISetState(@SW_SHOW, $hChoice)
    Local $iChoice = 0
    While 1
        Local $nChoice = GUIGetMsg()
        Switch $nChoice
            Case $GUI_EVENT_CLOSE
                ExitLoop
            Case $radPcap
                GUICtrlSetData($lblInfo1, "Trafik sorunsuz aktarılır.")
                GUICtrlSetData($lblInfo2, "NAT bozulmaz.")
                GUICtrlSetData($lblInfo3, "WiFi ile yavaş olabilir.")
				GUICtrlSetData($lblInfo4, "Yavaşsa PC-Modem Kablolu kullanın.")
            Case $radV2ray
                GUICtrlSetData($lblInfo1, "Bazı servislere erişim sorunlu olabilir.")
                GUICtrlSetData($lblInfo2, "NAT bozulur.")
                GUICtrlSetData($lblInfo3, "Hız düşüşü olmaz.")
                GUICtrlSetData($lblInfo4, "Roblox'ta sorun çıkarmaz.")
            Case $btnScanDevices
                _ShowLanDeviceScan($hChoice)
            Case $btnStart
                If BitAND(GUICtrlRead($radPcap), $GUI_CHECKED) = $GUI_CHECKED Then
                    $iChoice = 1
                ElseIf BitAND(GUICtrlRead($radV2ray), $GUI_CHECKED) = $GUI_CHECKED Then
                    $iChoice = 2
                EndIf
                ExitLoop
        EndSwitch
        Sleep(20)
    WEnd
    GUIDelete($hChoice)

    ; Seçim penceresi kapandıktan sonra ana pencereyi etkinleştir ve odağı geri ver.
    GUISetState(@SW_ENABLE, $hGUI)
    GUISetState(@SW_RESTORE, $hGUI)
    WinActivate($hGUI)
    WinWaitActive($hGUI, "", 2)

    Return $iChoice
EndFunc

Func _ShowLanDeviceScan($hParent)
    Local $hScan = GUICreate("Ağdaki Cihazlar", 550, 440, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_MINIMIZEBOX), 0, $hParent)
    GUISetBkColor(0xF4F6F9, $hScan)
    Local $lblScan = GUICtrlCreateLabel("Yerel ağ taranıyor. Bu işlem birkaç saniye sürebilir...", 16, 14, 518, 24, $SS_LEFT)
    GUICtrlSetFont($lblScan, 10, 600, 0, "Segoe UI")
    Local $lblSummary = GUICtrlCreateLabel("Ağdaki cihazlar listeleniyor...", 16, 42, 518, 22)
    GUICtrlSetFont($lblSummary, 9, 400, 0, "Segoe UI")
    Local $lvDevices = GUICtrlCreateListView("IP ADRESİ|MAC ADRESİ|ÜRETİCİ", 16, 72, 518, 310, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS))
    GUICtrlSetFont($lvDevices, 9, 400, 0, "Segoe UI")
    _GUICtrlListView_SetExtendedListViewStyle(GUICtrlGetHandle($lvDevices), BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))
    _GUICtrlListView_SetColumnWidth(GUICtrlGetHandle($lvDevices), 0, 105)
    _GUICtrlListView_SetColumnWidth(GUICtrlGetHandle($lvDevices), 1, 135)
    _GUICtrlListView_SetColumnWidth(GUICtrlGetHandle($lvDevices), 2, 255)
    Local $btnClose = GUICtrlCreateButton("Kapat", 422, 394, 112, 30)
    GUISetState(@SW_SHOW, $hScan)
    GUICtrlSetData($lblSummary, "PowerShell ile yerel alt ağdaki yanıt veren cihazlar aranıyor...")
    Local $sPsPath = @TempDir & "\zapret_lan_scan_" & @AutoItPID & ".ps1"
    Local $sPs = "" & _
            "$ErrorActionPreference = 'SilentlyContinue'" & @CRLF & _
            "$route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric | Select-Object -First 1" & @CRLF & _
            "if (-not $route) { Write-Output 'Varsayılan ağ bağlantısı bulunamadı.'; exit }" & @CRLF & _
            "$ip = Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1" & @CRLF & _
            "if (-not $ip) { Write-Output 'Etkin ağ arayüzünün IPv4 adresi bulunamadı.'; exit }" & @CRLF & _
            "$prefix = [int]$ip.PrefixLength" & @CRLF & _
            "if ($prefix -lt 20) { Write-Output ('Ağ çok geniş (/' + $prefix + '). Güvenli süre sınırı nedeniyle tarama yapılmadı.'); exit }" & @CRLF & _
            "if ($prefix -ge 31) { Write-Output ('Tarama için uygun bir yerel alt ağ bulunamadı: ' + $ip.IPAddress + '/' + $prefix); exit }" & @CRLF & _
            "$oct = [System.Net.IPAddress]::Parse($ip.IPAddress).GetAddressBytes()" & @CRLF & _
            "$net = @()" & @CRLF & _
            "for ($i=0; $i -lt 4; $i++) {" & @CRLF & _
            "  $remaining = $prefix - ($i * 8)" & @CRLF & _
            "  if ($remaining -ge 8) { $mask = 255 } elseif ($remaining -le 0) { $mask = 0 } else { $mask = 256 - [math]::Pow(2, 8 - $remaining) }" & @CRLF & _
            "  $net += ([int]$oct[$i] -band [int]$mask)" & @CRLF & _
            "}" & @CRLF & _
            "$base = ($net -join '.')" & @CRLF & _
            "$count = [int][math]::Pow(2, 32 - $prefix)" & @CRLF & _
            "if ($count -gt 4096) { Write-Output ('Alt ağ çok geniş; tarama yapılmadı: ' + $ip.IPAddress + '/' + $prefix); exit }" & @CRLF & _
            "$tasks = @()" & @CRLF & _
            "$targets = @{}" & @CRLF & _
            "for ($n=1; $n -lt ($count - 1); $n++) {" & @CRLF & _
            "  $v = $n; $parts = @([int]$net[0], [int]$net[1], [int]$net[2], [int]$net[3])" & @CRLF & _
            "  for ($j=3; $j -ge 0; $j--) { $parts[$j] += ($v -band 255); $v = $v -shr 8 }" & @CRLF & _
            "  $addr = $parts -join '.'" & @CRLF & _
            "  if ($addr -eq $ip.IPAddress) { continue }" & @CRLF & _
            "  $ping = New-Object System.Net.NetworkInformation.Ping" & @CRLF & _
            "  $targets[$addr] = $ping" & @CRLF & _
            "  $tasks += $ping.SendPingAsync($addr, 450)" & @CRLF & _
            "}" & @CRLF & _
            "try { [System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]$tasks, 1800) | Out-Null } catch {}" & @CRLF & _
            "$found = @{}" & @CRLF & _
            "foreach ($task in $tasks) {" & @CRLF & _
            "  try { if ($task.IsCompleted -and -not $task.IsFaulted -and $task.Result.Status -eq 'Success') { $found[$task.Result.Address.ToString()] = $true } } catch {}" & @CRLF & _
            "}" & @CRLF & _
            "foreach ($ping in $targets.Values) { try { $ping.Dispose() } catch {} }" & @CRLF & _
            "# Yalnızca etkin arayüzün kendi alt ağındaki komşuları ekle." & @CRLF & _
            "function Test-LocalSubnet([string]$address, [int[]]$network, [int]$prefixLength) {" & @CRLF & _
            "  $bytes = [System.Net.IPAddress]::Parse($address).GetAddressBytes()" & @CRLF & _
            "  for ($k = 0; $k -lt 4; $k++) { $bits = $prefixLength - ($k * 8); if ($bits -ge 8) { $mask = 255 } elseif ($bits -le 0) { $mask = 0 } else { $mask = 256 - [math]::Pow(2, 8 - $bits) }; if (($bytes[$k] -band [int]$mask) -ne ($network[$k] -band [int]$mask)) { return $false } }" & @CRLF & _
            "  return $true" & @CRLF & _
            "}" & @CRLF & _
            "Get-NetNeighbor -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne $ip.IPAddress -and $_.IPAddress -notmatch '^(22[4-9]|23[0-9])\.' -and $_.IPAddress -notlike '255.*' -and $_.State -notin @('Unreachable','Incomplete') -and (Test-LocalSubnet $_.IPAddress $net $prefix) } | ForEach-Object { $found[$_.IPAddress] = $true }" & @CRLF & _
            "if ($found.Count -eq 0) { Write-Output ('Yanıt veren cihaz bulunamadı. Yerel IP: ' + $ip.IPAddress + '/' + $prefix + '. Bazı cihazlar taramaya yanıt vermeyebilir.'); exit }" & @CRLF & _
            "Write-Output ('Bilgisayar: ' + $ip.IPAddress + '/' + $prefix)" & @CRLF & _
            "Write-Output ('Bulunan cihaz sayısı: ' + $found.Count)" & @CRLF & _
            "Write-Output ''" & @CRLF & _
            "Write-Output 'IP ADRESI`tMAC ADRESI`tURETICI'" & @CRLF & _
            "foreach ($addr in ($found.Keys | Sort-Object { [version]$_ })) {" & @CRLF & _
            "  $neighbor = Get-NetNeighbor -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -IPAddress $addr | Select-Object -First 1" & @CRLF & _
            "  $mac = if ($neighbor) { $neighbor.LinkLayerAddress } else { 'Bilinmiyor' }" & @CRLF & _
            "  Write-Output ($addr + ""`t"" + $mac + ""`t"" + ('Bilgiler getiriliyor...'))" & @CRLF & _
            "}" & @CRLF


    Local $hFile = FileOpen($sPsPath, 2 + 128)
    If $hFile = -1 Then
        GUICtrlSetData($lblSummary, "Tarama dosyası oluşturulamadı.")
    Else
        FileWrite($hFile, $sPs)
        FileClose($hFile)
        Local $iPID = Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' & $sPsPath & '"', @SystemDir, @SW_HIDE, $STDOUT_CHILD + $STDERR_CHILD)
        If $iPID = 0 Then
            GUICtrlSetData($lblSummary, "PowerShell başlatılamadı.")
        Else
            Local $sOutput = "", $sPending = ""
            Local $aDeviceIPs[1], $aDeviceItems[1], $iDeviceCount = 0, $sNetwork = ""
            While ProcessExists($iPID)
                $sPending &= StdoutRead($iPID)
                $sPending &= StderrRead($iPID)
                While StringInStr($sPending, @LF)
                    Local $iNL = StringInStr($sPending, @LF)
                    Local $sLine = StringStripWS(StringLeft($sPending, $iNL - 1), 3)
                    $sPending = StringTrimLeft($sPending, $iNL)
                    $sOutput &= $sLine & @LF
                    If StringLeft($sLine, 11) = "Bilgisayar:" Then $sNetwork = $sLine
                    If StringLeft($sLine, 20) = "Bulunan cihaz sayısı:" Then GUICtrlSetData($lblSummary, $sLine)
                    If StringInStr($sLine, @TAB) Then
                        Local $aCols = StringSplit($sLine, @TAB, 2)
                        If UBound($aCols) >= 3 Then
                            If $aCols[0] = "UPDATE" Then
                                For $k = 0 To $iDeviceCount - 1
                                    If $aDeviceIPs[$k] = $aCols[1] Then
                                        _GUICtrlListView_SetItemText(GUICtrlGetHandle($lvDevices), $aDeviceItems[$k], $aCols[2], 2)
                                        ExitLoop
                                    EndIf
                                Next
                            ElseIf StringRegExp($aCols[0], '^\d{1,3}(?:\.\d{1,3}){3}$') Then
                                Local $iItem = _GUICtrlListView_GetItemCount(GUICtrlGetHandle($lvDevices))
                                GUICtrlCreateListViewItem($aCols[0] & "|" & $aCols[1] & "|" & $aCols[2], $lvDevices)
                                ReDim $aDeviceIPs[$iDeviceCount + 1]
                                ReDim $aDeviceItems[$iDeviceCount + 1]
                                $aDeviceIPs[$iDeviceCount] = $aCols[0]
                                $aDeviceItems[$iDeviceCount] = $iItem
                                $iDeviceCount += 1
                            EndIf
                        EndIf
                    EndIf
                    If StringInStr($sLine, "bulunamadı") Then GUICtrlSetData($lblSummary, $sLine)
                WEnd
                Sleep(40)
            WEnd
            $sPending &= StdoutRead($iPID)
            If $sNetwork <> "" Then GUICtrlSetData($lblSummary, $sNetwork & "     •     Bulunan cihaz: " & $iDeviceCount)
            If $iDeviceCount = 0 And StringStripWS($sOutput & $sPending, 8) <> "" Then GUICtrlSetData($lblSummary, StringLeft($sOutput & $sPending, 180))

            ; Ağ taraması tamamlandı. Şimdi OUI veritabanını ayrı bir PowerShell işlemiyle indirip mevcut satırları güncelle.
            If $iDeviceCount > 0 Then
                GUICtrlSetData($lblScan, "Üretici bilgileri alınıyor...")
                GUICtrlSetData($lblSummary, "Üretici bilgileri güncelleniyor...")

                Local $sVendorInput = @TempDir & "\zapret_oui_input_" & @AutoItPID & ".txt"
                Local $sVendorOutput = @TempDir & "\zapret_oui_output_" & @AutoItPID & ".txt"
                Local $sVendorPsPath = @TempDir & "\zapret_oui_lookup_" & @AutoItPID & ".ps1"
                Local $sVendorUrl = "https://raw.githubusercontent.com/alimali54/zapret-win-turkey/refs/heads/master/oui.txt"
                Local $hVendorInput = FileOpen($sVendorInput, 2 + 128)

                If $hVendorInput <> -1 Then
                    For $j = 0 To $iDeviceCount - 1
                        Local $sMacForLookup = _GUICtrlListView_GetItemText(GUICtrlGetHandle($lvDevices), $aDeviceItems[$j], 1)
                        FileWriteLine($hVendorInput, $j & @TAB & $sMacForLookup)
                    Next
                    FileClose($hVendorInput)

                    Local $sVendorPS = "$ErrorActionPreference = 'Stop'" & @CRLF & _
                        "$url = '" & $sVendorUrl & "'" & @CRLF & _
                        "$inputPath = '" & StringReplace($sVendorInput, "'", "''") & "'" & @CRLF & _
                        "$outputPath = '" & StringReplace($sVendorOutput, "'", "''") & "'" & @CRLF & _
                        "$ouiPath = Join-Path $env:TEMP 'zapret_oui_db.txt'" & @CRLF & _
                        "try {" & @CRLF & _
                        "  if (-not (Test-Path $ouiPath)) { Invoke-WebRequest -Uri $url -OutFile $ouiPath -UseBasicParsing -TimeoutSec 20 }" & @CRLF & _
                        "  $vendors = @{}" & @CRLF & _
                        "  foreach ($line in [System.IO.File]::ReadLines($ouiPath)) {" & @CRLF & _
                        "    if ($line -match '^\s*([0-9A-Fa-f]{2}(?:-[0-9A-Fa-f]{2}){2})\s+\(hex\)\s+(.+?)\s*$') {" & @CRLF & _
                        "      $prefix = $matches[1].Replace('-', '').ToUpperInvariant()" & @CRLF & _
                        "      if (-not $vendors.ContainsKey($prefix)) { $vendors[$prefix] = $matches[2].Trim() }" & @CRLF & _
                        "    }" & @CRLF & _
                        "  }" & @CRLF & _
                        "  $result = foreach ($item in [System.IO.File]::ReadLines($inputPath)) {" & @CRLF & _
                        "    $parts = $item.Split([char]9, 2)" & @CRLF & _
                        "    if ($parts.Count -ge 2) {" & @CRLF & _
                        "      $mac = ($parts[1] -replace '[:-]', '').ToUpperInvariant()" & @CRLF & _
                        "      $prefix = if ($mac.Length -ge 6) { $mac.Substring(0, 6) } else { '' }" & @CRLF & _
                        "      $vendor = if ($vendors.ContainsKey($prefix)) { $vendors[$prefix] } else { ('Bilinmeyen ' + [char]0x00DC + 'retici') }" & @CRLF & _
                        "      $parts[0] + [char]9 + $vendor" & @CRLF & _
                        "    }" & @CRLF & _
                        "  }" & @CRLF & _
                        "  [System.IO.File]::WriteAllLines($outputPath, [string[]]$result, [System.Text.Encoding]::UTF8)" & @CRLF & _
                        "} catch { [System.IO.File]::WriteAllText($outputPath, 'ERROR' + [char]9 + $_.Exception.Message, [System.Text.Encoding]::UTF8); exit 1 }" & @CRLF

                    If FileWrite($sVendorPsPath, $sVendorPS) Then
                        Local $iVendorPID = Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' & $sVendorPsPath & '"', @SystemDir, @SW_HIDE)
                        If $iVendorPID <> 0 Then
                            ProcessWaitClose($iVendorPID)
                            If FileExists($sVendorOutput) Then
                                Local $hVendorOutput = FileOpen($sVendorOutput, 128)
                                If $hVendorOutput <> -1 Then
                                    While 1
                                        Local $sVendorLine = FileReadLine($hVendorOutput)
                                        If @error Then ExitLoop
                                        Local $aVendorResult = StringSplit($sVendorLine, @TAB, 2)
                                        If UBound($aVendorResult) >= 2 Then
                                            If $aVendorResult[0] = "ERROR" Then
                                                GUICtrlSetData($lblSummary, "OUI indirme hatası: " & $aVendorResult[1])
                                            ElseIf StringIsInt($aVendorResult[0]) Then
                                                Local $iVendorIndex = Number($aVendorResult[0])
                                                If $iVendorIndex >= 0 And $iVendorIndex < $iDeviceCount Then
                                                    _GUICtrlListView_SetItemText(GUICtrlGetHandle($lvDevices), $aDeviceItems[$iVendorIndex], $aVendorResult[1], 2)
                                                EndIf
                                            EndIf
                                        EndIf
                                    WEnd
                                    FileClose($hVendorOutput)
                                EndIf
                            Else
                                GUICtrlSetData($lblSummary, "OUI sonuç dosyası oluşturulamadı.")
                            EndIf
                        Else
                            GUICtrlSetData($lblSummary, "Üretici sorgusu için PowerShell başlatılamadı.")
                        EndIf
                    Else
                        GUICtrlSetData($lblSummary, "Üretici sorgusu betiği oluşturulamadı.")
                    EndIf
                Else
                    GUICtrlSetData($lblSummary, "Geçici MAC listesi oluşturulamadı.")
                EndIf

                If FileExists($sVendorInput) Then FileDelete($sVendorInput)
                If FileExists($sVendorOutput) Then FileDelete($sVendorOutput)
                If FileExists($sVendorPsPath) Then FileDelete($sVendorPsPath)
                GUICtrlSetData($lblScan, "Ağdaki Cihazlar")
                If StringInStr(GUICtrlRead($lblSummary), "OUI indirme hatası") = 0 Then _
                    GUICtrlSetData($lblSummary, $sNetwork & "     •     Bulunan cihaz: " & $iDeviceCount & " • Üretici bilgileri güncellendi")
            EndIf
        EndIf
        FileDelete($sPsPath)
    EndIf

    GUICtrlSetData($lblScan, "Ağdaki Cihazlar")
    While 1
        Local $iMsg = GUIGetMsg()
        If $iMsg = $GUI_EVENT_CLOSE Or $iMsg = $btnClose Then ExitLoop
        Sleep(20)
    WEnd
    GUIDelete($hScan)
    GUISetState(@SW_RESTORE, $hParent)
    WinActivate($hParent)
EndFunc

Func _StartV2rayMaraDNS()
    Local $sV2rayDir = @ScriptDir & "\bin\v2ray"
    Local $sMaraDir = @ScriptDir & "\bin\maradns"
    Local $sZoneFile = $sMaraDir & "\zone-redirect-all.txt"
    Local $sV2rayCmd = $sV2rayDir & "\v2ray-run.cmd"
    Local $sMaraCmd = $sMaraDir & "\mara-run.cmd"

    If Not FileExists($sV2rayCmd) Or Not FileExists($sMaraCmd) Or Not FileExists($sZoneFile) Then
        MsgBox(16 + 8192, "Dosyalar Eksik", "v2ray + maradns başlatılamadı. Şu dosyaların varlığını kontrol et:" & @CRLF & _
                $sV2rayCmd & @CRLF & $sMaraCmd & @CRLF & $sZoneFile)
        Return False
    EndIf

    _StopV2rayMaraDNS()
    Local $sIP = _GetPhysicalIPv4()
    If $sIP = "" Or $sIP = "0.0.0.0" Then
        MsgBox(16 + 8192, "IP Bulunamadı", "Bilgisayarın yerel IPv4 adresi bulunamadı.")
        Return False
    EndIf

    Local $hZone = FileOpen($sZoneFile, 0)
    If $hZone = -1 Then
        MsgBox(16 + 8192, "Dosya Okunamadı", "MaraDNS zone dosyası okunamadı:" & @CRLF & $sZoneFile)
        Return False
    EndIf
    Local $sZoneText = FileRead($hZone)
    FileClose($hZone)
    Local $aZoneLines = StringSplit(StringStripCR($sZoneText), @LF, 2)
    If UBound($aZoneLines) < 2 Then
        MsgBox(16 + 8192, "Zone Dosyası Hatalı", "zone-redirect-all.txt dosyasında beklenen satır yapısı bulunamadı.")
        Return False
    EndIf

    ; VBS'deki gibi sondan bir önceki satırı yerel IP ile değiştir.
    Local $iIPLine = UBound($aZoneLines) - 2
    $aZoneLines[$iIPLine] = "* " & $sIP
    Local $sNewZone = ""
    For $i = 0 To UBound($aZoneLines) - 1
        $sNewZone &= $aZoneLines[$i]
        If $i < UBound($aZoneLines) - 1 Then $sNewZone &= @CRLF
    Next
    Local $hZoneOut = FileOpen($sZoneFile, 2)
    If $hZoneOut = -1 Then
        MsgBox(16 + 8192, "Dosya Yazılamadı", "MaraDNS zone dosyası güncellenemedi.")
        Return False
    EndIf
    FileWrite($hZoneOut, $sNewZone)
    FileClose($hZoneOut)

    ; go-pcap2socks ile aynı izin akışı: mevcut izni kontrol et,
    ; yoksa uygulamayı başlatıp Windows'un kendi izin istemini göster.
    ; Program kendisi güvenlik duvarı kuralı oluşturmaz.
    Local $sV2rayExe = $sV2rayDir & "\v2ray.exe"
    Local $sMaraExe = $sMaraDir & "\maradns.exe"
    If Not FileExists($sV2rayExe) Or Not FileExists($sMaraExe) Then
        MsgBox(16 + 8192, "Dosyalar Eksik", "Güvenlik duvarı kontrolü için v2ray.exe ve maradns.exe dosyaları bulunamadı." & @CRLF & _
                "Kontrol edilen yollar:" & @CRLF & $sV2rayExe & @CRLF & $sMaraExe)
        Return False
    EndIf

    Local $hFwSplash = GUICreate("Lütfen Bekleyin", 280, 80, -1, -1, $WS_POPUP, $WS_EX_TOPMOST)
    GUISetBkColor(0xF2F4F7, $hFwSplash)
    GUICtrlCreateLabel("Güvenlik Duvarı" & @CRLF & "Kontrolleri Yapılıyor...", 10, 20, 260, 40, $SS_CENTER)
    GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x2C3E50)
    GUISetState(@SW_SHOW, $hFwSplash)

                If Not HasFirewallRule($sV2rayExe) Then
                    GUISetState(@SW_HIDE, $hFwSplash)
                    RunWait('powershell -NoProfile -Command "Remove-NetFirewallRule -Program ''' & $sV2rayExe & ''' -ErrorAction SilentlyContinue"', "", @SW_HIDE)
                    RunWait(@ComSpec & ' /c netsh advfirewall firewall delete rule name=all program="' & $sV2rayExe & '"', "", @SW_HIDE)
                    MsgBox(8256, "Güvenlik Duvarı İzni", "v2ray için ağ izni gerekiyor." & @CRLF & @CRLF & _
                            "1. Birazdan Windows Güvenlik Duvarı uyarısı gelecektir." & @CRLF & _
                            "2. Gelen ekranda kutucukları işaretleyip 'Erişime izin ver' butonuna basın.")
                    Local $tmpPID = Run('"' & $sV2rayCmd & '"', @ScriptDir & "\bin\v2ray", @SW_HIDE)
                    MsgBox(8256, "Onay", "Güvenlik duvarı iznini onayladıysanız Tamam'a basın.")
                    If $tmpPID > 0 Then ProcessClose("v2ray.exe")
                    GUISetState(@SW_SHOW, $hFwSplash)
                EndIf

				If Not HasFirewallRule($sMaraExe) Then
                    GUISetState(@SW_HIDE, $hFwSplash)
                    RunWait('powershell -NoProfile -Command "Remove-NetFirewallRule -Program ''' & $sMaraExe & ''' -ErrorAction SilentlyContinue"', "", @SW_HIDE)
                    RunWait(@ComSpec & ' /c netsh advfirewall firewall delete rule name=all program="' & $sMaraExe & '"', "", @SW_HIDE)
                    MsgBox(8256, "Güvenlik Duvarı İzni", "maradns için ağ izni gerekiyor." & @CRLF & @CRLF & _
                            "1. Birazdan Windows Güvenlik Duvarı uyarısı gelecektir." & @CRLF & _
                            "2. Gelen ekranda kutucukları işaretleyip 'Erişime izin ver' butonuna basın.")
                    Local $tmpPID = Run('"' & $sMaraCmd & '"', @ScriptDir & "\bin\maradns", @SW_HIDE)
                    MsgBox(8256, "Onay", "Güvenlik duvarı iznini onayladıysanız Tamam'a basın.")
                    If $tmpPID > 0 Then ProcessClose("maradns.exe")
                    GUISetState(@SW_SHOW, $hFwSplash)
                EndIf
	GUIDelete($hFwSplash)

	$v2rayPID = Run(@ComSpec & ' /k "' & $sV2rayCmd & '"', $sV2rayDir, @SW_HIDE)
    Sleep(100)
    $maraPID = Run(@ComSpec & ' /k "' & $sMaraCmd & '"', $sMaraDir, @SW_HIDE)
    Sleep(300)

    If Not ProcessExists("v2ray.exe") Or Not ProcessExists("maradns.exe") Then
        MsgBox(48 + 8192, "Başlatma Kontrolü", "v2ray ve/veya maradns işlemi başlatılamadı.")
		Return False
	Else
		MsgBox(64 + 8192, "v2ray & MaraDNS", "Ağdaki diğer cihazınızda DNS adresi olarak şu IP'yi girin:" & @CRLF & @CRLF & $sIP)
		Return True
    EndIf


EndFunc

Func _GetPhysicalIPv4()
    Local $oWMI = ObjGet("winmgmts:\\.\root\cimv2")
    If Not IsObj($oWMI) Then Return ""

    Local $sQuery = "SELECT IPAddress, DefaultIPGateway, Description " & _
                    "FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True"

    Local $oAdapters = $oWMI.ExecQuery($sQuery)
    If Not IsObj($oAdapters) Then Return ""

    For $oAdapter In $oAdapters
        If Not IsArray($oAdapter.IPAddress) Then ContinueLoop
        If Not IsArray($oAdapter.DefaultIPGateway) Then ContinueLoop

        Local $sDesc = String($oAdapter.Description)

        If StringRegExp($sDesc, "(?i)Virtual|Hyper-V|WSL|TAP|TUN|VPN|VirtualBox|VMware|Loopback|WireGuard|Wintun") Then
            ContinueLoop
        EndIf

        For $sAddr In $oAdapter.IPAddress
            If StringRegExp($sAddr, "^\d{1,3}(\.\d{1,3}){3}$") _
                    And Not StringRegExp($sAddr, "^(127\.|169\.254\.)") _
                    And $sAddr <> "0.0.0.0" Then
                Return $sAddr
            EndIf
        Next
    Next

    Return ""
EndFunc

Func _StopV2rayMaraDNS()
    If ProcessExists("v2ray.exe") Then RunWait(@ComSpec & " /c taskkill /F /IM v2ray.exe /T", "", @SW_HIDE)
    If ProcessExists("maradns.exe") Then RunWait(@ComSpec & " /c taskkill /F /IM maradns.exe /T", "", @SW_HIDE)
    If $v2rayPID > 0 And ProcessExists($v2rayPID) Then ProcessClose($v2rayPID)
    If $maraPID > 0 And ProcessExists($maraPID) Then ProcessClose($maraPID)
    $v2rayPID = 0
    $maraPID = 0
EndFunc

Func _StopLanShareProcesses()
    If ProcessExists("go-pcap2socks.exe") Then RunWait(@ComSpec & " /c taskkill /F /IM go-pcap2socks.exe /T", "", @SW_HIDE)
    $pcapPID = 0
    _StopV2rayMaraDNS()
    $lanShareMethod = 0
EndFunc

Func ExitApp()
    If $isZapretRunning Then StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
    _StopLanShareProcesses()
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

		GUICtrlSetState($btnDnscrypt, $GUI_ENABLE)

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
    If $activeStrategy = "" Then Return MsgBox(48 + 8192, "Hata", "Strateji bulunamadı. Önce analiz yapın.")

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
    If $activeStrategy = "" Then Return MsgBox(48 + 8192, "Hata", "Strateji bulunamadı. Önce analiz yapın.")

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

; =========================================================================
; --- ZAPRET 1 ANALİZ FONKSİYONLARI ---
; =========================================================================
Func RunBlockcheck($ctrlID)
    Local $isNoBypassNeeded = False
    If FileExists($logPath) Then FileDelete($logPath)
    Local $bashPath = @ScriptDir & "\bin\zapret\cygwin\bin\bash.exe"
    Local $shScriptPath = @ScriptDir & "\bin\zapret\blockcheck\zapret\blog.sh"
    Local $sCommand = '"' & $bashPath & '" -i "' & $shScriptPath & '"'
    Local $iPidBash = Run($sCommand, @ScriptDir & "\bin\zapret\blockcheck", @SW_HIDE)
    Local $hWaitTimer = TimerInit()
    While Not FileExists($logPath)
        Sleep(100)
        If TimerDiff($hWaitTimer) > 10000 Then ExitLoop
    WEnd
    While ProcessExists("bash.exe")
        Sleep(1000)
        Local $hFile = FileOpen($logPath, 0)
        If $hFile <> -1 Then
            Local $sContent = FileRead($hFile)
            FileClose($hFile)
            If StringInStr($sContent, "working without bypass") Or StringInStr($sContent, "not blocked") Then
                $isNoBypassNeeded = True
                ExitLoop
            EndIf
        EndIf
    WEnd
    If $isNoBypassNeeded Then
        MsgBox(64 + 8192, "Bilgi: Zapret1 Analiz Tamamlandı", _
                "İnternet hattınızda herhangi bir DPI / Sansür kısıtlaması saptanmadı!")
    Else
        ExtractSummary($logPath)
    EndIf
EndFunc

Func ExtractSummary($filePath)
    Local $aLogContent
    If Not _FileReadToArray($filePath, $aLogContent) Then Return
    Local $found = False, $strategy = ""
    For $i = $aLogContent[0] To 1 Step -1
        If StringInStr($aLogContent[$i], "SUMMARY") Then
            Local $fullLine = $aLogContent[$i + 1]
            Local $pos = StringInStr($fullLine, "--dpi")
            If $pos > 0 Then
                $strategy = StringStripWS(StringMid($fullLine, $pos), 3)
                $found = True
                ExitLoop
            EndIf
        EndIf
    Next
    If $found And $strategy <> "" Then
        Local $sFormatted = _FormatStrategyQuotes($strategy)
        Local $hFile = FileOpen($strategyFile, 2)
        If $hFile <> -1 Then
            FileWrite($hFile, $sFormatted)
            FileClose($hFile)
            MsgBox(64 + 8192, "Başarılı", "Analiz tamamlandı. Zapret1 için strateji ayıklandı.")
        EndIf
    Else
        MsgBox(16 + 8192, "Başarısız", "Strateji bulunamadı.")
    EndIf
EndFunc

; =========================================================================
; --- ZAPRET 2 ANALİZ FONKSİYONU ---
; =========================================================================
Func _BlockcheckResultsPath()
    Return @ScriptDir & "\config\blockcheck2_strategies.txt"
EndFunc

Func _SaveBlockcheckResults(ByRef $aStrategies)
    Local $sPath = _BlockcheckResultsPath()
    Local $hFile = FileOpen($sPath, 2)
    If $hFile = -1 Then Return False

    For $i = 1 To $aStrategies[0]
        FileWriteLine($hFile, $aStrategies[$i])
    Next
    FileClose($hFile)
    Return True
EndFunc

Func _LoadBlockcheckResults(ByRef $aStrategies)
    Local $sPath = _BlockcheckResultsPath()
    If Not FileExists($sPath) Then Return False

    Local $sContent = FileRead($sPath)
    If @error Or $sContent = "" Then Return False

    Local $aLines = StringSplit(StringStripCR($sContent), @LF, 1)
    Local $aLoaded[1] = [0]
    For $i = 1 To $aLines[0]
        Local $sStrategy = StringStripWS($aLines[$i], 3)
        If $sStrategy = "" Then ContinueLoop

        Local $bExists = False
        For $j = 1 To $aLoaded[0]
            If $aLoaded[$j] = $sStrategy Then
                $bExists = True
                ExitLoop
            EndIf
        Next
        If Not $bExists Then
            ReDim $aLoaded[UBound($aLoaded) + 1]
            $aLoaded[0] += 1
            $aLoaded[$aLoaded[0]] = $sStrategy
        EndIf
    Next

    $aStrategies = $aLoaded
    Return ($aStrategies[0] > 0)
EndFunc

Func RunBlockcheck2($ctrlID)
    ; Ana pencereyi modal olarak kilitle; popup sadece ana pencerenin önünde kalsın.
    GUISetState(@SW_DISABLE, $hGUI)

    Local $isNoBypassNeeded = False
    Local $bUserStopped = False
    Local $aStrategies[1] = [0]

    ; Kullanıcı yeni analiz seçtiği için eski sonuçları geçersiz kıl.
    If FileExists(_BlockcheckResultsPath()) Then FileDelete(_BlockcheckResultsPath())
    If FileExists($logPath) Then FileDelete($logPath)
	;config.ini içinde testdomain varsa blockcheck2.sh dosyasına yaz
	If Not _PrepareTestDomain() Then Return

    Local $hScanGUI = GUICreate("Zapret2 Blockcheck", 360, 170, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), 0, $hGUI)
    GUISetBkColor(0xFFFFFF, $hScanGUI)
    Local $lblScanTitle = GUICtrlCreateLabel("Taranıyor...", 18, 16, 324, 25, $SS_CENTER)
    GUICtrlSetFont($lblScanTitle, 12, 700, 0, "Segoe UI")
    Local $lblScanElapsed = GUICtrlCreateLabel("Geçen süre: 00:00", 18, 53, 324, 22, $SS_CENTER)
    GUICtrlSetFont($lblScanElapsed, 10, 400, 0, "Segoe UI")
    Local $lblScanCount = GUICtrlCreateLabel("Bulunan strateji: 0", 18, 80, 324, 22, $SS_CENTER)
    GUICtrlSetFont($lblScanCount, 10, 600, 0, "Segoe UI")
    Local $btnStopScan = GUICtrlCreateButton("Analizi Durdur", 95, 115, 170, 32)
    GUISetState(@SW_SHOW, $hScanGUI)

    Local $bashPath = @ScriptDir & "\bin\zapret\cygwin\bin\bash.exe"
    Local $shScriptPath = @ScriptDir & "\bin\zapret\blockcheck\zapret2\blog.sh"
    Local $sCommand = '"' & $bashPath & '" -i "' & $shScriptPath & '"'
    Local $iPidBash = Run($sCommand, @ScriptDir & "\bin\zapret\blockcheck", @SW_HIDE)

    If $iPidBash = 0 Then
        GUIDelete($hScanGUI)
        GUISetState(@SW_ENABLE, $hGUI)
        GUISetState(@SW_SHOW, $hGUI)
        MsgBox(16 + 8192, "Analiz Başlatılamadı", "Blockcheck2 süreci başlatılamadı.")
        Return
    EndIf

    Local $hTimer = TimerInit()
    Local $hUiTimer = TimerInit()

    ; İlk çalışan stratejide durmak yerine, analiz devam ettiği sürece
    ; logdaki tüm benzersiz AVAILABLE stratejilerini topluyoruz.

	Local $hLogTimer = TimerInit()
    While ProcessExists($iPidBash)
        Local $nMsg = GUIGetMsg()

		If $nMsg = $btnStopScan Or $nMsg = $GUI_EVENT_CLOSE Then
			$bUserStopped = True
			GUICtrlSetData($btnStopScan, "Analiz durduruluyor...")
			GUICtrlSetState($btnStopScan, $GUI_DISABLE)
			GUICtrlSetData($lblScanTitle, "Analiz durduruluyor...")
			ExitLoop
		EndIf

		If TimerDiff($hLogTimer) >= 3000 Then
			$hLogTimer = TimerInit()

			If FileExists($logPath) Then
				Local $hFile = FileOpen($logPath, 0)
				If $hFile <> -1 Then
					Local $sContent = FileRead($hFile)
					FileClose($hFile)

					If StringInStr($sContent, "!!!!! AVAILABLE !!!!!") Then
						_CollectStrategiesFromText($sContent, $aStrategies)
					EndIf

				EndIf
			EndIf
		EndIf

        If TimerDiff($hUiTimer) >= 1000 Then
            Local $iSeconds = Int(TimerDiff($hTimer) / 1000)
            GUICtrlSetData($lblScanElapsed, "Geçen süre: " & StringFormat("%02d:%02d", Int($iSeconds / 60), Mod($iSeconds, 60)))
            GUICtrlSetData($lblScanCount, "Bulunan strateji: " & $aStrategies[0])
            $hUiTimer = TimerInit()
        EndIf

        Sleep(10)
    WEnd

    ; Analiz doğal olarak bittiğinde de, kullanıcı durdurduğunda da
    ; blockcheck alt süreçlerini temizliyoruz.
    If ProcessExists($iPidBash) Then ProcessClose($iPidBash)
    Local $aProcesses = ["bash.exe", "sh.exe", "tee.exe", "winws2.exe"]
    For $sProc In $aProcesses
        RunWait(@ComSpec & " /c taskkill /F /IM " & $sProc & " /T", "", @SW_HIDE)
    Next

    GUIDelete($hScanGUI)

    ; Sonuçları kalıcı dosyaya yaz: pencere kapatılsa bile ana menüden yeniden açılabilir.
    If $aStrategies[0] > 0 Then
        If Not _SaveBlockcheckResults($aStrategies) Then
            MsgBox(48 + 8192, "Sonuçlar Kaydedilemedi", _
                "Stratejiler bu oturumda kullanılabilir ancak sonuç dosyasına kaydedilemedi:" & @CRLF & _BlockcheckResultsPath())
        EndIf
    EndIf

	; Blockcheck sonlandığında isNoBypassNeeded için logu tekrar oku
	Local $hFile = FileOpen($logPath, 0)

	If $hFile <> -1 Then
		Local $sContent = FileRead($hFile)
		FileClose($hFile)

		If StringInStr($sContent, "working without bypass") Or _
		StringInStr($sContent, "not blocked") Then
			$isNoBypassNeeded = True
		EndIf
	EndIf

	If $isNoBypassNeeded Then
        MsgBox(64 + 8192, "Bilgi: Zapret2 Analiz Tamamlandı", _
            "İnternet hattınızda herhangi bir DPI / sansür kısıtlaması saptanmadı.")
	ElseIf $aStrategies[0] > 0 Then
        _ShowStrategyTestWindow($aStrategies, True)
    ElseIf $bUserStopped Then
        MsgBox(48 + 8192, "Analiz Durduruldu", "Analiz durduruldu. Kullanılabilir strateji bulunamadı.")
    Else
        MsgBox(16 + 8192, "Başarısız", "Analiz tamamlandı ancak kullanılabilir strateji bulunamadı.")
    EndIf

    GUISetState(@SW_ENABLE, $hGUI)
    GUISetState(@SW_SHOW, $hGUI)

	;orijinal blockcheck2.sh dosyasını geri yükle
	_RestoreTestDomain()
EndFunc

Func _PrepareTestDomain()
    Local $shPath = @ScriptDir & "\bin\zapret\blockcheck\zapret2\blockcheck2.sh"
    Local $bakPath = $shPath & ".bak"

    Local $testDomain = StringStripWS(IniRead($iniPath, "Settings", "testdomain", ""), 3)

    ; Ayar yoksa varsayilan dosyayi kullan
    If $testDomain = "" Then Return True

    ; URL protokolunu ve www. on ekini temizle
    $testDomain = StringRegExpReplace($testDomain, "(?i)^https?://", "")
    $testDomain = StringRegExpReplace($testDomain, "(?i)^www\.", "")

    ; Yol, port, sorgu ve fragment kisimlarini temizle
    $testDomain = StringRegExpReplace($testDomain, "[/?#].*$", "")
    $testDomain = StringRegExpReplace($testDomain, ":\d+$", "")
    $testDomain = StringStripWS($testDomain, 3)

    ; Gecerli alan adi karakterleri ve etiket yapisi
    If StringLen($testDomain) > 253 Or _
        Not StringRegExp($testDomain, _
        "(?i)^(?=.{1,253}$)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$") Then

        MsgBox(16 + 8192, "Hata", "config.ini içindeki testdomain geçersiz: " & $testDomain & @CRLF & "roblox.com ile devam edilecek")
        Return True
    EndIf

    ; Dosyalarin varligini kontrol et
    If Not FileExists($shPath) Then
        MsgBox(16 + 8192, "Hata", "blockcheck2.sh bulunamadi.")
        Return False
    EndIf

    ; Mevcut yedegin ustune yazma
    If FileExists($bakPath) Then
        MsgBox(16 + 8192, "Hata", "Yedek dosya zaten mevcut:" & @CRLF & $bakPath & _
            @CRLF & "Olası veri kaybını önlemek için işlem durduruldu.")
        Return False
    EndIf

    ; Orijinal dosyayi yedekle
    If Not FileMove($shPath, $bakPath) Then
        MsgBox(16 + 8192, "Hata", "blockcheck2.sh yedeklenemedi.")
        Return False
    EndIf

    Local $shContent = FileRead($bakPath)
    If @error Then
        FileMove($bakPath, $shPath)
        MsgBox(16 + 8192, "Hata", "Yedek dosya okunamadi.")
        Return False
    EndIf

    ; DOMAINS satirini degistir
    Local $pattern = '(?m)^[ \t]*DOMAINS=\$\{DOMAINS:-[^\r\n]*'

    If Not StringRegExp($shContent, $pattern) Then
        FileMove($bakPath, $shPath)
        MsgBox(16 + 8192, "Hata", "blockcheck2.sh içinde beklenen DOMAINS satırı bulunamadı.")
        Return False
    EndIf

    $shContent = StringRegExpReplace($shContent, $pattern, _
        'DOMAINS=${DOMAINS:-"' & $testDomain & '"}')

    ; Yeni dosyayi olustur
    Local $hFile = FileOpen($shPath, 2 + 256)
    If $hFile = -1 Then
        FileMove($bakPath, $shPath)
        MsgBox(16 + 8192, "Hata", "Yeni blockcheck2.sh dosyasi olusturulamadi.")
        Return False
    EndIf

    FileWrite($hFile, $shContent)
    FileClose($hFile)

    Return True
EndFunc

Func _RestoreTestDomain()
    Local $shPath = @ScriptDir & "\bin\zapret\blockcheck\zapret2\blockcheck2.sh"
    Local $bakPath = $shPath & ".bak"

    If FileExists($bakPath) Then
        If FileExists($shPath) Then FileDelete($shPath)

        If Not FileMove($bakPath, $shPath) Then
            MsgBox(16 + 8192, "Hata", "Orijinal blockcheck2.sh geri yuklenemedi!" & @CRLF & _
                "Yedek dosya: " & $bakPath)
            Return False
        EndIf
    EndIf

    Return True
EndFunc

Func _CollectStrategiesFromText($sText, ByRef $aStrategies)
    Local $aLines = StringSplit(StringStripCR($sText), @LF)
    If $aLines[0] < 2 Then Return

    For $i = 2 To $aLines[0]
        If Not StringInStr($aLines[$i], "!!!!! AVAILABLE !!!!!") Then ContinueLoop
        If StringInStr($aLines[$i], "iana.org") Then ContinueLoop

        Local $sPrevLine = $aLines[$i - 1]
        If StringInStr($sPrevLine, "iana.org") Then ContinueLoop

        Local $targetStr = "--wf-tcp-out=443"
        Local $startPos = StringInStr($sPrevLine, $targetStr)
        If $startPos = 0 Then ContinueLoop

        Local $cutPoint = $startPos + StringLen($targetStr)
        Local $sRawStrategy = StringStripWS(StringMid($sPrevLine, $cutPoint), 3)
        If $sRawStrategy = "" Then ContinueLoop

        Local $sStrategy = _FormatStrategyQuotes($sRawStrategy)
        Local $bExists = False
        For $j = 1 To $aStrategies[0]
            If $aStrategies[$j] = $sStrategy Then
                $bExists = True
                ExitLoop
            EndIf
        Next

        If Not $bExists Then
            ReDim $aStrategies[UBound($aStrategies) + 1]
            $aStrategies[0] += 1
            $aStrategies[$aStrategies[0]] = $sStrategy
        EndIf
    Next
EndFunc

Func _ShowStrategyTestWindow(ByRef $aStrategies, $bMainAlreadyDisabled = False)
    ; Önceki sonuçlar ana menüden açılırsa burada modal kilitle; analiz akışından gelirse kilit zaten aktiftir.
    If Not $bMainAlreadyDisabled Then GUISetState(@SW_DISABLE, $hGUI)

    Local $hTestGUI = GUICreate("Bulunan Stratejileri Test Et", 500, 325, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), 0, $hGUI)
    GUISetBkColor(0xFFFFFF, $hTestGUI)

    GUICtrlCreateLabel("Bulunan stratejilerden birini seçip test edebilirsin.", 15, 14, 470, 22)
    Local $cmbFoundStrategies = GUICtrlCreateCombo("", 15, 42, 470, 150, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    Local $sOptions = ""
    For $i = 1 To $aStrategies[0]
        If $sOptions <> "" Then $sOptions &= "|"
        $sOptions &= "Strateji " & $i
    Next
    GUICtrlSetData($cmbFoundStrategies, $sOptions, "Strateji 1")

    GUICtrlCreateLabel("Seçili strateji:", 15, 80, 470, 18)
    Local $edtStrategyPreview = GUICtrlCreateEdit($aStrategies[1], 15, 100, 470, 62, BitOR($ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
    Local $lblOobWarning = GUICtrlCreateLabel("", 15, 167, 470, 30)
    GUICtrlSetColor($lblOobWarning, 0xCC0000)
    GUICtrlSetFont($lblOobWarning, 9, 700, 0, "Segoe UI")
    ; Belirgin durum alanı: açık mavi zemin, koyu mavi kalın yazı
    Local $lblTestStatus = GUICtrlCreateLabel("TEST BEKLİYOR  |  Test Et'e basıp Discord/Roblox bağlantını deneyebilirsin.", 15, 202, 470, 38, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetBkColor($lblTestStatus, 0xEAF3FF)
    GUICtrlSetColor($lblTestStatus, 0x174EA6)
    GUICtrlSetFont($lblTestStatus, 10, 700, 0, "Segoe UI")

    ; Tek düğme: test kapalıyken başlatır, çalışırken durdurur.
    Local $btnToggleTest = GUICtrlCreateButton("Test Et", 15, 258, 220, 34)
    Local $btnSaveStrategy = GUICtrlCreateButton("Stratejiyi Kaydet", 245, 258, 130, 34)
    Local $btnCloseTest = GUICtrlCreateButton("Kapat", 385, 258, 100, 34)
    Local $bStrategyTestRunning = False
    GUISetState(@SW_SHOW, $hTestGUI)

    Local $bDone = False
    Local $iSelected = 1
    _UpdateOobWarning($aStrategies[$iSelected], $lblOobWarning)
    While Not $bDone
        Local $nMsg = GUIGetMsg()
        Switch $nMsg
            Case $GUI_EVENT_CLOSE, $btnCloseTest
                _StopStrategyTest()
                $bDone = True

            Case $cmbFoundStrategies
                $iSelected = Int(StringTrimLeft(GUICtrlRead($cmbFoundStrategies), 8))
                If $iSelected >= 1 And $iSelected <= $aStrategies[0] Then
                    GUICtrlSetData($edtStrategyPreview, $aStrategies[$iSelected])
                    _UpdateOobWarning($aStrategies[$iSelected], $lblOobWarning)
                EndIf

            Case $btnToggleTest
                If $bStrategyTestRunning Then
                    ; Çalışan testi durdur.
                    _StopStrategyTest()
                    $bStrategyTestRunning = False
                    GUICtrlSetData($btnToggleTest, "Test Et")
                    GUICtrlSetData($lblTestStatus, "TEST DURDURULDU  |  İstersen başka bir stratejiyi test edebilirsin.")
                    GUICtrlSetBkColor($lblTestStatus, 0xFFF4E5)
                    GUICtrlSetColor($lblTestStatus, 0x8A4B08)
                Else
                    ; Testi başlat.
                    $iSelected = Int(StringTrimLeft(GUICtrlRead($cmbFoundStrategies), 8))
                    If $iSelected >= 1 And $iSelected <= $aStrategies[0] Then
                        _UpdateOobWarning($aStrategies[$iSelected], $lblOobWarning)
                        _StopStrategyTest()
                        Local $sTestCommand = _BuildStrategyTestCommand($aStrategies[$iSelected])
                        $strategyTestPID = Run($sTestCommand, @ScriptDir & "\bin\zapret\zapret-winws\", @SW_HIDE)
                        If $strategyTestPID > 0 Then
                            $bStrategyTestRunning = True
                            GUICtrlSetData($btnToggleTest, "Testi Durdur")
                            GUICtrlSetData($lblTestStatus, "TEST ÇALIŞIYOR  |  Discord/Roblox bağlantını dene.")
                            GUICtrlSetBkColor($lblTestStatus, 0xE8F5E9)
                            GUICtrlSetColor($lblTestStatus, 0x1B5E20)
                        Else
                            $bStrategyTestRunning = False
                            GUICtrlSetData($btnToggleTest, "Test Et")
                            GUICtrlSetData($lblTestStatus, "BAŞLATILAMADI  |  WinWS2 dosyasını ve yetkileri kontrol et.")
                            GUICtrlSetBkColor($lblTestStatus, 0xFDECEC)
                            GUICtrlSetColor($lblTestStatus, 0xB71C1C)
                        EndIf
                    EndIf
                EndIf

            Case $btnSaveStrategy
                $iSelected = Int(StringTrimLeft(GUICtrlRead($cmbFoundStrategies), 8))
                If $iSelected >= 1 And $iSelected <= $aStrategies[0] Then
                    Local $hStore = FileOpen($strategyFile, 2)
                    If $hStore = -1 Then
                        MsgBox(16 + 8192, "Kayıt Hatası", "Strateji dosyasına yazılamadı:" & @CRLF & $strategyFile)
                    Else
                        FileWrite($hStore, $aStrategies[$iSelected])
                        FileClose($hStore)
                        ; Analiz Sonucu seçiliyken kaydedilen yeni stratejiye göre ana filtre alanını anında güncelle.
                        _UpdateFilterForStrategy()
                        _StopStrategyTest()
                        MsgBox(64 + 8192, "Strateji Kaydedildi", "Seçilen strateji kaydedildi. Ana menüden Analiz Sonucu seçip Zapret'i başlatabilirsiniz.")
                        $bDone = True
                    EndIf
                EndIf
        EndSwitch

        ; Test açık görünürken winws2.exe beklenmedik şekilde kapanırsa durumu hemen düzelt.
        If $bStrategyTestRunning Then
            If Not ProcessExists("winws2.exe") Or ($strategyTestPID > 0 And Not ProcessExists($strategyTestPID)) Then
                $bStrategyTestRunning = False
                $strategyTestPID = 0
                GUICtrlSetData($btnToggleTest, "Test Et")
                GUICtrlSetData($lblTestStatus, "TEST ÇALIŞMIYOR | Bir şey süreci sonlandırdı.")
                GUICtrlSetBkColor($lblTestStatus, 0xFDECEC)
                GUICtrlSetColor($lblTestStatus, 0xB71C1C)
            EndIf
        EndIf

        Sleep(30)
    WEnd

    _StopStrategyTest()
    GUIDelete($hTestGUI)

    If Not $bMainAlreadyDisabled Then
        GUISetState(@SW_ENABLE, $hGUI)
        GUISetState(@SW_SHOW, $hGUI)
    EndIf
EndFunc

Func _BuildStrategyTestCommand($sStrategy)
    Local $luaBaseDir = StringRegExpReplace($winwsPath, "\\[^\\]+$", "") & "\lua\"
    Local $luaParams = ' --lua-init="@' & $luaBaseDir & 'zapret-lib.lua"' & _
                       ' --lua-init="@' & $luaBaseDir & 'zapret-antidpi.lua"' & _
                       ' --lua-init="@' & $luaBaseDir & 'zapret-auto.lua"'

    ; Testler hostlist/hostlist-auto/hostlist-exclude filtreleri olmadan çalışır.
    Return '"' & $winwsPath & '" --wf-l3=ipv4 --wf-tcp-out=0-65535 --wf-udp-out=0-65535 ' & $sStrategy & $luaParams
EndFunc

Func _UpdateOobWarning($sStrategy, $lblOobWarning)
    If StringInStr($sStrategy, "oob") Then
        GUICtrlSetData($lblOobWarning, "UYARI: Bu strateji OOB içeriyor. Filtreler ile çalışmamaktadır. Sistem geneli çalışacaktır. Bazı sitelerde sorun yaratabilir.")
        GUICtrlSetState($lblOobWarning, $GUI_SHOW)
    Else
        GUICtrlSetData($lblOobWarning, "")
    EndIf
EndFunc

Func _StopStrategyTest()
    If $strategyTestPID > 0 And ProcessExists($strategyTestPID) Then ProcessClose($strategyTestPID)
    $strategyTestPID = 0
EndFunc

Func _GetLastStrategyFromText($sText)
    Local $aLines = StringSplit(StringStripCR($sText), @LF)
    For $i = $aLines[0] To 1 Step -1
        If StringInStr($aLines[$i], "iana.org") Then ContinueLoop
        If StringInStr($aLines[$i], "!!!!! AVAILABLE !!!!!") Then
            If $i > 1 Then
                Local $sPrevLine = $aLines[$i - 1]
                Local $targetStr = "--wf-tcp-out=443"
                Local $startPos = StringInStr($sPrevLine, $targetStr)
                If $startPos > 0 Then
                    Local $cutPoint = $startPos + StringLen($targetStr)
                    Local $sRawStrategy = StringStripWS(StringMid($sPrevLine, $cutPoint), 3)
                    Return _FormatStrategyQuotes($sRawStrategy)
                EndIf
            EndIf
        EndIf
    Next
    Return ""
EndFunc

Func _FormatStrategyQuotes($sRawStrategy)
    Local $aParams = StringSplit($sRawStrategy, " ", 1)
    Local $sFormattedStrategy = ""
    For $j = 1 To $aParams[0]
        Local $sCurrentParam = $aParams[$j]
        Local $iFirstEq = StringInStr($sCurrentParam, "=")
        If $iFirstEq > 0 Then
            Local $sParamName = StringLeft($sCurrentParam, $iFirstEq)
            Local $sParamValue = StringMid($sCurrentParam, $iFirstEq + 1)
            $sCurrentParam = $sParamName & '"' & $sParamValue & '"'
        EndIf
        $sFormattedStrategy &= $sCurrentParam & " "
    Next
    Return StringStripWS($sFormattedStrategy, 3)
EndFunc

Func HasValidStrategy()
    If Not FileExists($strategyFile) Then Return False
    Local $sContent = StringStripWS(FileRead($strategyFile), 3)
    Return ($sContent <> "")
EndFunc

; --- Güvenlik Duvarı Sorgu Fonksiyonu ---
Func HasFirewallRule($fullPath)
	Local $fixedPath = StringReplace($fullPath, "I", "i")
	Local $psCmd = 'powershell -NoProfile -Command "Get-NetFirewallApplicationFilter -Program ''' & $fixedPath & ''' -ErrorAction SilentlyContinue | Get-NetFirewallRule | Where-Object { $_.Action -eq ''Allow'' -and $_.Enabled -eq ''True'' }"'
	Local $iPID = Run(@ComSpec & ' /c ' & $psCmd, "", @SW_HIDE, $STDOUT_CHILD)
    ProcessWaitClose($iPID)

    Return (StringLen(StdoutRead($iPID)) > 10)
EndFunc

Func _SetDNS_Localhost()
    Local $oWMI = ObjGet("winmgmts:\\.\root\cimv2")
    If Not IsObj($oWMI) Then Return False

    Local $oAdapters = $oWMI.ExecQuery( _
        "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True")

    If Not IsObj($oAdapters) Then Return False

    Local $bSet = False

    For $oAdapter In $oAdapters
        If Not IsArray($oAdapter.DefaultIPGateway) Then ContinueLoop

        Local $sDesc = String($oAdapter.Description)
        If StringRegExp($sDesc, _
            "(?i)Virtual|Hyper-V|WSL|TAP|TUN|VPN|VirtualBox|VMware|Loopback|WireGuard|Wintun") Then ContinueLoop

        ; Dinamik arayüz adını bul
        Local $sAdapterName = ""
        Local $oNetAdapters = $oWMI.ExecQuery( _
            "SELECT * FROM Win32_NetworkAdapter WHERE Index=" & $oAdapter.Index)

        For $oNetAdapter In $oNetAdapters
            $sAdapterName = $oNetAdapter.NetConnectionID
            If Not IsString($sAdapterName) Then $sAdapterName = ""
        Next

        If $sAdapterName = "" Then ContinueLoop

        ; IPv4 DNS: 127.0.0.1
        Local $iIPv4 = RunWait(@ComSpec & ' /c netsh interface ipv4 set dnsservers name="' & _
            $sAdapterName & '" source=static address=127.0.0.1 validate=no', "", @SW_HIDE)

        ; IPv6 DNS: ::1
        Local $iIPv6 = RunWait(@ComSpec & ' /c netsh interface ipv6 set dnsservers name="' & _
            $sAdapterName & '" source=static address=::1 validate=no', "", @SW_HIDE)

        If $iIPv4 = 0 And $iIPv6 = 0 Then $bSet = True
    Next

    ; DNS önbelleğini temizle
    RunWait(@ComSpec & " /c ipconfig /flushdns", "", @SW_HIDE)

    Return $bSet
EndFunc

Func _CheckDnscryptStatus()
    Local $sProxyName = "dnscrypt-proxy"

    ; 1. Windows Servisi çalışıyor mu kontrol et
    Local $iPid = Run(@ComSpec & " /c sc query " & $sProxyName, "", @SW_HIDE, $STDOUT_CHILD)
    ProcessWaitClose($iPid)
    Local $sOutput = StdoutRead($iPid)

    ; 2. Aktif DNS adresi 127.0.0.1 mi kontrol et
    Local $psScript = "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Virtual*' -and $_.InterfaceDescription -notlike '*Hyper-V*' -and $_.InterfaceDescription -notlike '*WSL*' -and $_.Name -notlike '*vEthernet*' -and $_.InterfaceDescription -notlike '*TAP*' -and $_.InterfaceDescription -notlike '*TUN*' -and $_.InterfaceDescription -notlike '*VPN*'} | Select-Object -First 1; "
    $psScript &= "if ($adapter) { (Get-DnsClientServerAddress -InterfaceAlias $adapter.Name).ServerAddresses -join ',' }"
    Local $iPidDNS = Run('powershell -NoProfile -Command "' & $psScript & '"', "", @SW_HIDE, $STDOUT_CHILD)
    ProcessWaitClose($iPidDNS)
    Local $sDnsOut = StdoutRead($iPidDNS)

    If StringInStr($sOutput, "RUNNING") And StringInStr($sDnsOut, "127.0.0.1") Then
        GUICtrlSetData($btnDnscrypt, "[ ✓ ] Dnscrypt-proxy Aktif / Kaldır")
        IniWrite($iniPath, "Settings", "DnscryptInstalled", "1")
    Else
        GUICtrlSetData($btnDnscrypt, "Dnscrypt-proxy servisi kur")
        IniWrite($iniPath, "Settings", "DnscryptInstalled", "0")
    EndIf

    ; Açılışta butonun disabled kalmaması için her kontrol bitiminde açıyoruz
    GUICtrlSetState($btnDnscrypt, $GUI_ENABLE)
EndFunc
