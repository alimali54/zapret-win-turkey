#include-once ; #include <_SelfWatchDog.au3>
;~ #AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <Date.au3>
#include <WinAPI.au3>
#include <WinAPISys.au3>
#include <WinAPIError.au3>

; #INDEX# ====================================================================================================================
; Title .........: SelfWatchDog
; AutoIt Version : 3.3.16.1+
; Language ......: English
; Description ...: A self-contained process watchdog UDF that attaches as a lightweight debugger to capture unhandled
;                  exceptions and generate crash minidumps (.dmp) for post-mortem analysis.
; Author(s) .....: argumentum
; Link ..........: https://www.autoitscript.com/forum/topic/213815-_selfwatchdogau3-debug-minidump-udf/
; ============================================================================================================================

; #GLOBAL VARIABLES# =========================================================================================================
Global $__g_SelfWatchDog_Version = "0.2026.08.02"
Global $__g_SelfWatchDog_LogsFolder = @ScriptDir
Global $__g_SelfWatchDog_CreateDbgDmp = True
Global $__g_SelfWatchDog_WriteLogOnNonZeroExit = False
Global $__g_SelfWatchDog_TrayToolTip = 0 ; Default: don't show
Global $__g_SelfWatchDog_MsgBox = False ; silent gathering of developer debug info, or not.
; ============================================================================================================================

;~ _SelfWatchDog_MyLoader() ; this would go in your script, not here.
Func _SelfWatchDog_MyLoader() ; this is an example
    ; set these before running "_SelfWatchDog_Load()" if you wanna change the defaults
