#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=bin\zapret\zapret-winws\winws2.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Zapret Multi-Engine Windows Türkiye - Zapret & Zapret2 Kontrol Aracı
#AutoIt3Wrapper_Res_Fileversion=4.2.0.0
#AutoIt3Wrapper_Res_ProductVersion=4.2
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
Global $bServiceStoppedWarned = False

; --- GUI Tasarımı ---
Local $hGUI = GUICreate("Zapret Windows Türkiye v4.2", 400, 535)
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
GUICtrlSetData(-1, "Auto (Zapret oluşturur)|Manuel ('hostlist.txt' İçeriği)")

; INI'den okunan değere göre varsayılanı seç
If $iniFilterMode == "1" Then
    GUICtrlSetData($cmbFilter, "Auto (Zapret oluşturur)", "Auto (Zapret oluşturur)")
ElseIf $iniFilterMode == "2" Then
    GUICtrlSetData($cmbFilter, "Manuel ('hostlist.txt' İçeriği)", "Manuel ('hostlist.txt' İçeriği)")
Else
    GUICtrlSetData($cmbFilter, "Kapalı (Tüm trafik)", "Kapalı (Tüm trafik)")
EndIf

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
					If ProcessExists("go-pcap2socks.exe") Then
						ProcessClose("go-pcap2socks.exe")
						$pcapPID = 0
					EndIf
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

		Case $btnAnalyze
            Local $iConfirm = MsgBox(33 + 8192, "Bilgi", "Analiz işlemi 5-10 dakika sürebilir." & @CRLF & "Lütfen bitene kadar bekleyin.")
            If $iConfirm = 1 Then
                _SetButtonsState($aCriticalButtons, $GUI_DISABLE)
                GUICtrlSetState($btnRemoveService, $GUI_DISABLE)
                GUICtrlSetData($lblStatusText, "ANALİZ YAPILIYOR...")
                GUICtrlSetState($pBar, $GUI_SHOW)
                GUICtrlSetData($lblStrategyInfo, "")
                _SendMessage(GUICtrlGetHandle($pBar), $PBM_SETMARQUEE, True, 50)

                If $currentEngine = "Zapret2" Then
                    RunBlockcheck2($btnAnalyze)
                Else
                    RunBlockcheck($btnAnalyze)
                EndIf

                _SendMessage(GUICtrlGetHandle($pBar), $PBM_SETMARQUEE, False, 0)
                GUICtrlSetState($pBar, $GUI_HIDE)
                _SetButtonsState($aCriticalButtons, $GUI_ENABLE)
                GUICtrlSetState($btnRemoveService, $GUI_ENABLE)
                CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)
                GUICtrlSetData($lblStatusText, "ANALİZ TAMAMLANDI")
                _RefreshStrategyLabel()
            EndIf

		Case $btnLanShare
            If GUICtrlRead($btnLanShare) = "Ağdaki Cihazlarla Paylaş" Then
                ; --- ADIM 1: NPCAP KONTROLÜ ---
                If Not FileExists(@SystemDir & "\Packet.dll") Then
                    GUICtrlSetData($btnLanShare, "Ağdaki Cihazlarla Paylaş")
                    GUICtrlSetFont($btnLanShare, 10, 600, 0, "Segoe UI")
                    MsgBox(8208, "Eksik Bileşen", "HATA: Sistemde Npcap sürücüsü bulunamadı!" & @CRLF & @CRLF & _
                            "go-pcap2socks motorunun çalışabilmesi için Npcap kurulmalıdır." & @CRLF & _
                            "Lütfen npcap.com adresinden indirip kurun.")
                    ContinueLoop
                EndIf

                ; --- SPLASH SCREEN BAŞLANGICI ---
                Local $hSplash = GUICreate("Lütfen Bekleyin", 280, 80, -1, -1, $WS_POPUP, $WS_EX_TOPMOST)
                GUISetBkColor(0xF2F4F7, $hSplash)
                GUICtrlCreateLabel("Güvenlik Duvarı" & @CRLF & "Kontrolleri Yapılıyor...", 10, 20, 260, 40, $SS_CENTER)
                GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
                GUICtrlSetColor(-1, 0x2C3E50)
                GUISetState(@SW_SHOW, $hSplash)

                Local $targetPcapExe = @ScriptDir & '\bin\go-pcap2socks\go-pcap2socks.exe'

                If Not HasFirewallRule($targetPcapExe) Then
                    GUISetState(@SW_HIDE, $hSplash)

                    RunWait('powershell -NoProfile -Command "Remove-NetFirewallRule -Program ''' & $targetPcapExe & ''' -ErrorAction SilentlyContinue"', "", @SW_HIDE)
                    RunWait(@ComSpec & ' /c netsh advfirewall firewall delete rule name=all program="' & $targetPcapExe & '"', "", @SW_HIDE)

                    MsgBox(8256, "Güvenlik Duvarı İzni", "go-pcap2socks için ağ izni gerekiyor." & @CRLF & @CRLF & _
                            "1. Birazdan Windows Güvenlik Duvarı uyarısı gelecektir." & @CRLF & _
                            "2. Lütfen gelen ekranda kutucukları işaretleyip 'Erişime izin ver' (Allow) butonuna basın.")

                    Local $tmpPID = Run('"' & $targetPcapExe & '"', @ScriptDir & '\bin\go-pcap2socks', @SW_HIDE)
                    MsgBox(8256, "Onay", "Güvenlik duvarı iznini onayladıysanız Tamam'a basın.")
                    ProcessClose($tmpPID)

                    GUISetState(@SW_SHOW, $hSplash)
                EndIf

                ; --- ADIM 3: SÜRECİ BAŞLATMA ---
                If Not ProcessExists("go-pcap2socks.exe") Then
                    $pcapPID = Run('"' & $targetPcapExe & '"', @ScriptDir & '\bin\go-pcap2socks', @SW_HIDE)
                EndIf

                ; --- GERÇEKTEN ÇALIŞIYOR MU KONTROLÜ ---
                Sleep(500)

                If Not ProcessExists("go-pcap2socks.exe") Then
                    GUIDelete($hSplash)
                    GUICtrlSetData($btnLanShare, "Ağdaki Cihazlarla Paylaş")
                    GUICtrlSetFont($btnLanShare, 10, 600, 0, "Segoe UI")
                    $pcapPID = 0
                    MsgBox(16 + 8192, "Başlatma Hatası", "HATA: go-pcap2socks başlatılamadı!" & @CRLF & @CRLF & _
                            "• Sanal bir ağ kartı oluşturan VPN vb program kullanıyorsanız kapatın.")
                    ContinueLoop
                EndIf

                GUIDelete($hSplash)

                ; BAŞARILI DURUM: Butonu Yeşile Boya ve Metni Değiştir
                GUICtrlSetData($btnLanShare, "[ ✓ ] Paylaşım Aktif / Durdur")
                GUICtrlSetFont($btnLanShare, 10, 800, 0, "Segoe UI")

                MsgBox(8256, "go-pcap2socks Ağ Yapılandırması", _
                        "Ağdaki diğer cihazınızda şu IP ayarlarını giriniz:" & @CRLF & @CRLF & _
                        "• IP Aralığı: 172.24.2.10 - 172.24.2.255" & @CRLF & _
                        "• Ağ Geçidi (Gateway): 172.24.2.1" & @CRLF & _
                        "• Alt Ağ Maskesi (Maske): 255.255.0.0" & @CRLF & _
                        "• DNS 1: 1.1.1.1" & @CRLF & _
                        "• DNS 2: 8.8.8.8")
            Else
                ; DURDURMA İŞLEMİ
                If ProcessExists("go-pcap2socks.exe") Then
                    ProcessClose("go-pcap2socks.exe")
                    $pcapPID = 0
                EndIf
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
            InstallServiceClean($cmbFilter)
            CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $cmbFilter)

		Case $btnDnscrypt
            Local $sProxyDir = @ScriptDir & "\bin\dnscrypt-proxy"
            Local $sProxyPath = $sProxyDir & "\dnscrypt-proxy.exe"

            If Not FileExists($sProxyPath) Then
                MsgBox(16, "Hata", "DNSCrypt dosyası bulunamadı!" & @CRLF & $sProxyPath)
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
    ; Aktif adaptörü bul, DNS'i düz Cloudflare yap ve önbelleği sıfırla
    Local $psScript = "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Virtual*' -and $_.InterfaceDescription -notlike '*Hyper-V*' -and $_.InterfaceDescription -notlike '*WSL*' -and $_.Name -notlike '*vEthernet*' -and $_.InterfaceDescription -notlike '*TAP*' -and $_.InterfaceDescription -notlike '*TUN*' -and $_.InterfaceDescription -notlike '*VPN*'} | Select-Object -First 1; " & _
                      "Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses '1.1.1.1', '1.0.0.1'; " & _
                      "ipconfig /flushdns;"

    RunWait('powershell -NoProfile -ExecutionPolicy Bypass -Command "' & $psScript & '"', "", @SW_HIDE)
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

    Local $filterSel = GUICtrlRead($cmbFilter)
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
        GUICtrlSetData($lblFooter, "Zapret2 v1.0.2")
    Else
        $currentEngine = "Zapret1"
        $strategyFile = @ScriptDir & "\config\strategy.txt"
        $winwsPath = @ScriptDir & "\bin\zapret\zapret-winws\winws.exe"
        $blockcheckPath = @ScriptDir & "\bin\zapret\blockcheck\blockcheck.cmd"
        $logPath = @ScriptDir & "\bin\zapret\blockcheck\blockcheck.log"
        GUICtrlSetData($lblFooter, "Zapret v72.12")
    EndIf
EndFunc

Func _SendMessage($hWnd, $iMsg, $wParam = 0, $lParam = 0)
    Local $aResult = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", $iMsg, "wparam", $wParam, "lparam", $lParam)
    Return $aResult[0]
EndFunc

Func ShowGUI()
    GUISetState(@SW_SHOW, $hGUI)
    GUISetState(@SW_RESTORE, $hGUI)
EndFunc

Func ExitApp()
    If $isZapretRunning Then StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
    If ProcessExists("go-pcap2socks.exe") Then ProcessClose("go-pcap2socks.exe")
    Exit
EndFunc

Func _SetButtonsState(ByRef $aBtnArray, $iState)
    For $i = 0 To UBound($aBtnArray) - 1
        GUICtrlSetState($aBtnArray[$i], $iState)
    Next
EndFunc

Func CheckDnsPoisoningSilent()
    ; Değişkenleri sadece bu fonksiyona özel (Local) olarak tanımlıyoruz
    Local $testDomain = "updates.discord.com"
    Local $safePrefix = "162.159"
    Local $ttPoisonIP = "195.175.254.2" ; Türk Telekom sahte yönlendirme IP'si

    ; --- 1. KADEME: nslookup ile test et ---
    Local $iPidLocal = Run(@ComSpec & ' /c nslookup ' & $testDomain, "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($iPidLocal)
    Local $sLocalOut = StdoutRead($iPidLocal)

    ; DURUM A: Gerçek IP direkt bulunduysa (YogaDNS devrede vs.)
    If StringInStr($sLocalOut, $safePrefix) Then
        Return False ; Pass (Temiz)
    EndIf

    ; DURUM B: Türk Telekom zehirli IP'si saptandıysa (Erken ve Hızlı Çıkış)
    If StringInStr($sLocalOut, $ttPoisonIP) Then
        Return True ; Fail (Zehirli)
    EndIf

    ; --- 2. KADEME: WARP / Proxy Kontrolü (OS API Fallback) ---
    ; nslookup hata verdiyse (WARP veya Proxy devrede olduğu için engellenmiş olabilir)
    If StringInStr($sLocalOut, "No response") Or StringInStr($sLocalOut, "can't find") Or StringInStr($sLocalOut, "timed out") Then
        TCPStartup()
        Local $sIP = TCPNameToIP($testDomain)
        TCPShutdown()

        ; Eğer OS API gerçek IP'yi bulabildiyse (WARP arka planda işini yapıyordur)
        If StringInStr($sIP, $safePrefix) Then
            Return False ; Pass (Temiz)
        EndIf
    EndIf

    ; --- 3. KADEME: Diğer tüm başarısız durumlar ---
    ; (TT harici başka ISS zehirlemesi, farklı bir sahte IP veya tamamen internetsizlik)
    Return True ; Fail (Zehirli)
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

        GUICtrlSetData($statusID, "SİSTEM HAZIR")
        GUICtrlSetColor($statusID, 0x2C3E50)
    EndIf
EndFunc

Func StartWinws($ctrlID, $statusID, $aBtns)
    Local $activeStrategy = _GetActiveStrategyString()
    If $activeStrategy = "" Then Return MsgBox(48 + 8192, "Hata", "Strateji bulunamadı. Önce analiz yapın.")

    Local $fullCommand = ""

    If $currentEngine = "Zapret2" Then
        Local $luaBaseDir = StringRegExpReplace($winwsPath, "\\[^\\]+$", "") & "\lua\"
        Local $luaParams = ' --lua-init="@' & $luaBaseDir & 'zapret-lib.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-antidpi.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-auto.lua"'
        $fullCommand = '"' & $winwsPath & '" --wf-l3=ipv4 --wf-tcp-out=0-65535 --wf-udp-out=0-65535 --hostlist-exclude="' & $exludelistPath & '" ' & $activeStrategy & $luaParams
    Else
        $fullCommand = '"' & $winwsPath & '" --wf-tcp=0-65535 --wf-udp=0-65535 --hostlist-exclude="' & $exludelistPath & '" ' & $activeStrategy
    EndIf

	; --- YENİ AÇILIR MENÜ FİLTRE KONTROLÜ ---
    Local $filterSelection = GUICtrlRead($cmbFilter)
    If StringInStr($filterSelection, "Auto") Then
        If Not FileExists($hostlistPath) Then FileWrite($hostlistPath, "")
        $fullCommand &= ' --hostlist-auto="' & $hostlistPath & '"'
    ElseIf StringInStr($filterSelection, "Manuel") Then
        If Not FileExists($normalHostlistPath) Then FileWrite($normalHostlistPath, "discord.com" & @CRLF & "updates.discord.com")
        $fullCommand &= ' --hostlist="' & $normalHostlistPath & '"'
    EndIf

    ClipPut($fullCommand)
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

    If $currentEngine = "Zapret2" Then
        Local $luaBaseDir = StringRegExpReplace($winwsPath, "\\[^\\]+$", "") & "\lua\"
        Local $luaParams = ' --lua-init="@' & $luaBaseDir & 'zapret-lib.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-antidpi.lua"' & _
                           ' --lua-init="@' & $luaBaseDir & 'zapret-auto.lua"'
        $binArgs = '--wf-l3=ipv4 --wf-tcp-out=0-65535 --wf-udp-out=0-65535 --hostlist-exclude="' & $exludelistPath & '" ' & $activeStrategy & $luaParams
    Else
        $binArgs = '--wf-tcp=0-65535 --wf-udp=0-65535 --hostlist-exclude="' & $exludelistPath & '" ' & $activeStrategy
    EndIf

	; --- YENİ AÇILIR MENÜ FİLTRE KONTROLÜ ---
    Local $filterSelection = GUICtrlRead($cmbFilter)
    If StringInStr($filterSelection, "Auto") Then
        If Not FileExists($hostlistPath) Then FileWrite($hostlistPath, "")
        $binArgs &= ' --hostlist-auto="' & $hostlistPath & '"'
    ElseIf StringInStr($filterSelection, "Manuel") Then
        If Not FileExists($normalHostlistPath) Then FileWrite($normalHostlistPath, "discord.com" & @CRLF & "updates.discord.com")
        $binArgs &= ' --hostlist="' & $normalHostlistPath & '"'
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
Func RunBlockcheck2($ctrlID)
    Local $strategyFound = ""
    Local $isNoBypassNeeded = False
    If FileExists($logPath) Then FileDelete($logPath)
    Local $bashPath = @ScriptDir & "\bin\zapret\cygwin\bin\bash.exe"
    Local $shScriptPath = @ScriptDir & "\bin\zapret\blockcheck\zapret2\blog.sh"
    Local $sCommand = '"' & $bashPath & '" -i "' & $shScriptPath & '"'
    Local $iPidBash = Run($sCommand, @ScriptDir & "\bin\zapret\blockcheck", @SW_HIDE)
    Local $hWaitTimer = TimerInit()
    While Not FileExists($logPath)
        Sleep(500)
        If TimerDiff($hWaitTimer) > 10000 Then ExitLoop
    WEnd
    Local $hTimer = TimerInit()
    While ProcessExists("bash.exe")
        Sleep(1000)
        Local $hFile = FileOpen($logPath, 0)
        If $hFile <> -1 Then
            Local $sContent = FileRead($hFile)
            FileClose($hFile)
            Local $sFiltered = StringReplace($sContent, "iana.org", "IGNORE")
            If StringInStr($sFiltered, "!!!!! AVAILABLE !!!!!") Then
                $strategyFound = _GetLastStrategyFromText($sContent)
                If $strategyFound <> "" Then ExitLoop
            EndIf
            If StringInStr($sContent, "working without bypass") Or StringInStr($sContent, "not blocked") Then
                $isNoBypassNeeded = True
            EndIf
        EndIf
        If TimerDiff($hTimer) > 600000 Then ExitLoop
    WEnd
    Local $aProcesses = ["bash.exe", "sh.exe", "tee.exe", "winws2.exe"]
    For $sProc In $aProcesses
        RunWait(@ComSpec & " /c taskkill /F /IM " & $sProc & " /T", "", @SW_HIDE)
    Next
    If $strategyFound <> "" Then
        Local $hStore = FileOpen($strategyFile, 2)
        FileWrite($hStore, $strategyFound)
        FileClose($hStore)
        MsgBox(64 + 8192, "Başarılı", "Analiz tamamlandı. Zapret2 için strateji ayıklandı.")
    ElseIf $isNoBypassNeeded Then
        MsgBox(64 + 8192, "Bilgi: Zapret2 Analiz Tamamlandı", _
                "İnternet hattınızda herhangi bir DPI / Sansür kısıtlaması saptanmadı!")
    Else
        MsgBox(16 + 8192, "Başarısız", "Zaman aşımı.")
    EndIf
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
    Local $psScript = "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Virtual*' -and $_.InterfaceDescription -notlike '*Hyper-V*' -and $_.InterfaceDescription -notlike '*WSL*' -and $_.Name -notlike '*vEthernet*' -and $_.InterfaceDescription -notlike '*TAP*' -and $_.InterfaceDescription -notlike '*TUN*' -and $_.InterfaceDescription -notlike '*VPN*'} | Select-Object -First 1; "
    $psScript &= "Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses '127.0.0.1', '::1'; "
    $psScript &= "ipconfig /flushdns;"

    RunWait('powershell -NoProfile -Command "' & $psScript & '"', "", @SW_HIDE)
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
