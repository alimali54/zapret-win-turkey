#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Zapret Türkiye Windows - Zapret Kullanmayı Kolaylaştıran Araç
#AutoIt3Wrapper_Res_Fileversion=1.1.1.0
#AutoIt3Wrapper_Res_ProductVersion=1.1.1
#AutoIt3Wrapper_Res_LegalCopyright=Ali Mali
#AutoIt3Wrapper_Res_Language=1055
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region ; **** Directives created by AutoIt3Wrapper_GUI ****
#EndRegion ; **** Directives created by AutoIt3Wrapper_GUI ****

#include <File.au3>
#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ProgressConstants.au3>

; --- ZIP / TEMP KLASÖRÜ KONTROLÜ ---
Local $currentDir = @ScriptDir
; Windows'un ZIP'leri açtığı geçici klasörleri (Temp veya Temporary Internet Files) kontrol et
If StringInStr($currentDir, @TempDir) Or StringInStr($currentDir, "Temporary Internet Files") Or StringInStr($currentDir, "vfs") Then
    MsgBox(16, "Hata: Arşivden Çalıştırma Saptandı", _
            "Programı ZIP dosyasının içinden doğrudan çalıştırmayın!" & @CRLF & @CRLF & _
            "1. ZIP dosyasındaki tüm dosyaları normal bir klasöre çıkarın." & @CRLF & _
            "2. Ardından programı o klasörden tekrar başlatın." & @CRLF & @CRLF & _
            "Geçici klasörlerden çalıştırıldığında sürücü izinleri alınamaz.")
    Exit
EndIf