;~  ConsoleWrite('- UDF ( SelfWatchDog ) version: ' & _SelfWatchDog_Version() & @CRLF) ;             Uncomment to test
;~  _SelfWatchDog_LogsFolder(@ScriptDir) ; Default = @ScriptDir ;                                    Uncomment to test
;~  _SelfWatchDog_LogsFolder("") ; Default = @ScriptDir ; ( disable creating .log and .dmp )         Uncomment to test
    _SelfWatchDog_WriteLogOnNonZeroExit(True) ; Default = False ;                                    Uncomment to test
    _SelfWatchDog_TrayToolTip(1) ; Default = 0 (don't show) ;                                        Uncomment to test
;~  _SelfWatchDog_CreateDbgDmp(False) ; Default = True ;  ( disable creating .dmp )                  Uncomment to test
    _SelfWatchDog_MsgBox(True) ; Default = False ;                                                   Uncomment to test

    If Not _SelfWatchDog_Load() Then ConsoleWrite('! "SelfWatchDog" did not load !' & @CRLF) ;       Uncomment to test
    ; or comment it out and load it in your script at your leasure
    ; but should be loaded before it crashes as otherwise we're too late to attach the debugger.
    ; FYI: ..can only attach one debbuger to a process.

    ; --- TEST CRASH (Uncomment to test) ---
;~  DllCall("ntdll.dll", "none", "RtlMoveMemory", "ptr", 0, "str", "Crash", "ulong", 4) ;0xC0000005; Uncomment to test
    Exit 1234 ;                                                                                      Uncomment to test
EndFunc   ;==>_SelfWatchDog_MyLoader

; ===================================================================
; SelfWatchDog Initialization / Auto-Launcher ( if you load _SelfWatchDog_Load() from the UDF )
; ===================================================================

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_Load
; Description ...: Initializes the SelfWatchDog system. If run as main script, spawns and waits for watchdog stub attachment.
;                  If spawned as watchdog stub, attaches debugger to target process and monitors execution.
; Syntax ........: _SelfWatchDog_Load()
; Parameters ....: None
; Return values .: True on successful parent startup and debugger attach, or exits process if acting as watchdog stub.
;                  Returns False and sets @error on launch or attachment failure.
; Author ........: argumentum ; changed in "0.2026.07.30" / "0.2026.08.01"
; Related .......: _SelfWatchDog_WaitForDebugger, _SelfWatchDog_MonitorProcess
; ============================================================================================================================
Func _SelfWatchDog_Load()
    If StringInStr($CmdLineRaw, "/SelfWatchDog*") Then

        Opt("TrayAutoPause", 0) ; 0 = no pause
        Opt("TrayIconDebug", 0) ; 0 = (default) no debug information
        Opt("TrayMenuMode", 1) ;  1 = no default menu

        For $n = 1 To $CmdLine[0]
            If StringInStr($CmdLine[$n], "/SelfWatchDog*") Then
                Local $aArray = StringSplit($CmdLine[$n], "*", 0)
                If $aArray[0] >= 3 Then _SelfWatchDog_WriteLogOnNonZeroExit(Int($aArray[3]))
                If $aArray[0] >= 4 Then _SelfWatchDog_LogsFolder(String($aArray[4]))
                If $aArray[0] >= 5 Then _SelfWatchDog_MsgBox(Int($aArray[5]))
                If $aArray[0] >= 6 Then _SelfWatchDog_CreateDbgDmp(Int($aArray[6]))
                If $aArray[0] >= 7 Then _SelfWatchDog_TrayToolTip(Int($aArray[7]))

                Switch _SelfWatchDog_TrayToolTip()
                    Case 0
                        Opt("TrayIconHide", 1)
                    Case 1 ; "#NoTrayIcon" will reflect in Opt("TrayIconHide")
                        If Not Opt("TrayIconHide") Then TraySetIcon("shell32.dll", -72)
                    Case 2
                        TraySetState()
                        TraySetIcon("shell32.dll", -72) ; "File with gears" looking icon
                EndSwitch

                _SelfWatchDog_MonitorProcess(Int($aArray[2]))
                Exit
            EndIf
        Next
        Exit MsgBox(16 + 262144, StringTrimRight(@ScriptName, 4), "WFT ?!" & @LF & $CmdLineRaw, 600)
    Else
        AutoItWinSetTitle(StringTrimRight(@ScriptName, 4) & "-STUB") ; meh, ..easier to find in ControlViewer

        Local $sCmdArgs = _SelfWatchDog_CmdLine() & _
                '"/SelfWatchDog*' & @AutoItPID & _
                '*' & Int(_SelfWatchDog_WriteLogOnNonZeroExit()) & _
                '*' & String(_SelfWatchDog_LogsFolder()) & _
                '*' & Int(_SelfWatchDog_MsgBox()) & _
                '*' & Int(_SelfWatchDog_CreateDbgDmp()) & _
                '*' & Int(_SelfWatchDog_TrayToolTip()) & _
                '*" '

        Local $iWatchDogPID = ShellExecute(@AutoItExe, _
                (@AutoItExe = @ScriptFullPath ? '' : '"' & @ScriptFullPath & '" ') & $sCmdArgs)

        If Not $iWatchDogPID Or Not ProcessWait($iWatchDogPID, 10) Then
            Return SetError(1, 0, False) ; Failed to launch watchdog process
        EndIf

        If Not _SelfWatchDog_WaitForDebugger(5000) Then ; Block/wait until the spawned watchdog actually attaches ; faster than WinWait()
;~         If Not WinWait(StringTrimRight(@ScriptName, 4) & "-STUB-SelfWatchDog_PID:" & @AutoItPID, "", 5) Then ; if the above ain't working, use this line.
            Return SetError(2, 0, False) ; Watchdog process launched, but failed to attach within 5 seconds
        EndIf
        Return True
    EndIf
EndFunc   ;==>_SelfWatchDog_Load


; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_WaitForDebugger
; Description ...: Pauses execution until a watchdog or debugger attaches to the current process.
; Syntax ........: _SelfWatchDog_WaitForDebugger([$iTimeoutMs = 3000])
; Parameters ....: $iTimeoutMs - [optional] Max time to wait in milliseconds. Default is 3000 (3 seconds).
; Return values .: Success: Returns True when debugger is detected.
;                  Failure: Returns False and sets @error = 1 if timed out.
; Author ........: argumentum ; new in "0.2026.07.30"
; ============================================================================================================================
Func _SelfWatchDog_WaitForDebugger($iTimeoutMs = 3000)
    Local $aResult, $hTimer = TimerInit()
    While 1
        $aResult = DllCall("kernel32.dll", "bool", "IsDebuggerPresent")
        If Not @error And $aResult[0] Then Return True ; Query Windows PEB BeingDebugged flag
        If TimerDiff($hTimer) > $iTimeoutMs Then Return SetError(1, 0, False)
        Sleep(10)
    WEnd
EndFunc   ;==>_SelfWatchDog_WaitForDebugger

; #INTERNAL_USE_ONLY# =========================================================================================================
; Name ..........: _SelfWatchDog_MonitorProcess
; Description ...: Attaches to the target process via Win32 Debug API and loops waiting for exception debug events.
; Syntax ........: _SelfWatchDog_MonitorProcess($iTargetPID)
; Parameters ....: $iTargetPID - Process ID (PID) of the application to monitor.
; Return values .: True on normal process exit, False on attach failure.
; Author ........: argumentum ; changed in "0.2026.07.30"
; ============================================================================================================================
Func _SelfWatchDog_MonitorProcess($iTargetPID)
    Local $iCounter = 0, $sDumpPath = _SelfWatchDog_LogsFolder() & "\" & StringTrimRight(@ScriptName, 4) & "-" & $iTargetPID & ".dmp"
    If _SelfWatchDog_LogsFolder() = "" Then
        $sDumpPath = ""
    Else
        If FileExists($sDumpPath) Then
            Do
                $iCounter += 1 ; hope you have a flawless script or clean up after yourself 😅
                $sDumpPath = _SelfWatchDog_LogsFolder() & "\" & StringTrimRight(@ScriptName, 4) & "-" & $iTargetPID & "[" & $iCounter & "].dmp"
            Until Not FileExists($sDumpPath)
        EndIf
    EndIf

    Local $sLogPath = _SelfWatchDog_LogsFolder() & "\" & StringTrimRight(@ScriptName, 4) & "-WatchDog.log"
    _SelfWatchDog_Log($sLogPath, "Watchdog started for PID: " & $iTargetPID & ' - (' & (@AutoItX64 ? "64bit" : "32bit") & ') - ' & @ScriptFullPath)
    _SelfWatchDog_EnableDebugPrivilege() ; Attempt to enable SeDebugPrivilege (ignored safely if non-Admin)
    Local $aRet = DllCall("kernel32.dll", "bool", "DebugActiveProcess", "dword", $iTargetPID)
    If @error Or Not $aRet[0] Then ; Attach as lightweight debugger
        _SelfWatchDog_Log($sLogPath, "DebugActiveProcess failed! Error: " & _WinAPI_GetLastError())
        _SelfWatchDog_Log()
        Return False
    EndIf
    AutoItWinSetTitle(StringTrimRight(@ScriptName, 4) & "-STUB-SelfWatchDog_PID:" & $iTargetPID) ; here is better because is actually running ; "0.2026.08.01"
    If _SelfWatchDog_TrayToolTip() Then
        TraySetToolTip("[SelfWatchDog]" & @LF & @ScriptName & @LF & 'on PID:' & $iTargetPID & @LF & @LF & " ")
    EndIf
    _SelfWatchDog_Log($sLogPath, "Successfully attached debugger to PID: " & $iTargetPID)
    Local $iUnionOffset = @AutoItX64 ? 16 : 12
    Local $iFirstChanceOffset = @AutoItX64 ? 168 : 92
    Local $tDebugEvent = DllStructCreate("byte Data[256]")
    Local $pDebugEvent = DllStructGetPtr($tDebugEvent)

    Local $DBG_CONTINUE = 0x00010002
    Local $DBG_EXCEPTION_NOT_HANDLED = 0x80010001
    Local $sHexCodeWas, $tHeader, $aCont, $bDumpWritten = False, $bOops = False, $bInitialBpLogged = False, $iExitCode = 0
    Local $iEventCode, $iPID, $iTID, $iStatus, $tFile, $hFile, $tException, $iExCode, $sHexCode, $tFirstChance, $bFirstChance
    While ProcessExists($iTargetPID)
        $aRet = DllCall("kernel32.dll", "bool", "WaitForDebugEvent", "ptr", $pDebugEvent, "dword", 500)
        If @error Or Not $aRet[0] Then ContinueLoop ; Poll for debug events (500ms timeout)
        $tHeader = DllStructCreate("dword EventCode;dword PID;dword TID", $pDebugEvent)
        $iEventCode = DllStructGetData($tHeader, "EventCode") ; Parse Debug Event Header (EventCode = 0..3, PID = 4..7, TID = 8..11)
        $iPID = DllStructGetData($tHeader, "PID")
        $iTID = DllStructGetData($tHeader, "TID")
        $iStatus = $DBG_CONTINUE
        If $iEventCode = 3 Or $iEventCode = 6 Then ; Event 3 = CREATE_PROCESS_DEBUG_EVENT, Event 6 = LOAD_DLL_DEBUG_EVENT
            $tFile = DllStructCreate("handle hFile", $pDebugEvent + $iUnionOffset)
            $hFile = DllStructGetData($tFile, "hFile")
            If $hFile Then DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hFile)

        ElseIf $iEventCode = 1 Then ; Event 1 = EXCEPTION_DEBUG_EVENT
            $tException = DllStructCreate("dword ExceptionCode", $pDebugEvent + $iUnionOffset)
            $iExCode = DllStructGetData($tException, "ExceptionCode")
            $sHexCode = "0x" & Hex($iExCode, 8)

            $tFirstChance = DllStructCreate("dword FirstChance", $pDebugEvent + $iFirstChanceOffset)
            $bFirstChance = (DllStructGetData($tFirstChance, "FirstChance") <> 0)

            If $sHexCode = "0x80000003" Or $sHexCode = "0x4000001F" Or $sHexCode = "0x40010006" Then
                If Not $bInitialBpLogged Then ; Breakpoint & Informational Signals (0x80000003, 0x4000001F, 0x40010006, etc.)
                    _SelfWatchDog_Log($sLogPath, "Debugger attached successfully (Initial Breakpoint acknowledged)")
                    $bInitialBpLogged = True
                EndIf
                $iStatus = $DBG_CONTINUE

            ElseIf $bFirstChance Then ; First-Chance Exception ; Pass back to OS so internal SEH/VEH/__try/__except blocks can handle it
                $iStatus = $DBG_EXCEPTION_NOT_HANDLED

            Else ; Second-Chance Exception (True Unhandled Fatal Crash)
                If $sHexCodeWas <> $sHexCode Then
                    _SelfWatchDog_Log($sLogPath, "Fatal Crash Exception caught: " & $sHexCode)
                    _SelfWatchDog_Log($sLogPath, _SelfWatchDog_ExplainExitCode($iExCode, $pDebugEvent))
                EndIf
                $sHexCodeWas = $sHexCode
                $bOops = True

                If _SelfWatchDog_IsFatalCode($sHexCode) And Not $bDumpWritten Then
                    If $sDumpPath <> "" Then
                        If _SelfWatchDog_CreateDbgDmp() Then
                            _SelfWatchDog_Log($sLogPath, "Fatal crash detected! Generating MiniDump...")
                            Local $sErrorDetails = ""
                            If _SelfWatchDog_WriteMiniDump($iTargetPID, $sDumpPath, $sErrorDetails) Then
                                If $sDumpPath <> "" Then _SelfWatchDog_Log($sLogPath, "SUCCESS: MiniDump created -> " & $sDumpPath)
                            Else
                                If $sDumpPath <> "" Then _SelfWatchDog_Log($sLogPath, "ERROR: MiniDump creation failed! Details: " & $sErrorDetails)
                            EndIf
                        EndIf
                    EndIf
                    $bDumpWritten = True
                EndIf

                Local $aHProc = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", 0x0001, "bool", False, "dword", $iTargetPID)
                If Not @error And $aHProc[0] Then ; Terminate the crashed process so it doesn't spin in an infinite re-fault loop
                    DllCall("kernel32.dll", "bool", "TerminateProcess", "handle", $aHProc[0], "uint", $iExCode)
                    DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aHProc[0])
                EndIf

                $iStatus = $DBG_CONTINUE
            EndIf

        ElseIf $iEventCode = 5 Then ; Event 5 = EXIT_PROCESS_DEBUG_EVENT
            Local $tExitInfo = DllStructCreate("dword ExitCode", $pDebugEvent + $iUnionOffset)
            $iExitCode = DllStructGetData($tExitInfo, "ExitCode")
            Local $sHexExit = "0x" & Hex($iExitCode, 8)

            If $bDumpWritten Then
                _SelfWatchDog_Log($sLogPath, "Target process crashed and exited (ExitCode: " & $sHexExit & ")")
            ElseIf $iExitCode = 0 Then
                _SelfWatchDog_Log($sLogPath, "Target process exited cleanly (ExitCode: 0x00000000)")
            Else
                _SelfWatchDog_Log($sLogPath, "Target process exited with return code: " & $iExitCode & " (" & $sHexExit & ")")
            EndIf

            DllCall("kernel32.dll", "bool", "ContinueDebugEvent", "dword", $iPID, "dword", $iTID, "dword", $DBG_CONTINUE)
            ExitLoop
        EndIf

        $aCont = DllCall("kernel32.dll", "bool", "ContinueDebugEvent", "dword", $iPID, "dword", $iTID, "dword", $iStatus)
        If @error Or Not $aCont[0] Then ; Dispatch continue status to unfreeze the target thread
            _SelfWatchDog_Log($sLogPath, "ContinueDebugEvent failed! Error: " & _WinAPI_GetLastError())
        EndIf
    WEnd

    DllCall("kernel32.dll", "bool", "DebugActiveProcessStop", "dword", $iTargetPID)
    If $bOops Or ($__g_SelfWatchDog_WriteLogOnNonZeroExit And $iExitCode) Then _SelfWatchDog_Log()
EndFunc   ;==>_SelfWatchDog_MonitorProcess

; #INTERNAL_USE_ONLY# =========================================================================================================
; Name ..........: _SelfWatchDog_WriteMiniDump
; Description ...: Calls dbghelp.dll!MiniDumpWriteDump to generate a memory crash dump file.
; Syntax ........: _SelfWatchDog_WriteMiniDump($iPID, $sDumpPath, ByRef $sErrorDetails)
; Parameters ....: $iPID          - Target Process ID.
;                  $sDumpPath     - Full output file path for the .dmp file.
;                  $sErrorDetails - [ByRef] String variable receiving error diagnostics on failure.
; Return values .: Success - True
;                  Failure - False and sets $sErrorDetails.
; Author ........: argumentum
; Remarks .......: Tries MiniDumpWithFullMemory first, falling back to PrivateReadWriteMemory and MiniDumpNormal.
;                  If $sDumpPath = "" then it's skipped.
; ============================================================================================================================
Func _SelfWatchDog_WriteMiniDump($iPID, $sDumpPath, ByRef $sErrorDetails)
    If $sDumpPath = "" Then Return SetError(0, 1, True)

    Local $hProcess = _WinAPI_OpenProcess(0x0458, False, $iPID)
    If Not $hProcess Then     ; Open target process: QUERY_INFORMATION (0x0400) | VM_READ (0x0010) | DUP_HANDLE (0x0040) | VM_OPERATION (0x0008)
        $sErrorDetails = "OpenProcess failed (Error " & _WinAPI_GetLastError() & ")"
        Return False
    EndIf

    Local $aFileCall = DllCall("kernel32.dll", "handle", "CreateFileW", _
            "wstr", $sDumpPath, "dword", 0x40000000, _     ; GENERIC_WRITE (0x40000000), FILE_SHARE_READ (1), CREATE_ALWAYS (2)
            "dword", 1, "ptr", 0, "dword", 2, "dword", 0x80, _     ; FILE_ATTRIBUTE_NORMAL
            "ptr", 0)

    Local $hFile = @error ? 0 : $aFileCall[0]
    If Not $hFile Or $hFile = -1 Then
        $sErrorDetails = "CreateFileW failed (Error " & _WinAPI_GetLastError() & ")"
        _WinAPI_CloseHandle($hProcess)
        Return False
    EndIf


    Local $iDumpType = 0x00000002 ; Try dumping: MiniDumpWithFullMemory (0x00000002)
    Local $aResult = DllCall("dbghelp.dll", "bool", "MiniDumpWriteDump", _
            "handle", $hProcess, "dword", $iPID, "handle", $hFile, "int", $iDumpType, _
            "ptr", 0, "ptr", 0, "ptr", 0)

    Local $iWinErr = _WinAPI_GetLastError()

    If @error Or Not $aResult[0] Then
        $iDumpType = 0x00000235 ; Fallback 1: PrivateReadWriteMemory (0x00000235)
        $aResult = DllCall("dbghelp.dll", "bool", "MiniDumpWriteDump", _
                "handle", $hProcess, "dword", $iPID, "handle", $hFile, "int", $iDumpType, _
                "ptr", 0, "ptr", 0, "ptr", 0)
        $iWinErr = _WinAPI_GetLastError()
    EndIf

    If @error Or Not $aResult[0] Then
        $iDumpType = 0x00000000 ; Fallback 2: MiniDumpNormal (0x00000000)
        $aResult = DllCall("dbghelp.dll", "bool", "MiniDumpWriteDump", _
                "handle", $hProcess, "dword", $iPID, "handle", $hFile, "int", $iDumpType, _
                "ptr", 0, "ptr", 0, "ptr", 0)
        $iWinErr = _WinAPI_GetLastError()
    EndIf

    Local $bSuccess = (Not @error And $aResult[0])
    If Not $bSuccess Then $sErrorDetails = "MiniDumpWriteDump API Error: " & $iWinErr

    DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hFile)
    _WinAPI_CloseHandle($hProcess)

    Return $bSuccess