; --- GÜVENLİK UYARILARINI (SMARTSCREEN) KALDIR ---
; Bu komut, programın bulunduğu klasördeki tüm dosyaların "Mark of the Web" işaretini siler.
; Böylece bash.exe veya winws.exe çalışırken kullanıcıya uyarı çıkmaz.
RunWait('powershell -Command "Get-ChildItem -Path ''' & @ScriptDir & ''' -Recurse | Unblock-File"', "", @SW_HIDE)


; --- ÇAKIŞMA KONTROLÜ (GoodbyeDPI) ---
If ProcessExists("goodbyedpi.exe") Then
    Local $iResponse = MsgBox(52, "Çakışma Saptandı", "GoodbyeDPI aktif gözüküyor, Zapret'in çalışması için GoodbyeDPI sonlandırılmalı." & @CRLF & @CRLF & _
            "GoodbyeDPI'ı kapatmak ve varsa servisini kaldırmak istiyor musunuz?")

    If $iResponse = 6 Then ; Evet seçilirse
        ; İşlemi sonlandır
        ProcessClose("goodbyedpi.exe")
        While ProcessExists("goodbyedpi.exe")
            Sleep(100)
        WEnd

        ; Servisleri temizle
        RunWait(@ComSpec & ' /c sc stop "GoodbyeDPI" & sc delete "GoodbyeDPI" & sc stop "WinDivert" & sc delete "WinDivert" & sc stop "WinDivert14" & sc delete "WinDivert14"', "", @SW_HIDE)

        MsgBox(64, "Bilgi", "GoodbyeDPI ve servisleri başarıyla kaldırıldı. Program başlatılıyor.")
    Else ; Hayır seçilirse
        Exit ; Programı kapat
    EndIf
EndIf

; --- Tepsi Menüsü Ayarları ---
Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

; --- Ayarlar ve Dosya Yolları ---
Local $serviceName = "ZapretService"
Local $strategyFile = @ScriptDir & "\strategy.txt"
Local $winwsPath = @ScriptDir & "\zapret\zapret-winws\winws.exe"
Local $hostlistPath = @ScriptDir & "\autohostlist.txt"
Local $blockcheckPath = @ScriptDir & "\zapret\blockcheck\blockcheck.cmd"
Local $logPath = @ScriptDir & "\zapret\blockcheck\blockcheck.log"

; --- Global Değişkenler ---
Global $isZapretRunning = False
Global $zapretPID = 0

; --- GUI Tasarımı ---
Local $hGUI = GUICreate("Zapret Türkiye Windows", 400, 415)
GUISetBkColor(0xFFFFFF)

; --- Tepsi Menüsü Öğeleri ---
Local $trayShow = TrayCreateItem("Göster")
TrayItemSetOnEvent(-1, "ShowGUI")
TrayCreateItem("")
Local $trayExit = TrayCreateItem("Kapat")
TrayItemSetOnEvent(-1, "ExitApp")
TraySetClick(16)

; --- Üst Durum Paneli ---
Local $lblStatusBg = GUICtrlCreateLabel("", 15, 15, 370, 75)
GUICtrlSetBkColor(-1, 0xF2F4F7)
Local $lblStatusText = GUICtrlCreateLabel("SİSTEM HAZIRLANIYOR...", 15, 30, 370, 25, $SS_CENTER)
GUICtrlSetFont(-1, 12, 800, 0, "Segoe UI")
GUICtrlSetColor(-1, 0xE67E22)

Local $pBar = GUICtrlCreateProgress(15, 75, 370, 15, $PBS_MARQUEE)
GUICtrlSetState(-1, $GUI_HIDE)

Local $lblStrategyInfo = GUICtrlCreateLabel("Strateji Durumu: " & (FileExists($strategyFile) ? "Mevcut" : "Mevcut Değil"), 15, 55, 370, 20, $SS_CENTER)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x666666)

; --- Butonlar (BAŞLANGIÇTA DISABLED) ---
Local $btnRunZapret = GUICtrlCreateButton("ZAPRET'İ BAŞLAT", 50, 105, 300, 55)
GUICtrlSetState(-1, $GUI_DISABLE) ; <--- KİLİTLİ BAŞLAR
GUICtrlSetFont(-1, 11, 800, 0, "Segoe UI")

Local $chkAutoHost = GUICtrlCreateCheckbox(" Otomatik Hostlist Kullanımını Aktifleştir", 75, 175, 280, 25)
GUICtrlSetState(-1, BitOR($GUI_CHECKED, $GUI_DISABLE)) ; <--- Hem CHECKED hem DISABLE yapar
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

Local $btnAnalyze = GUICtrlCreateButton("ISS Analizi Yap", 50, 215, 300, 40)
GUICtrlSetState(-1, $GUI_DISABLE) ; <--- KİLİTLİ BAŞLAR
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Local $btnInstallService = GUICtrlCreateButton("Servis Olarak Yükle (Otomatik Başlat)", 50, 265, 300, 40)
GUICtrlSetState(-1, $GUI_DISABLE) ; <--- KİLİTLİ BAŞLAR
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Local $btnRemoveService = GUICtrlCreateButton("Servis ve Kalıntıları Temizle", 50, 315, 300, 35)
GUICtrlSetFont(-1, 10, 600, 0, "Segoe UI")

Local $lblFooter = GUICtrlCreateLabel("Zapret Türkiye Windows v1.1.1", 0, 390, 400, 20, $SS_CENTER)
GUICtrlSetFont(-1, 8, 400, 0, "Segoe UI")
GUICtrlSetColor(-1, 0xBDC3C7)

Local $aCriticalButtons[4] = [$btnRunZapret, $btnAnalyze, $btnInstallService, $chkAutoHost]
Local $aOtherButtons[4] = [$btnAnalyze, $btnInstallService, $btnRemoveService, $chkAutoHost]

GUISetState(@SW_SHOW)

; --- GÜVENLİ AÇILIŞ AKIŞI ---
GUICtrlSetData($lblStatusText, "DNS KONTROL EDİLİYOR...")

Local $isPoisoned = CheckDnsPoisoningSilent()

If $isPoisoned Then
    _SetButtonsState($aCriticalButtons, $GUI_DISABLE)
    GUICtrlSetData($lblStatusText, "DNS ZEHİRLENMESİ SAPTANDI!")
    GUICtrlSetColor($lblStatusText, 0xC0392B)
    MsgBox(16, "Kritik Uyarı", "ISS tarafından DNS Zehirlenmesi saptandı!" & @CRLF & @CRLF & _
           "Bu şartlarda Zapret doğru çalışmayacaktır." & @CRLF & @CRLF & _
           "Lütfen DNS değiştirin veya YogaDNS, NextDNS gibi DNS istemcileri kullanın.")
Else
    ; DNS Temizse butonları ve servis durumunu aç
    CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $chkAutoHost)
EndIf

; --- Ana Döngü ---
While 1
    Local $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            ExitApp()

        Case $GUI_EVENT_MINIMIZE
            GUISetState(@SW_HIDE, $hGUI)
            TraySetToolTip("Zapret Master Pro Çalışıyor")

        Case $btnAnalyze
            Local $iConfirm = MsgBox(33, "Bilgi", "Analiz işlemi 5-10 dakika sürebilir." & @CRLF & "Lütfen bitene kadar bekleyin.")
            If $iConfirm = 1 Then
                _SetButtonsState($aCriticalButtons, $GUI_DISABLE)
                GUICtrlSetState($btnRemoveService, $GUI_DISABLE)
                GUICtrlSetData($lblStatusText, "ANALİZ YAPILIYOR...")

                GUICtrlSetState($pBar, $GUI_SHOW)
                GUICtrlSetData($lblStrategyInfo, "")
                _SendMessage(GUICtrlGetHandle($pBar), $PBM_SETMARQUEE, True, 50)

                RunBlockcheck($btnAnalyze)

                _SendMessage(GUICtrlGetHandle($pBar), $PBM_SETMARQUEE, False, 0)
                GUICtrlSetState($pBar, $GUI_HIDE)

                _SetButtonsState($aCriticalButtons, $GUI_ENABLE)
                GUICtrlSetState($btnRemoveService, $GUI_ENABLE)
                CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $chkAutoHost)
                GUICtrlSetData($lblStatusText, "ANALİZ TAMAMLANDI")
                GUICtrlSetData($lblStrategyInfo, "Strateji Durumu: " & (FileExists($strategyFile) ? "Mevcut" : "Mevcut Değil"))
            EndIf

        Case $btnRunZapret
            If $isZapretRunning = False Then
                StartWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
            Else
                StopWinws($btnRunZapret, $lblStatusText, $aOtherButtons)
            EndIf

        Case $btnInstallService
            InstallServiceClean($chkAutoHost)
            CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $chkAutoHost)

        Case $btnRemoveService
            RemoveService()
            $isPoisoned = CheckDnsPoisoningSilent()
            If Not $isPoisoned Then CheckServiceStatus($btnRunZapret, $lblStatusText, $aCriticalButtons, $chkAutoHost)
            GUICtrlSetData($lblStrategyInfo, "Strateji Durumu: " & (FileExists($strategyFile) ? "Mevcut" : "Mevcut Değil"))
            MsgBox(64, "Bilgi", "Temizlik tamamlandı.")
    EndSwitch
WEnd

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
    Exit
EndFunc

Func _SetButtonsState(ByRef $aBtnArray, $iState)
    For $i = 0 To UBound($aBtnArray) - 1
        GUICtrlSetState($aBtnArray[$i], $iState)
    Next
EndFunc

Func CheckDnsPoisoningSilent()
    Local $testDomain = "updates.discord.com"
    Local $localIP = "", $safeIP = ""

    ; 1. YEREL SORGU (PowerShell Resolve-DnsName)
    ; -Type A: Sadece IPv4 adreslerini getirir.
    ; -ErrorAction SilentlyContinue: Hata durumunda (internet yoksa vb.) PowerShell'in hata fışkırtmasını engeller.
    Local $sPSCommand = 'powershell -NoProfile -Command "(Resolve-DnsName ' & $testDomain & ' -Type A -ErrorAction SilentlyContinue).IPAddress"'
    Local $iPidLocal = Run($sPSCommand, "", @SW_HIDE, $STDOUT_CHILD)
    ProcessWaitClose($iPidLocal)
    Local $sLocalOut = StringStripWS(StdoutRead($iPidLocal), 3) ; Boşlukları ve yeni satırları temizle

    ; Eğer birden fazla IP dönerse (Discord genelde liste döner), ilkini alalım
    If $sLocalOut <> "" Then
        Local $aIPs = StringSplit($sLocalOut, @CRLF, 1)
        $localIP = $aIPs[1]
    EndIf

    ; 2. GÜVENLİ SORGU (Cloudflare DoH üzerinden gerçek IP)
    Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
    $oHTTP.Open("GET", "https://1.1.1.1/dns-query?name=" & $testDomain & "&type=A", False)
    $oHTTP.SetRequestHeader("Accept", "application/dns-json")
    $oHTTP.Send()
    If $oHTTP.Status = 200 Then
        ; JSON içindeki "data":"..." kısmından IP'yi çeker
        Local $aSafeMatches = StringRegExp($oHTTP.ResponseText, 'data":"(\d+\.\d+\.\d+\.\d+)"', 3)
        If UBound($aSafeMatches) > 0 Then $safeIP = $aSafeMatches[0]
    EndIf

    ; --- KARŞILAŞTIRMA VE HATA KONTROLÜ ---

    ; Yerel IP hiç alınamadıysa (DNS cevap vermiyor veya engelli), bunu sorun kabul edelim.
    If $localIP = "" Then Return True

    ; IP'lerin ilk iki bloğunu (Oktet) karşılaştır (Örn: 162.159)
    ; Bu yöntem IP son hanesi değişse bile doğru sonucu verir.
    Local $localPrefix = StringRegExpReplace($localIP, "^(\d+\.\d+).*", "$1")
    Local $safePrefix = StringRegExpReplace($safeIP, "^(\d+\.\d+).*", "$1")

    If $localPrefix <> $safePrefix Then
        Return True ; Zehirlenme (Poisoning) var!
    Else
        Return False ; Her şey temiz.
    EndIf
EndFunc

Func CheckServiceStatus($manualBtn, $statusID, $lockArray, $chkID)
    Local $iPid = Run(@ComSpec & " /c sc query " & $serviceName, "", @SW_HIDE, $STDOUT_CHILD)
    ProcessWaitClose($iPid)
    Local $sOutput = StdoutRead($iPid)
    If StringInStr($sOutput, "SERVICE_NAME") Then
        Local $iPidCfg = Run(@ComSpec & " /c sc qc " & $serviceName, "", @SW_HIDE, $STDOUT_CHILD)
        ProcessWaitClose($iPidCfg)
        GUICtrlSetState($chkID, StringInStr(StdoutRead($iPidCfg), "--hostlist-auto") ? $GUI_CHECKED : $GUI_UNCHECKED)
        GUICtrlSetState($manualBtn, $GUI_DISABLE)
        _SetButtonsState($lockArray, $GUI_DISABLE)
        GUICtrlSetData($statusID, "SERVİS MODU AKTİF")
        GUICtrlSetColor($statusID, 0x27AE60)
    Else
        GUICtrlSetState($manualBtn, $GUI_ENABLE)
        _SetButtonsState($lockArray, $GUI_ENABLE)
        GUICtrlSetData($statusID, "SİSTEM HAZIR")
        GUICtrlSetColor($statusID, 0x2C3E50)
    EndIf
EndFunc

Func StartWinws($ctrlID, $statusID, $aBtns)
    Local $savedStrategy = StringStripWS(FileRead($strategyFile), 3)
    If $savedStrategy = "" Then Return MsgBox(48, "Hata", "Önce analiz yapın.")
    Local $fullCommand = '"' & $winwsPath & '" --wf-tcp=0-65535 --wf-udp=0-65535 ' & $savedStrategy
    If GUICtrlRead($chkAutoHost) = $GUI_CHECKED Then $fullCommand &= ' --hostlist-auto="' & $hostlistPath & '"'
    $zapretPID = Run($fullCommand, @ScriptDir & "\zapret\zapret-winws\", @SW_HIDE)
    If $zapretPID > 0 Then
        $isZapretRunning = True
        GUICtrlSetData($ctrlID, "DURDUR")
        GUICtrlSetData($statusID, "MANUEL MOD AKTİF")
        GUICtrlSetColor($statusID, 0xE67E22)
        _SetButtonsState($aBtns, $GUI_DISABLE)
    EndIf
EndFunc

Func StopWinws($ctrlID, $statusID, $aBtns)
    If ProcessExists($zapretPID) Then ProcessClose($zapretPID)
    While ProcessExists("winws.exe")
        ProcessClose("winws.exe")
    WEnd
    RunWait(@ComSpec & " /c sc stop WinDivert & sc delete WinDivert & sc stop WinDivert14 & sc delete WinDivert14", "", @SW_HIDE)
    $isZapretRunning = False
    GUICtrlSetData($ctrlID, "ZAPRET'İ BAŞLAT")
    CheckServiceStatus($ctrlID, $statusID, $aBtns, $chkAutoHost)
EndFunc

Func InstallServiceClean($chkID)
    Local $savedStrategy = StringStripWS(FileRead($strategyFile), 3)
    If $savedStrategy = "" Then Return MsgBox(48, "Hata", "Önce analiz yapın.")
    Local $binArgs = '--wf-tcp=80,443 --wf-udp=443,50000-50099 ' & $savedStrategy
    If GUICtrlRead($chkID) = $GUI_CHECKED Then
        If Not FileExists($hostlistPath) Then FileWrite($hostlistPath, "")
        $binArgs &= ' --hostlist-auto="' & $hostlistPath & '"'
    EndIf
    Local $fullBinPath = '"' & $winwsPath & '" ' & $binArgs
	$fullBinPath = StringReplace($fullBinPath, '"', '\"')
    RemoveService()
    Sleep(500)
    If RunWait(@ComSpec & " /c sc create " & $serviceName & ' binPath= "' & $fullBinPath & '" start= auto', "", @SW_HIDE) = 0 Then
        RunWait(@ComSpec & " /c sc start " & $serviceName, "", @SW_HIDE)
        MsgBox(64, "Başarılı", "Servis kuruldu." & @CRLF & @CRLF & "Zapret bu programı açmasanız da çalışacaktır.")
    EndIf
EndFunc

Func RemoveService()
    RunWait(@ComSpec & " /c sc stop " & $serviceName & " & sc delete " & $serviceName & " & sc stop WinDivert & sc delete WinDivert & sc stop WinDivert14 & sc delete WinDivert14", "", @SW_HIDE)
EndFunc

Func RunBlockcheck($ctrlID)
    If FileExists($logPath) Then FileDelete($logPath)
    Run($blockcheckPath, @ScriptDir & "\zapret\blockcheck", @SW_HIDE)
    Local $hTimer = TimerInit()
    Do
        Sleep(100)
        If WinExists("[Class:ConsoleWindowClass]") Then
            WinSetState("[Class:ConsoleWindowClass]", "", @SW_HIDE)
        EndIf
    Until (Not ProcessExists("bash.exe")) And (TimerDiff($hTimer) > 10000)
    ExtractSummary($logPath)
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

    ; --- DÜZELTME BURADA ---
    If $found And $strategy <> "" Then
        ; Dosyayı mod 2 (overwrite) ile açıp yazıyoruz, böylece eski veri siliniyor
        Local $hFile = FileOpen($strategyFile, 2)
        If $hFile <> -1 Then
            FileWrite($hFile, $strategy)
            FileClose($hFile)
        EndIf
    EndIf
EndFunc