EndFunc   ;==>_SelfWatchDog_WriteMiniDump

; #INTERNAL_USE_ONLY# =========================================================================================================
; Name ..........: _SelfWatchDog_IsFatalCode
; Description ...: Determines if an exception code represents a severe/fatal crash across Native, C++, .NET, and Delphi.
; Syntax ........: _SelfWatchDog_IsFatalCode($sHexCode)
; Parameters ....: $sHexCode - Hexadecimal string (e.g. "0xC0000005").
; Return values .: True if fatal crash code, False otherwise.
; Author ........: argumentum
; Note ..........: capture crash minidumps for virtually any Windows executable, regardless of whether it
;                   was written in C, C++, C#, AutoIt, or Delphi!. But *you* thinker with that =)
; ============================================================================================================================
Func _SelfWatchDog_IsFatalCode($sHexCode)
    Local $sPrefix = StringLeft($sHexCode, 3)
    ; 1. 0xC... = Windows Native Kernel/Process Errors (Access Violation, Stack Overflow, Division by Zero, etc.)
    ; 2. 0xE... = Managed/Runtime Exceptions (MSVC C++ 0xE06D7363, .NET CLR 0xE0434352)
    ; 3. 0x0EEDFACE = Delphi / VCL Exceptions
    If $sPrefix = "0xC" Or $sPrefix = "0xE" Or $sHexCode = "0x0EEDFACE" Then Return True
    Return False
EndFunc   ;==>_SelfWatchDog_IsFatalCode

; #INTERNAL_USE_ONLY# =========================================================================================================
; Name ..........: _SelfWatchDog_EnableDebugPrivilege
; Description ...: Enables SeDebugPrivilege in the current process access token using advapi32.dll.
; Syntax ........: _SelfWatchDog_EnableDebugPrivilege()
; Parameters ....: None
; Return values .: Success - True
;                  Failure - False (e.g., non-admin rights)
; Author ........: argumentum
; ============================================================================================================================
Func _SelfWatchDog_EnableDebugPrivilege()
    Local $aCall = DllCall("kernel32.dll", "handle", "GetCurrentProcess")
    If @error Or Not $aCall[0] Then Return False
    Local $hProcess = $aCall[0]

    $aCall = DllCall("advapi32.dll", "bool", "OpenProcessToken", "handle", $hProcess, "dword", 0x0028, "handle*", 0)
    If @error Or Not $aCall[0] Then Return False
    Local $hToken = $aCall[3]

    Local $tLUID = DllStructCreate("dword LowPart;long HighPart")
    $aCall = DllCall("advapi32.dll", "bool", "LookupPrivilegeValueW", "ptr", 0, "wstr", "SeDebugPrivilege", "ptr", DllStructGetPtr($tLUID))
    If Not @error And $aCall[0] Then
        Local $tTokenPrivileges = DllStructCreate("dword Count;dword LowPart;long HighPart;dword Attributes")
        DllStructSetData($tTokenPrivileges, "Count", 1)
        DllStructSetData($tTokenPrivileges, "LowPart", DllStructGetData($tLUID, "LowPart"))
        DllStructSetData($tTokenPrivileges, "HighPart", DllStructGetData($tLUID, "HighPart"))
        DllStructSetData($tTokenPrivileges, "Attributes", 0x0002) ; SE_PRIVILEGE_ENABLED

        DllCall("advapi32.dll", "bool", "AdjustTokenPrivileges", "handle", $hToken, "bool", False, "ptr", DllStructGetPtr($tTokenPrivileges), "dword", DllStructGetSize($tTokenPrivileges), "ptr", 0, "ptr", 0)
    EndIf

    _WinAPI_CloseHandle($hToken)
    Return True
EndFunc   ;==>_SelfWatchDog_EnableDebugPrivilege

; #INTERNAL_USE_ONLY# =========================================================================================================
; Name ..........: _SelfWatchDog_Log
; Description ...: Writes a timestamped log line to the specified log path.
; Syntax ........: _SelfWatchDog_Log($sLogPath, $sMessage)
; Parameters ....: $sLogPath - Target log file path.
;                  $sMessage - Message text to log.
; Return values .: True on FileWriteLine success.
; Author ........: argumentum ; changed in "0.2026.07.30"
; Remarks .......: if $sLogPath = "" then $sLogPath = @ScriptDir
; ============================================================================================================================
Func _SelfWatchDog_Log($sLogPath = Default, $sMessage = "")
    Local Static $_sStr = @CRLF, $_sMsg = "", $_sLogPath = $sLogPath
    If IsKeyword($sLogPath) Then
        $_sStr = StringReplace($_sStr, @CRLF & @CRLF, @CRLF)
        If $_sLogPath = "" Then $_sLogPath = @ScriptDir
        FileWriteLine($_sLogPath, $_sStr & @CRLF)
        If $__g_SelfWatchDog_MsgBox Then MsgBox(16 + 262144, StringTrimRight(@ScriptName, 4), $_sMsg, 600)
    EndIf
    $_sStr &= _NowCalc() & " | " & $sMessage & @CRLF
    $_sMsg &= StringReplace($sMessage, @CRLF, @LF) & @LF & @LF
EndFunc   ;==>_SelfWatchDog_Log

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_LogsFolder
; Description ...: Gets or sets the global output directory for created crash minidumps and logs.
; Syntax ........: _SelfWatchDog_LogsFolder([$sFullPath = Default])
; Parameters ....: $sFullPath - [optional] Directory path to set as default output location. Default is @ScriptDir
;                  $sFullPath = "" will disable creating *.dmp and *.log files
; Return values .: Returns the current dump folder path string.
; Author ........: argumentum
; Related .......: _SelfWatchDog_Load
; Remarks .......: ..the idea is to have a dump file but if all you want to do is catch errors while coding then
;                  set the $sFullPath = "" and skip the creation of files because you may not want to delete countless files.
;                  On the other hand, if the crash is sporadic, then do collect as much info as you can.
;                  That is my train of thought at the moment of coding this.
; ============================================================================================================================
Func _SelfWatchDog_LogsFolder($sFullPath = Default)
    If Not IsKeyword($sFullPath) And (FileExists($sFullPath) Or $sFullPath = "") Then $__g_SelfWatchDog_LogsFolder = $sFullPath
    Return $__g_SelfWatchDog_LogsFolder
EndFunc   ;==>_SelfWatchDog_LogsFolder

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_CreateDbgDmp
; Description ...: Sets or retrieves the flag that controls whether mini-dump (.dmp) files are generated on crash.
; Syntax ........: _SelfWatchDog_CreateDbgDmp([$bYesNo = Default])
; Parameters ....: $bYesNo      - [optional] True to enable dump file creation, False to disable.
;                                  Default is return setting.
; Return values .: Current boolean state of dump file creation (True = Enabled, False = Disabled).
; Author ........: argumentum
; Related .......: _SelfWatchDog_LogsFolder, _SelfWatchDog_WriteMiniDump, _SelfWatchDog_MonitorProcess
; Remarks .......: You may want to write logs but not the dumps.
; ============================================================================================================================
Func _SelfWatchDog_CreateDbgDmp($bYesNo = Default)
    If Not IsKeyword($bYesNo) Then $__g_SelfWatchDog_CreateDbgDmp = Not Not $bYesNo
    Return $__g_SelfWatchDog_CreateDbgDmp
EndFunc   ;==>_SelfWatchDog_CreateDbgDmp

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_WriteLogOnNonZeroExit
; Description ...: Gets or sets whether the watchdog should write a log entry when the target process exits with a custom non-zero code.
; Syntax ........: _SelfWatchDog_WriteLogOnNonZeroExit([$bYesNo = Default])
; Parameters ....: $bYesNo - [optional] Boolean flag (True/False) to enable or disable logging non-zero exits. Default is False
; Return values .: Returns the current boolean setting state (True or False). Default is False.
; Author ........: argumentum
; Related .......: _SelfWatchDog_Load
; ============================================================================================================================
Func _SelfWatchDog_WriteLogOnNonZeroExit($bYesNo = Default)
    If Not IsKeyword($bYesNo) Then $__g_SelfWatchDog_WriteLogOnNonZeroExit = Not Not $bYesNo
    Return $__g_SelfWatchDog_WriteLogOnNonZeroExit
EndFunc   ;==>_SelfWatchDog_WriteLogOnNonZeroExit

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_TrayToolTip
; Description ...: Gets or sets the tray icon visibility and information display level.
; Syntax ........: _SelfWatchDog_TrayToolTip([$iLevel = Default])
; Parameters ....: $iLevel - [optional] Integer value defining the tray icon behavior:
;                  |0 - Hide tray icon.
;                  |1 - Set tray icon info.
;                  |2 - Force tray icon show.
; Return values .: Returns the current tray icon level setting (Integer).
; Author ........: argumentum
; Related .......: _SelfWatchDog_Load
; Remarks .......; Tray icon will not show exit menu. Is there just to show that is loaded.
; ============================================================================================================================
Func _SelfWatchDog_TrayToolTip($iLevel = Default)
    If Not IsKeyword($iLevel) Then $__g_SelfWatchDog_TrayToolTip = Int($iLevel)
    Return $__g_SelfWatchDog_TrayToolTip
EndFunc   ;==>_SelfWatchDog_TrayToolTip

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_MsgBox
; Description ...: Gets or sets whether the watchdog displays a graphical notification dialog when a process crashes.
; Syntax ........: _SelfWatchDog_MsgBox([$bYesNo = Default])
; Parameters ....: $bYesNo - [optional] Boolean flag (True/False) to enable or disable crash alert popups. Default is False.
; Return values .: Returns the current boolean setting state (True or False).
; Author ........: argumentum
; Related .......: _SelfWatchDog_ExplainExitCode, _SelfWatchDog_LogsFolder
; ============================================================================================================================
Func _SelfWatchDog_MsgBox($bYesNo = Default)
    If Not IsKeyword($bYesNo) Then $__g_SelfWatchDog_MsgBox = Not Not $bYesNo
    Return $__g_SelfWatchDog_MsgBox
EndFunc   ;==>_SelfWatchDog_MsgBox

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_CmdLine
; Description ...: Reconstructs the full command-line arguments string, wrapping any arguments containing spaces in quotes.
; Syntax ........: _SelfWatchDog_CmdLine()
; Parameters ....: None
; Return values .: Success - Returns a string containing the reconstructed command-line parameters.
;                  @extended - Contains the count of command-line arguments ($CmdLine[0]).
; Author ........: argumentum
; Related .......: _SelfWatchDog_Load
; ============================================================================================================================
Func _SelfWatchDog_CmdLine()
    Local $sCmdArgs = ""
    For $n = 1 To $CmdLine[0]
        $sCmdArgs &= (StringInStr($CmdLine[$n], " ") ? '"' & $CmdLine[$n] & '"' : $CmdLine[$n]) & " "
    Next
    Return SetError(0, $CmdLine[0], $sCmdArgs)
EndFunc   ;==>_SelfWatchDog_CmdLine

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_Version
; Description ...: Returns the current version string of the SelfWatchDog UDF.
; Syntax ........: _SelfWatchDog_Version()
; Parameters ....: None
; Return values .: String containing the UDF version number.
; Author ........: argumentum
; Related .......: _SelfWatchDog_Load
; ============================================================================================================================
Func _SelfWatchDog_Version()
    Return $__g_SelfWatchDog_Version
EndFunc   ;==>_SelfWatchDog_Version

; #FUNCTION# ====================================================================================================================
; Name ..........: _SelfWatchDog_ExplainExitCode
; Description ...: Translates a process exit or crash code into human-readable system text and actionable developer explanations.
; Syntax ........: _SelfWatchDog_ExplainExitCode($iExitCode[, $pDebugEvent = 0])
; Parameters ....: $iExitCode    - Process exit code or NTSTATUS crash code (32-bit integer).
;                  $pDebugEvent  - [optional] Pointer to DEBUG_EVENT struct for live access violation pointer extraction.
; Return values .: String containing the formatted hex code, live memory instruction details, system status, and dev notes.
; Author ........: argumentum
; Related .......: _SelfWatchDog_GetNTStatusText, _SelfWatchDog_GetAccessViolationText
; Link ..........: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-erref/596a1078-e883-4972-9bbc-49e60bebca55
; ============================================================================================================================
Func _SelfWatchDog_ExplainExitCode($iExitCode, $pDebugEvent = 0)
    Local $sDynamicDetail = "", $sHexCode = "0x" & Hex($iExitCode, 8)
    If $iExitCode = 0 Then Return "[0x00000000] Process completed successfully."

    Local $sSysMessage = _SelfWatchDog_GetNTStatusText($iExitCode)
    If $sSysMessage = "" Then $sSysMessage = "Unknown Exception / Exit Code"

    Local $sDevNote = ""
    Switch $sHexCode
        ; --- Native Memory & Pointer Violations ---
        Case "0xC0000005"
            If $pDebugEvent Then $sDynamicDetail = _SelfWatchDog_GetAccessViolationText($pDebugEvent)
            $sDevNote = "Cause: Access Violation (Segmentation Fault)." & @CRLF & @CRLF & _
                    "Troubleshooting: Reading/writing unallocated memory, NULL pointer dereference, or invalid DllCall parameter types."

        Case "0xC0000008"
            $sDevNote = "Cause: Invalid Handle." & @CRLF & @CRLF & _
                    "Troubleshooting: Operation performed on a closed, uninitialized, or corrupt Win32 handle."

        Case "0xC0000374"
            $sDevNote = "Cause: Heap Corruption." & @CRLF & @CRLF & _
                    "Troubleshooting: Memory buffer overflow, double-freeing pointers, or struct size mismatch in DllCall/DllStructCreate."

        Case "0xC0000017"
            $sDevNote = "Cause: Out of Memory (STATUS_NO_MEMORY)." & @CRLF & @CRLF & _
                    "Troubleshooting: Process exhausted physical RAM or commit limit during allocation."

            ; --- Stack & Control Flow Faults ---
        Case "0xC00000FD"
            $sDevNote = "Cause: Stack Overflow." & @CRLF & @CRLF & _
                    "Troubleshooting: Infinite recursive function loop or allocating excessively large local variables."

        Case "0xC0000409"
            $sDevNote = "Cause: Stack Buffer Overrun (/GS fast-fail)." & @CRLF & @CRLF & _
                    "Troubleshooting: Windows Security hard-terminated process due to memory buffer boundary corruption."

        Case "0xC000001D"
            $sDevNote = "Cause: Illegal Instruction." & @CRLF & @CRLF & _
                    "Troubleshooting: CPU executed invalid machine code, corrupt memory, or unsupported instruction set (e.g., AVX2 on legacy CPU)."

        Case "0xC000041D"
            $sDevNote = "Cause: Unhandled Exception in User Callback." & @CRLF & @CRLF & _
                    "Troubleshooting: A crash occurred inside a Window Procedure (WndProc) or low-level Windows hook callback."

            ; --- Dependency & DLL Loading Failures ---
        Case "0xC0000135"
            $sDevNote = "Cause: Dependent DLL Not Found." & @CRLF & @CRLF & _
                    "Troubleshooting: A required third-party or system .dll is missing from system path."

        Case "0xC0000138"
            $sDevNote = "Cause: Ordinal Not Found." & @CRLF & @CRLF & _
                    "Troubleshooting: Target DLL exists, but the requested function ordinal/index was missing."

        Case "0xC0000139"
            $sDevNote = "Cause: Entry Point Not Found." & @CRLF & @CRLF & _
                    "Troubleshooting: Target DLL exists, but the specific function export name was not found."

        Case "0xC0000142"
            $sDevNote = "Cause: DLL Initialization Failed." & @CRLF & @CRLF & _
                    "Troubleshooting: Required DLL loaded, but its DllMain entry point returned FALSE or crashed on startup."

            ; --- Arithmetic & Hardware Exceptions ---
        Case "0xC000008C", "0xC0000094"
            $sDevNote = "Cause: Integer Division by Zero or Overflow." & @CRLF & @CRLF & _
                    "Troubleshooting: Math calculation attempted a division by zero or integer overflow."

        Case "0xC0000096"
            $sDevNote = "Cause: Privileged Instruction." & @CRLF & @CRLF & _
                    "Troubleshooting: Assembly executed Ring 0/kernel privileged code from user space."

        Case "0x80000002"
            $sDevNote = "Cause: Datatype Misalignment." & @CRLF & @CRLF & _
                    "Troubleshooting: CPU read/write operation targeted an unaligned memory offset."

            ; --- High-Level Runtimes & Framework Exceptions ---
        Case "0xE06D7363"
            $sDevNote = "Cause: Unhandled MSVC C++ Exception." & @CRLF & @CRLF & _
                    "Troubleshooting: An unhandled C++ 'throw' exception bubbled up from a compiled C++ DLL."

        Case "0xE0434352"
            $sDevNote = "Cause: Unhandled .NET CLR Exception." & @CRLF & @CRLF & _
                    "Troubleshooting: An unhandled Managed C#/VB.NET exception occurred inside a loaded .NET assembly."

        Case "0x0EEDFACE", "0x0EEDFADE"
            $sDevNote = "Cause: Unhandled Delphi/VCL Runtime Exception." & @CRLF & @CRLF & _
                    "Troubleshooting: An unhandled Object Pascal runtime exception occurred in a Delphi DLL or executable."

            ; --- Process Environment & Interruption ---
        Case "0xC0000006"
            $sDevNote = "Cause: In-Page I/O Error." & @CRLF & @CRLF & _
                    "Troubleshooting: Executable or DLL dropped connection while paging code from a network drive or USB flash drive."

        Case "0xC000013A"
            $sDevNote = "Cause: Control-C Exit." & @CRLF & @CRLF & _
                    "Troubleshooting: Application was killed abruptly via console terminate, user logout, or CTRL+C signal."

        Case "0x80000003"
            $sDevNote = "Cause: Breakpoint Hit." & @CRLF & @CRLF & _
                    "Troubleshooting: A debug breakpoint (INT 3) was encountered with no attached debugger to handle it."
    EndSwitch

    Local $sOutput = $sSysMessage
    If $sDynamicDetail <> "" Then $sOutput = $sDynamicDetail
    If $sDevNote <> "" Then $sOutput &= @CRLF & @CRLF & $sDevNote

    Return $sOutput
EndFunc   ;==>_SelfWatchDog_ExplainExitCode

; #INTERNAL_USE_ONLY# =========================================================================================================
; Name ..........: _SelfWatchDog_GetAccessViolationText
; Description ...: Extracts instruction and memory pointers from an EXCEPTION_DEBUG_EVENT for Access Violations (0xC0000005).
; Syntax ........: _SelfWatchDog_GetAccessViolationText($pDebugEvent)
; Parameters ....: $pDebugEvent - Pointer or DllStruct to the DEBUG_EVENT structure.
; Return values .: Formatted string with memory address, instruction pointer, and operation type (read/written/executed).
; Author ........: argumentum ; new in "0.2026.07.30"
; Related .......: _SelfWatchDog_ExplainExitCode
; ============================================================================================================================
Func _SelfWatchDog_GetAccessViolationText($pDebugEvent)
    Local $pBase = $pDebugEvent ; just in case ; am not experienced with these
    If IsDllStruct($pBase) Then $pBase = DllStructGetPtr($pBase)
    If Not IsPtr($pBase) Then $pBase = Ptr($pBase)
    Local $iCodeOffset = @AutoItX64 ? 16 : 12
    Local $tRecord, $pRecord = Ptr($pBase + $iCodeOffset)
    If @AutoItX64 Then
        $tRecord = DllStructCreate("dword Code;dword Flags;uint64 Record;uint64 Address;dword NumParams;dword Pad;uint64 Info[15]", $pRecord)
    Else
        $tRecord = DllStructCreate("dword Code;dword Flags;ptr Record;ptr Address;dword NumParams;ulong_ptr Info[15]", $pRecord)
    EndIf
    Local $pInstruction = DllStructGetData($tRecord, "Address")
    Local $iNumParams = DllStructGetData($tRecord, "NumParams")
    Local $iHexLen = @AutoItX64 ? 16 : 8
    Local $sInstHex = "0x" & Hex($pInstruction, $iHexLen)
    If $iNumParams < 2 Then ; If parameters aren't populated yet, fallback
        Return StringFormat("The instruction at %s referenced memory at an unknown address.", $sInstHex)
    EndIf
    Local $iOpType = DllStructGetData($tRecord, "Info", 1)    ; Index 1 = Info[0] (0 = Read, 1 = Write, 8 = Execute)
    Local $pTargetMem = DllStructGetData($tRecord, "Info", 2) ; Index 2 = Info[1] (Faulting Memory Address)
    Local $sOpText, $sMemHex = "0x" & Hex($pTargetMem, $iHexLen)
    Select
        Case $iOpType = 0
            $sOpText = "read"
        Case $iOpType = 1
            $sOpText = "written"
        Case $iOpType = 8
            $sOpText = "executed"
        Case Else
            $sOpText = "accessed"
    EndSelect
    Return StringFormat("The instruction at %s referenced memory at %s. The memory could not be %s.", $sInstHex, $sMemHex, $sOpText)
EndFunc   ;==>_SelfWatchDog_GetAccessViolationText

; #INTERNAL_USE_ONLY# =========================================================================================================
; Name ..........: _SelfWatchDog_GetNTStatusText
; Description ...: Formats an NTSTATUS or Win32 status code into its official system error message using ntdll.dll.
; Syntax ........: _SelfWatchDog_GetNTStatusText($iStatus)
; Parameters ....: $iStatus - The NTSTATUS / Win32 integer code.
; Return values .: Success - String message extracted from ntdll.dll message resources.
;                  Failure - Empty string.
; Author ........: argumentum
; Related .......: _SelfWatchDog_ExplainExitCode
; ============================================================================================================================
Func _SelfWatchDog_GetNTStatusText($iStatus)
    Local $hNtDll = _WinAPI_GetModuleHandle("ntdll.dll")
    Local $aResult = DllCall("kernel32.dll", "dword", "FormatMessageW", _
            "dword", 0x0B00, _ ; FORMAT_MESSAGE_ALLOCATE_BUFFER (0x100) | FORMAT_MESSAGE_FROM_HMODULE (0x800) | FORMAT_MESSAGE_IGNORE_INSERTS (0x200)
            "ptr", $hNtDll, "dword", $iStatus, "dword", 0, "ptr*", 0, "dword", 0, "ptr", 0)
    If @error Or Not $aResult[0] Or Not $aResult[5] Then Return ""
    Local $sMsg = DllStructGetData(DllStructCreate("wchar[" & $aResult[0] & "]", $aResult[5]), 1)
    DllCall("kernel32.dll", "ptr", "LocalFree", "ptr", $aResult[5])
    Return StringStripWS($sMsg, 3)
EndFunc   ;==>_SelfWatchDog_GetNTStatusText