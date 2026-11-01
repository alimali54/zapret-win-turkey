#include-once

#include <SendMessage.au3>
#include <GuiMonthCal.au3>
#include <WinAPIGdiInternals.au3>
#include <WinAPISysWin.au3>
#include <WinAPIGdi.au3>
#include <WinAPIShellEx.au3>
#include <WinAPISys.au3>
#include <WinAPIProc.au3>
#include <WinAPIConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiToolbar.au3>
#include <GuiIPAddress.au3>
#include <GuiListBox.au3>
#include <Array.au3>

; #INDEX# =======================================================================================================================
; Title .........: Per-Monitor v2 Scaling UDF Library for AutoIt3
; AutoIt Version : 3.3.18.0
; Language ......: English
; Description ...: UDF library for applying Per-Monitor v2 scaling to GUI and controls
; Author(s) .....: WildByDesign (including code from ioa747, argumentum, UEZ and more)
; Version .......: 2026.10.19
; Link ..........: https://www.autoitscript.com/forum/topic/213823-automatic-per-monitor-v2-scaling-udf/
; ===============================================================================================================================

Global $__PM_g_Version = "2026.10.19"

; #CURRENT# =====================================================================================================================
; _PM_GetDefaultFont:	Obtain a DPI-scaled default GUI font that is equivalent to system font used by dialogs.
; _PM_GetMenuFont:		Obtain a DPI-scaled font for use with menu bars.
; _PM_Init:             Initializes the Per-Monitor V2 DPI awareness context for the process.
; _PM_PtToPx:			Converts font point size (pt) to cell pixel height (px) for Win32 API font creation.
; _PM_Scale:            Applies DPI scaling dynamically for GUI and Native and Win32 controls.
; _PM_Version:          Provides UDF version.
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
; __PM_CBTHookProc:		CBT Hook used to catch AutoIt v3 GUI at HCBT_CREATEWND stage.
; __PM_Cleanup			Releases all dynamically created GDI font handles from memory for ALL windows upon application exit.
; __PM_Free:			Releases GDI font handles and removes destroyed or specified GUI windows from the PM Map.
; __PM_GetNCMFont:		Internal helper function for _PM_GetMenuFont and _PM_GetDefaultFont.
; __PM_GetWindowDPI:    Retrieves the DPI for a given window handle with multi-OS fallback mechanisms.
; __PM_GetWindowRect:	A faster GetWindowRect function, particularly in busy loops.
; __PM_HookCleanup:		Clean up everything related to CBT Hook.
; __PM_InitCBTHook:		Initiate CBT Hook.
; __PM_ScaleToolbar:	Delete and restore toolbar buttons with same properties (needed for scaling buttons with BTNS_AUTOSIZE).
; __PM_WM_DPICHANGED:   Windows message handler for $WM_DPICHANGED (0x02E0) in Per-Monitor V2 DPI.
; __PM_WndProc:			Subclass procedure to handle WM_DPICHANGED and WM_NCCREATE (to set EnableNonClientDpiScaling on PMv1).
; ===============================================================================================================================

; #GLOBAL VARIABLES# ============================================================================================================
Global $__PM_mDPI[]
Global $__PM_g_hWndProc = 0, $__PM_g_pWndProc = 0, $__PM_g_hSubProc = 0, $__PM_g_hThreadID = 0, $__PM_g_hWH_CBT = 0
; ===============================================================================================================================

; #GLOBAL CONSTANTS# ============================================================================================================
Global Const $WM_DPICHANGED = 0x02E0
Global Const $WM_DPICHANGED_PRESCALE = $WM_APP + 20
Global Const $WM_DPICHANGED_POSTSCALE = $WM_APP + 21

Global Const $UDM_GETBUDDY = 1130

Global Const $DPI_AWARENESS_CONTEXT_UNAWARE = -1
Global Const $DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = -2
Global Const $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = -3
Global Const $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4
Global Const $DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED = -5
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: _PM_Init
; Description ...: Initializes the Per-Monitor V2 DPI awareness context for the process.
; Syntax.........: _PM_Init()
; Parameters ....: None
; Return values .: Success  - True
;                   Failure - False
; Author ........: ioa747
; Remarks .......: Automatically binds __PM_WM_DPICHANGED handler.
; Related .......: _PM_Scale, __PM_WM_DPICHANGED
; ===============================================================================================================================
Func _PM_Init()
	Opt("TrayAutoPause", 0) ; disabling TrayAutoPause prevents subclassing crashes

	; Prevent multiple initialization calls
	Local Static $bInitialized = False
	If $bInitialized Then Return True

	Local $bSuccess = False
	Local Const $PROCESS_PER_MONITOR_DPI_AWARE = 2
	Local $iDpiContext = 0

	; 1. Try PerMonitorV2 (-4) - Windows 10 (Build 1703+)
	Local $aRet = DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "int_ptr", $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
	If Not @error And $aRet[0] Then
		$bSuccess = True
		$iDpiContext = -4
	Else
		; 2. Try PerMonitorV1 (-3) via User32.dll - Windows 10 (Build 1607+)
		$aRet = DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "int_ptr", $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE)
		If Not @error And $aRet[0] Then
			$bSuccess = True
			$iDpiContext = -3
		Else
			; 3. Try PerMonitorV1 via SHCore.dll - Windows 8.1 (Normalized to -3)
			$aRet = DllCall("SHCore.dll", "long", "SetProcessDpiAwareness", "int", $PROCESS_PER_MONITOR_DPI_AWARE)
			If Not @error And $aRet[0] = 0 Then
				$bSuccess = True
				$iDpiContext = -3
			Else
				; 4. Fallback to SystemAware (-2) - Windows 10
				$aRet = DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "int_ptr", $DPI_AWARENESS_CONTEXT_SYSTEM_AWARE)
				If Not @error And $aRet[0] Then
					$bSuccess = True
					$iDpiContext = -2
				Else
					; 5. Legacy Fallback for Windows Vista / 7 / 8 (SystemAware)
					$aRet = DllCall("User32.dll", "bool", "SetProcessDPIAware")
					If Not @error And $aRet[0] Then
						$bSuccess = True
						$iDpiContext = -2
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	OnAutoItExitRegister("__PM_Cleanup")

	; Initiate CBT hook to handle WM_DPICHANGED scaling and WM_NCCREATE (to set EnableNonClientDpiScaling on PMv1)
	__PM_InitCBTHook()

	$bInitialized = True
	Return SetError(0, $iDpiContext, $bSuccess)
EndFunc   ;==>_PM_Init

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; Modified.......: ioa747
; Remarks........: Initial scaling should be applied with _PM_Scale($hWnd) prior to GUISetState in user script
;        ........: Subsequent calls to __PM_WM_DPICHANGED will send all parameters - Eg. _PM_Scale($hWnd, $iDPI, $tRect)
; ===============================================================================================================================
Func _PM_Scale($hWnd, $iDPI = "", $tRect = 0)
	Local Const $UDS_ALIGNLEFT = 0x0008
	; Check system availability of Segoe UI Variable font family
	Local Const $sFaceName = 'Segoe UI Variable Small'
	Local Static $sSegUIVar = _WinAPI_GetFontName($sFaceName)
	Local $bSegUIVar = True
	If Not $sSegUIVar Then $bSegUIVar = False

	Local $iCtrlID
	Local $bInitial = False

	If Not $iDPI Then
		$bInitial = True
		$iDPI = __PM_GetWindowDPI($hWnd)
		If @error Then $iDPI = 96
	EndIf

	Local $fNewDPI = $iDPI / 96

	Local $bPMv1 = False, $bPMv2 = False
	Local $hContext = _WinAPI_GetWindowDpiAwarenessContext($hWnd)
	If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2) Then $bPMv2 = True
	If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE) Then $bPMv1 = True

	Local $fPrevDPI, $aData, $aFontsOld[0]

	; Get previous DPI from map
	If MapExists($__PM_mDPI, $hWnd) Then
		; Window found in Map -> get $aData
		$aData = $__PM_mDPI[$hWnd]

		$fPrevDPI = $aData[0]
		$aFontsOld = $aData[1]
	Else
		; Window not found in Map -> AUTOMATIC FIRST TIME INITIALIZATION
		Dim $aData[3]
		; [0]=$fPrevDPI, [1]=$aFontsCur, [2]=...
		$aData[0] = 0   ; placeholder for $fPrevDPI
		$aData[1] = 0   ; placeholder for $aFontsCur
		$aData[2] = 0   ; placeholder for ...(for anything related to the current window)

		$fPrevDPI = 1
	EndIf

	Local $iMoveX, $iMoveY, $iMoveW, $iDiffW, $bCentered = False
	If Not IsDllStruct($tRect) Then
		$bInitial = True
		$tRect = DllStructCreate($tagRECT)
		$tRect = __PM_GetWindowRect($hWnd, $tRect)
		; Used to determine GUI position only after initial scaling
		$iMoveX = DllStructGetData($tRect, "Left")
		$iMoveY = DllStructGetData($tRect, "Top")
		; Used to determine if initial GUI was centered at startup
		$iMoveW = DllStructGetData($tRect, "Right") - DllStructGetData($tRect, "Left")
		$iDiffW = $iMoveX - (@DesktopWidth - $iMoveW - $iMoveX)
		If $iDiffW < 20 And $iDiffW > -20 And $iDiffW <> 0 Then $bCentered = True

		DllStructSetData($tRect, "Left", DllStructGetData($tRect, "Left") * $fNewDPI)
		DllStructSetData($tRect, "Top", DllStructGetData($tRect, "Top") * $fNewDPI)
		DllStructSetData($tRect, "Right", DllStructGetData($tRect, "Right") * $fNewDPI)
		DllStructSetData($tRect, "Bottom", DllStructGetData($tRect, "Bottom") * $fNewDPI)
	EndIf

	; Disable window drawing for smoother transition while window and all child controls are resized
	If Not $bInitial Then _SendMessage($hWnd, $WM_SETREDRAW, False)

	; Enumerate child windows and fill array with coordinates (before GUI gets resized) to resize controls AFTER GUI resize
	Local $aCtrls = _WinAPI_EnumChildWindows($hWnd, False)
	Local $hCtrl, $sClass, $aPos, $iX, $iY, $iW, $iH, $hCtrlFont, $hDC, $hChildEdit
	Local $hFontTest, $hSelectObject

	Local $tLOGFONT = DllStructCreate($tagLOGFONT)
	Local $iLogSize = DllStructGetSize($tLOGFONT)

	Local $aFontsCur[$aCtrls[0][0] + 1]
	Local $iFontCount = 0
	Local $tInputRect = DllStructCreate($tagRECT)
	Local $tUpDownRect = DllStructCreate($tagRECT)

	; Add some additional columns to the control array
	If IsArray($aCtrls) Then ReDim $aCtrls[UBound($aCtrls)][UBound($aCtrls, 2) + 6]
	; $aCtrls[$i][2] = $iX
	; $aCtrls[$i][3] = $iY
	; $aCtrls[$i][4] = $iW
	; $aCtrls[$i][5] = $iH
	; $aCtrls[$i][6] = $hCtrlFont
	; $aCtrls[$i][7] = $hBuddy

	Local $mControlMap[]

	If IsArray($aCtrls) Then
		; Map every control handle to its array row index
		For $i = 1 To $aCtrls[0][0]
			$mControlMap[$aCtrls[$i][0]] = $i
		Next

		; Initial run through array to find Edit/UpDown buddy pairs to measure together later
		For $i = 1 To $aCtrls[0][0]
			If $aCtrls[$i][1] = "msctls_updown32" Then
				Local $hBuddy = HWnd(_SendMessage($aCtrls[$i][0], $UDM_GETBUDDY))
				If MapExists($mControlMap, $hBuddy) Then
					$aCtrls[$mControlMap[$hBuddy]][7] = $aCtrls[$i][0]
				EndIf
			EndIf
		Next

		; Second run through array to collect control positions and create DPI-scaled fonts
		For $i = 1 To $aCtrls[0][0]
			$hCtrl = $aCtrls[$i][0]
			$sClass = $aCtrls[$i][1]

			If $bPMv1 Then
				; Lock down control resizing with GUICtrlSetResizing for PMv1 only
				If _IsNativeControl($hCtrl) Then
					$iCtrlID = _WinAPI_GetDlgCtrlID($hCtrl)
					GUICtrlSetResizing($iCtrlID, $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKWIDTH + $GUI_DOCKHEIGHT)
				EndIf
			EndIf

			; Skip child controls that belong to other controls (e.g., Edit inside ComboBox, SysHeader32 inside ListView)
			If _WinAPI_GetParent($hCtrl) <> $hWnd Then ContinueLoop

			; Skip statusbar control if context is PMv2 since OS will scale automatically
			If $sClass = "msctls_statusbar32" And $bPMv2 Then ContinueLoop
			If $sClass = "msctls_updown32" Then ContinueLoop

			; Get current position and size for control
			$aPos = ControlGetPos($hWnd, "", $hCtrl)
			$iX = $aPos[0]
			$iY = $aPos[1]
			$iW = $aPos[2]
			$iH = $aPos[3]

			; Determine DPI-scaled position and size for control
			$iX = _WinAPI_MulDiv(($iX / $fPrevDPI), $iDPI, 96)
			$iY = _WinAPI_MulDiv(($iY / $fPrevDPI), $iDPI, 96)
			$iW = _WinAPI_MulDiv(($iW / $fPrevDPI), $iDPI, 96)
			$iH = _WinAPI_MulDiv(($iH / $fPrevDPI), $iDPI, 96)

			; Determine ListBox height of ListBox that does NOT have LBS_NOINTEGRALHEIGHT
			If $sClass = 'ListBox' And Not $bInitial Then
				; need to determine number of visible items
				Local $iListHeight = _WinAPI_GetWindowHeight($hCtrl)
				Local $iItemHeight = _GUICtrlListBox_GetItemHeight($hCtrl)
				Local $iTargetItems = Floor($iListHeight / $iItemHeight)
				; Calculate new height for ListBox only if LBS_NOINTEGRALHEIGHT is not set
				Local $iItemHeightNew = _WinAPI_MulDiv(($iItemHeight / $fPrevDPI), $iDPI, 96)
				If Not BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $LBS_NOINTEGRALHEIGHT) Then
					; New height = (target items * new scaled item height) + half of new item height
					; This ensures ListBox is larger than iTargetItems (to snap down) but smaller than iTargetItems + 1
					$iH = ($iTargetItems * $iItemHeightNew) + ($iItemHeightNew / 2)
				EndIf
			EndIf

			; Edit control with UpDown buddy (initial width Edit width + UpDown width)
			If $sClass = 'Edit' And IsHWnd($aCtrls[$i][7]) Then
				; Get combined RECT width of UpDown and Edit buddy (overlapping, often by 2 pixels)
				Local $iBuddyPairWidth
				Local $hUpDown = $aCtrls[$i][7]
				$tInputRect = __PM_GetWindowRect($hCtrl, $tInputRect)
				$tUpDownRect = __PM_GetWindowRect($hUpDown, $tUpDownRect)
				Local $iUpDownStyle = _WinAPI_GetWindowLong($hUpDown, $GWL_STYLE)
				If BitAND($iUpDownStyle, $UDS_ALIGNLEFT) Then
					$iBuddyPairWidth = $tInputRect.right - $tUpDownRect.left
				Else
					$iBuddyPairWidth = $tUpDownRect.right - $tInputRect.left
				EndIf

				$iW = $iBuddyPairWidth
				$iW = _WinAPI_MulDiv(($iW / $fPrevDPI), $iDPI, 96)
			EndIf

			; Fill remainder of array with coordinates
			$aCtrls[$i][2] = $iX
			$aCtrls[$i][3] = $iY
			$aCtrls[$i][4] = $iW
			$aCtrls[$i][5] = $iH

			; Get the current font per control and select into DC to gather details
			$hDC = _WinAPI_GetDC($hCtrl)
			$hFontTest = _SendMessage($hCtrl, $WM_GETFONT)
			$hSelectObject = _WinAPI_SelectObject($hDC, $hFontTest)

			; Obtain LOGFONT structure to use directly with _WinAPI_CreateFontIndirect
			_WinAPI_GetObject($hFontTest, $iLogSize, DllStructGetPtr($tLOGFONT))

			If $sClass = 'SysIPAddress32' Then
				; SysIPAddress32 does not respond to WM_GETFONT - must get font from child Edit controls
				$hChildEdit = _WinAPI_GetWindow($hCtrl, $GW_CHILD)

				; Unselect previous font
				_WinAPI_SelectObject($hDC, $hSelectObject)
				_WinAPI_ReleaseDC($hCtrl, $hDC)

				; Get the current font per control and select into DC to gather details
				$hDC = _WinAPI_GetDC($hChildEdit)
				$hFontTest = _SendMessage($hChildEdit, $WM_GETFONT)
				$hSelectObject = _WinAPI_SelectObject($hDC, $hFontTest)

				; Obtain LOGFONT structure to use directly with _WinAPI_CreateFontIndirect
				_WinAPI_GetObject($hFontTest, $iLogSize, DllStructGetPtr($tLOGFONT))
			EndIf

			If $sClass = "msctls_statusbar32" And $bPMv1 Then ContinueLoop

			If $bInitial Then
				If $tLOGFONT.FaceName = "Segoe UI" Then $tLOGFONT.FaceName = $bSegUIVar ? $sSegUIVar : "Segoe UI"
				; If default font MS Shell Dlg is being used, switch to more modern font for improved scaling
				If $tLOGFONT.FaceName = "MS Shell Dlg" Then
					; Use Segoe UI Variable Small or Segoe UI depending on availability
					$tLOGFONT.FaceName = $bSegUIVar ? $sSegUIVar : "Segoe UI"
					If $tLOGFONT.Height = -13 Then $tLOGFONT.Height = -14 ; ensure unset font is equal to 8.5 pt
				EndIf
			Else
				; This is where the font scaling magic happens
				$tLOGFONT.Height = _WinAPI_MulDiv(($tLOGFONT.Height / $fPrevDPI), $iDPI, 96)
			EndIf

			; Create custom control font adjusted for new DPI factor
			$hCtrlFont = _WinAPI_CreateFontIndirect($tLOGFONT)

			; Add specific control font handle to main static array and secondary array to help with cleanup
			$aCtrls[$i][6] = $hCtrlFont
			$aFontsCur[$iFontCount] = $hCtrlFont
			$iFontCount += 1

			_WinAPI_SelectObject($hDC, $hSelectObject)
			_WinAPI_ReleaseDC($hCtrl, $hDC)
		Next
		; Save updated font handles back to global Map
		ReDim $aFontsCur[$iFontCount]
		$aData[1] = $aFontsCur ; add to placeholder
	EndIf

	; Resize GUI window to adjust to new DPI factor
	Local $iXP = $tRect.left, $iYP = $tRect.top, $iWP = $tRect.right - $iXP, $iHP = $tRect.bottom - $iYP
	_WinAPI_SetWindowPos($hWnd, 0, $iXP, $iYP, $iWP, $iHP, BitOR($SWP_NOZORDER, $SWP_NOACTIVATE))

	If $bInitial Then
		; On initial GUI launch, center if GUI was centered else use initial coordinates
		If $bCentered Then
			$aPos = WinGetPos($hWnd)
			WinMove($hWnd, "", (@DesktopWidth / 2 - ($aPos[2] / 2)), (@DesktopHeight / 2 - ($aPos[3] / 2)))
		Else
			WinMove($hWnd, "", $iMoveX, $iMoveY)
		EndIf
	EndIf

	Local $iFlags

	; Third run through array to resize controls and fonts to adjust to new DPI factor
	If IsArray($aCtrls) Then
		For $i = 1 To $aCtrls[0][0]
			$hCtrl = $aCtrls[$i][0]
			$sClass = $aCtrls[$i][1]
			$iX = $aCtrls[$i][2]
			$iY = $aCtrls[$i][3]
			$iW = $aCtrls[$i][4]
			$iH = $aCtrls[$i][5]
			$hCtrlFont = $aCtrls[$i][6]

			; Skip handling of UpDown control here because the OS will manage the size and position (PMv2)
			If $sClass = "msctls_updown32" Then ContinueLoop

			; Skip child controls that belong to other controls (e.g., Edit inside ComboBox, SysHeader32 inside ListView)
			If _WinAPI_GetParent($hCtrl) <> $hWnd Then ContinueLoop

			$iFlags = BitOR($SWP_NOZORDER, $SWP_NOACTIVATE)

			Switch $sClass
				Case 'Edit', 'ListBox', 'SysListView32', 'SysTreeView32', 'ComboBox'
					; These have may have custom borders and require WM_NCCALCSIZE via SWP_FRAMECHANGED
					$iFlags = BitOR($iFlags, $SWP_FRAMECHANGED)
			EndSwitch

			Switch _IsNativeControl($hCtrl)
				Case True
					$iCtrlID = _WinAPI_GetDlgCtrlID($hCtrl)
					_SendMessage($hCtrl, $WM_SETFONT, $hCtrlFont, True)
					If $sClass = 'SysMonthCal32' Then
						$iW = _GUICtrlMonthCal_GetMinReqWidth($hCtrl)
						$iH = _GUICtrlMonthCal_GetMinReqHeight($hCtrl)
					EndIf
					; Set scaled font and scale control size/position for native AutoIt control
					GUICtrlSetPos($iCtrlID, $iX, $iY, $iW, $iH)
					$iFlags = BitOR($iFlags, $SWP_NOMOVE, $SWP_NOSIZE)
					_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, $iFlags)
				Case False
					Switch $sClass
						Case 'SysIPAddress32'
							; SysIPAddress32 cannot be resized - must be destroyed and created again
							Local $sIpAddr = _GUICtrlIpAddress_Get($hCtrl)
							_GUICtrlIpAddress_Destroy($hCtrl)
							$hCtrl = _GUICtrlIpAddress_Create($hWnd, $iX, $iY, $iW, $iH)
							_GUICtrlIpAddress_Set($hCtrl, $sIpAddr)
							_SendMessage($hCtrl, $WM_SETFONT, $hCtrlFont, True)
							ContinueLoop

						Case 'ToolbarWindow32'
							If $bInitial Then ContinueLoop
							Local $aSize = _GUICtrlToolbar_GetButtonSize($hCtrl)
							If Not $bPMv2 Then _SendMessage($hCtrl, $WM_SETFONT, $hCtrlFont, True)
							_GUICtrlToolbar_SetButtonSize($hCtrl, _WinAPI_MulDiv(($aSize[0] / $fPrevDPI), $iDPI, 96), _WinAPI_MulDiv(($aSize[1] / $fPrevDPI), $iDPI, 96))
							_SendMessage($hCtrl, $TB_AUTOSIZE)
							ContinueLoop

						Case 'SysMonthCal32'
							$iW = _GUICtrlMonthCal_GetMinReqWidth($hCtrl)
							$iH = _GUICtrlMonthCal_GetMinReqHeight($hCtrl)

						Case 'msctls_statusbar32'
							If $bPMv1 Then ContinueLoop
					EndSwitch

					; Set scaled font and scale control size/position for UDF-created control
					_SendMessage($hCtrl, $WM_SETFONT, $hCtrlFont, True)
					_WinAPI_SetWindowPos($hCtrl, 0, $iX, $iY, $iW, $iH, $iFlags)
			EndSwitch
		Next
	EndIf

	$aData[0] = $fNewDPI ; add to placeholder for $fPrevDPI
	$__PM_mDPI[$hWnd] = $aData ; add $aData back to map

	; Custom window message allows any needed changes after scaling
	;_SendMessage($hWnd, $WM_DPICHANGED_POSTSCALE, $iDPI)
	;_WinAPI_PostMessage($hWnd, $WM_DPICHANGED_POSTSCALE, $iDPI, 0)

	; Enable drawing in window again since everything has been resized
	If Not $bInitial Then _SendMessage($hWnd, $WM_SETREDRAW, True)

	; Final run through array after window drawing is enabled again to fix some control visual glitches
	Local Const $EM_SETSEL = 0xB1
	If IsArray($aCtrls) Then
		For $i = 1 To $aCtrls[0][0]
			$hCtrl = $aCtrls[$i][0]
			$sClass = $aCtrls[$i][1]

			Switch $sClass
				Case 'ToolbarWindow32'
					; Toolbar button text measurements often stay cached internally and recreating the buttons is best
					__PM_ScaleToolbar($hCtrl, $fPrevDPI, $iDPI)

				Case 'Edit'
					; This clears the blue selection highlight that reappears after each DPI change
					If _WinAPI_GetClassName(_WinAPI_GetParent($hCtrl)) = 'ComboBox' Then _SendMessage($hCtrl, $EM_SETSEL, 0, 0)
			EndSwitch
		Next
	EndIf

	; Trigger window redraw and non-client area frame change
	;_WinAPI_RedrawWindow($hWnd)
	_WinAPI_RedrawWindow($hWnd, 0, 0, BitOR($RDW_INVALIDATE, $RDW_ALLCHILDREN))
	_WinAPI_SetWindowPos($hWnd, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

	; _WinAPI_SetActiveWindow($hWnd)
	If $bInitial Then _WinAPI_SetActiveWindow($hWnd)

	; Delete previous font resources after all changes
	For $i = 0 To UBound($aFontsOld) - 1
		_WinAPI_DeleteObject($aFontsOld[$i])
	Next
	;_ArrayDisplay($aCtrls)
EndFunc   ;==>_PM_Scale

; #FUNCTION# ====================================================================================================================
; Name ..........: _PM_Version
; Description ...: Provides UDF version.
; Author.........: argumentum
; ===============================================================================================================================
Func _PM_Version()
	Return $__PM_g_Version
EndFunc   ;==>_PM_Version

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_GetWindowDPI
; Description ...: Retrieves the DPI for a given window handle with multi-OS fallback mechanisms.
; Syntax ........: __PM_GetWindowDPI($hWnd)
; Parameters ....: $hWnd    - [Optional] Handle to the window. Default is the desktop window.
; Return values .: Success  - Integer DPI value (e.g. 96, 120, 144, 192).
;                   Failure - Returns 96 (Standard 100% DPI) as safe fallback.
; Author ........: ioa747
; Modified ......:
; Remarks .......: Uses native User32 GetDpiForWindow on Win10 1607+, falling back to GetDpiForSystem or Device Context.
; Related .......: _PM_Init
; Link ..........:
; Example .......: Local $iDpi = __PM_GetWindowDPI($hGUI)
; ===============================================================================================================================
Func __PM_GetWindowDPI($hWnd = 0)
	If Not IsHWnd($hWnd) Or $hWnd = 0 Then $hWnd = _WinAPI_GetDesktopWindow()

	; Primary Method: Native GetDpiForWindow (Win10 1607+ / Win11)
	Local $aRet = DllCall("User32.dll", "uint", "GetDpiForWindow", "hwnd", $hWnd)
	If Not @error And $aRet[0] > 0 Then Return $aRet[0]

	; Fallback Method 1: GetDpiForSystem (Win10 1607+)
	$aRet = DllCall("User32.dll", "uint", "GetDpiForSystem")
	If Not @error And $aRet[0] > 0 Then Return $aRet[0]

	; Fallback Method 2: Legacy Device Context (Win7 / Win8 / Win8.1)
	Local $hDC = _WinAPI_GetDC($hWnd)
	If $hDC Then
		Local $iDPI = _WinAPI_GetDeviceCaps($hDC, 88) ; 88 = LOGPIXELSX
		_WinAPI_ReleaseDC($hWnd, $hDC)
		If $iDPI > 0 Then Return $iDPI
	EndIf

	; Default fallback
	Return 96
EndFunc   ;==>__PM_GetWindowDPI

; #FUNCTION# =========================================================================================================
; Name ..........: __PM_Cleanup
; Description ...: Releases all dynamically created GDI font handles from memory for ALL windows upon application exit.
; Syntax ........: __PM_Cleanup()
; Parameters ....: None
; Return values .: Always returns True.
; Author ........: ioa747
; Remarks .......: Registered automatically via OnAutoItExitRegister inside _PM_Init.
; Related .......: _PM_Init, __PM_Free
; ====================================================================================================================
Func __PM_Cleanup()
	Local $aKeys = MapKeys($__PM_mDPI)
	If @error Or Not IsArray($aKeys) Then Return True

	Local $hWnd

	; Iterate through all registered GUI windows in the global Map
	For $i = 0 To UBound($aKeys) - 1
		$hWnd = $aKeys[$i]
		__PM_Free($hWnd)
	Next

	Return True
EndFunc   ;==>__PM_Cleanup

; #FUNCTION# =========================================================================================================
; Name ..........: __PM_Free
; Description ...: Releases GDI font handles and removes destroyed or specified GUI windows from the PM Map.
; Syntax ........: __PM_Free([$hWnd = 0])
; Parameters ....: $hWnd    - [Optional] Specific window handle to free. If 0 or omitted, cleans all destroyed windows.
; Return values .: Success  - True
;                   Failure - False (Sets @error: 1 = Specified HWND not found in Map)
; Author ........: ioa747
; Modified ......: WildByDesign
; Remarks .......: When called with 0, checks WinExists() for all stored handles and purges dead windows dynamically.
; Related .......: _PM_Scale, __PM_Cleanup
; Example .......: __PM_Free($hGUI) ; Free specific window
;                  __PM_Free()      ; Auto-garbage collect all closed windows
; ====================================================================================================================
Func __PM_Free($hWnd = 0)
	Local $aKeys = MapKeys($__PM_mDPI)
	If @error Or Not IsArray($aKeys) Then Return True

	Local $hTargetWnd, $aData, $aFontsOld, $hFont

	; === CASE 1: AUTO GARBAGE COLLECTION FOR ALL DESTROYED WINDOWS ===
	If $hWnd = 0 Then
		For $i = 0 To UBound($aKeys) - 1
			$hTargetWnd = $aKeys[$i]
			If Not IsHWnd($hTargetWnd) Then ContinueLoop
			If Not WinExists(HWnd($hTargetWnd)) Then
				$aData = $__PM_mDPI[$hTargetWnd]
				$aFontsOld = $aData[1]
				If IsArray($aFontsOld) Then
					For $j = 0 To UBound($aFontsOld) - 1
						$hFont = $aFontsOld[$j]
						If $hFont Then _WinAPI_DeleteObject($hFont)
					Next
				EndIf
				MapRemove($__PM_mDPI, $hTargetWnd)
			EndIf
		Next
		Return True
	EndIf

	; === CASE 2: SPECIFIC WINDOW PURGE ===
	If Not MapExists($__PM_mDPI, $hWnd) Then Return SetError(1, 0, False)
	$aData = $__PM_mDPI[$hWnd]
	$aFontsOld = $aData[1]
	If IsArray($aFontsOld) Then
		For $i = 0 To UBound($aFontsOld) - 1
			$hFont = $aFontsOld[$i]
			If $hFont Then
				_WinAPI_DeleteObject($hFont)
				$aFontsOld[$i] = 0
			EndIf
		Next
	EndIf

	MapRemove($__PM_mDPI, $hWnd)
	Return True
EndFunc   ;==>__PM_Free

; #FUNCTION# ====================================================================================================================
; Name ..........: _GetDpiAwarenessContextName
; Description ...: Helper Function to Convert Any Handle to a Friendly String.
; Author.........: argumentum
; ===============================================================================================================================
Func _GetDpiAwarenessContextName($hContext)
	If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2) Then Return "Per-Monitor Aware V2"
	If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE) Then Return "Per-Monitor Aware V1"
	If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_SYSTEM_AWARE) Then Return "System Aware"
	If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_UNAWARE) Then Return "Unaware"
	If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED) Then Return "Unaware (GDI Scaled)"
	Return "Unknown Context"
EndFunc   ;==>_GetDpiAwarenessContextName

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_InitCBTHook
; Description ...: Initiate CBT Hook.
; Author.........: WildByDesign
; ===============================================================================================================================
Func __PM_InitCBTHook()
	If Not $__PM_g_hWndProc Then $__PM_g_hWndProc = DllCallbackRegister(__PM_WndProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
	If Not $__PM_g_pWndProc Then $__PM_g_pWndProc = DllCallbackGetPtr($__PM_g_hWndProc)
	If Not $__PM_g_hSubProc Then $__PM_g_hSubProc = DllCallbackRegister(__PM_CBTHookProc, "int", "uint;wparam;lparam")
	If Not $__PM_g_hThreadID Then $__PM_g_hThreadID = _WinAPI_GetCurrentThreadId()
	If Not $__PM_g_hWH_CBT Then $__PM_g_hWH_CBT = _WinAPI_SetWindowsHookEx($WH_CBT, DllCallbackGetPtr($__PM_g_hSubProc), Null, $__PM_g_hThreadID)
	OnAutoItExitRegister("__PM_HookCleanup")
EndFunc   ;==>__PM_InitCBTHook

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_HookCleanup
; Description ...: Clean up everything related to CBT Hook.
; Author.........: WildByDesign
; ===============================================================================================================================
Func __PM_HookCleanup()
	; Enumerate all AutoIt v3 GUI windows under current PID and GUIDelete on exit
	; Needed in case user forgets to use GUIDelete() which can cause subclassing crashes
	Local $aData = _WinAPI_EnumProcessWindows(@AutoItPID, False)
	For $i = 1 To $aData[0][0]
		If $aData[$i][1] = "AutoIt v3 GUI" Then GUIDelete($aData[$i][0])
	Next

	If $__PM_g_hWndProc Then DllCallbackFree($__PM_g_hWndProc)
	If $__PM_g_hWH_CBT Then _WinAPI_UnhookWindowsHookEx($__PM_g_hWH_CBT)
	If $__PM_g_hSubProc Then DllCallbackFree($__PM_g_hSubProc)
EndFunc   ;==>__PM_HookCleanup

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_CBTHookProc
; Description ...: CBT Hook used to catch AutoIt v3 GUI at HCBT_CREATEWND stage.
; Author.........: UEZ
; Modified.......: WildByDesign, MattyD
; ===============================================================================================================================
Func __PM_CBTHookProc($nCode, $wParam, $lParam)
	Local Const $HCBT_CREATEWND = 3
	Local Const $hWnd = HWnd($wParam)
	If $nCode < 0 Then Return _WinAPI_CallNextHookEx($__PM_g_hWH_CBT, $nCode, $wParam, $lParam)
	Switch $nCode
		Case $HCBT_CREATEWND
			Switch _WinAPI_GetClassName($hWnd)
				Case "AutoIt v3 GUI"
					; Subclass GUI window
					_WinAPI_SetWindowSubclass($hWnd, $__PM_g_pWndProc, $hWnd)
			EndSwitch
	EndSwitch
	Return _WinAPI_CallNextHookEx($__PM_g_hWH_CBT, $nCode, $wParam, $lParam)
EndFunc   ;==>__PM_CBTHookProc

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_WndProc
; Description ...: Windows message handler for $WM_DPICHANGED and $WM_NCCREATE.
; Author ........: WildByDesign
; ===============================================================================================================================
Func __PM_WndProc($hWnd, $iMsg, $wParam, $lParam, $iSubClsID, $pData)
	#forceref $pData, $iSubClsID

	Switch $iMsg
		Case $WM_NCCREATE
			Local $bPMv1 = False
			Local $hContext = _WinAPI_GetThreadDpiAwarenessContext()
			If _WinAPI_AreDpiAwarenessContextsEqual($hContext, $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE) Then $bPMv1 = True

			; Set EnableNonClientDpiScaling for non-client scaling on Win10 1607+ when using PMv1
			If $bPMv1 And @OSBuild >= 14393 Then
				DllCall("user32.dll", "bool", "EnableNonClientDpiScaling", "hwnd", $hWnd)
			EndIf

			Return __PM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_DPICHANGED
			; Obtain new DPI value (raw)
			Local $iDPI = _WinAPI_LoWord($wParam)

			; Custom window message allows any needed changes before scaling
			_SendMessage($hWnd, $WM_DPICHANGED_PRESCALE, $wParam, $lParam)

			_PM_Scale($hWnd, $iDPI, DllStructCreate($tagRECT, $lParam))

			; Custom window message allows any needed changes after scaling
			_WinAPI_PostMessage($hWnd, $WM_DPICHANGED_POSTSCALE, $iDPI, 0)

			Local $iRet = __PM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If $iMsg = $WM_DPICHANGED Then Return 0
			Return $iRet

		Case $WM_DPICHANGED_POSTSCALE
			__PM_Free() ; Auto-garbage collect obsolete/destroyed windows from $__PM_mDPI

		Case $WM_DESTROY
			_WinAPI_RemoveWindowSubclass($hWnd, $__PM_g_pWndProc, $iSubClsID)
			Return __PM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

	EndSwitch

	Return __PM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__PM_WndProc

; #FUNCTION# ====================================================================================================================
; Name ..........: _IsNativeControl
; Description ...: Helper function to determine if control is native AutoIt control or UDF-created control.
; Author.........: ioa747
; ===============================================================================================================================
Func _IsNativeControl($hCtrl)
	Local $iCtrlID = _WinAPI_GetDlgCtrlID($hCtrl)
	If @error Or $iCtrlID <= 0 Then Return False
	Return (GUICtrlGetHandle($iCtrlID) = $hCtrl)
EndFunc   ;==>_IsNativeControl

; #FUNCTION# ====================================================================================================================
; Name ..........: _PM_PtToPx
; Description ...: Converts font point size (pt) to cell pixel height (px) for Win32 API font creation.
; Syntax ........: _PM_PtToPx($fPoints[, $hWnd = 0])
; Parameters ....: $fPoints - Font size in points (e.g. 9, 11, 14).
;                  $hWnd    - [Optional] Handle to target GUI window to determine current DPI.
; Return values .: Returns negative integer height ready for _WinAPI_CreateFont (e.g. -15 for 11pt @ 100% DPI).
; Author ........: ioa747
; Remarks .......: Uses __PM_GetWindowDPI internally to calculate exact pixel dimensions.
; Related .......: __PM_GetWindowDPI, _PM_Scale
; Example .......: Local $hFont = _WinAPI_CreateFont(_PM_PtToPx(11, $hGUI), 0, 0, 0, $FW_NORMAL, ...)
; ===============================================================================================================================
Func _PM_PtToPx($fPoints, $hWnd = 0)
	Local $iDPI = __PM_GetWindowDPI($hWnd)
	Return -Round(($fPoints * $iDPI) / 72)
EndFunc   ;==>_PM_PtToPx

; #FUNCTION# ====================================================================================================================
; Name ..........: _PM_GetMenuFont
; Description ...: Creates a DPI-scaled font that is identical to the system menu font used for menu bars.
; Author ........: WildByDesign
; ===============================================================================================================================
Func _PM_GetMenuFont($iDPI)
	Local $hFont = __PM_GetNCMFont("lfMenuFont", $iDPI)
	Return $hFont
EndFunc   ;==>_PM_GetMenuFont

; #FUNCTION# ====================================================================================================================
; Name ..........: _PM_GetDefaultFont
; Description ...: Creates a DPI-scaled font that is identical to the default system font used for dialogs.
; Author ........: WildByDesign
; ===============================================================================================================================
Func _PM_GetDefaultFont($iDPI)
	Local $hFont = __PM_GetNCMFont("lfMessageFont", $iDPI)
	Return $hFont
EndFunc   ;==>_PM_GetDefaultFont

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_GetNCMFont
; Description ...: Internal helper function for _PM_GetMenuFont and _PM_GetDefaultFont.
; Author ........: WildByDesign
; ===============================================================================================================================
Func __PM_GetNCMFont($sFontNCM, $iDPI)
	Local Const $SPI_GETNONCLIENTMETRICS = 0x0029

	Local $tNCM = DllStructCreate("uint cbSize;int iBorderWidth;int iScrollWidth;int iScrollHeight;" & _
			"int iCaptionWidth;int iCaptionHeight;byte lfCaptionFont[92];" & _
			"int iSmCaptionWidth;int iSmCaptionHeight;byte lfSmCaptionFont[92];" & _
			"int iMenuWidth;int iMenuHeight;byte lfMenuFont[92];" & _
			"byte lfStatusFont[92];byte lfMessageFont[92];int iPaddedBorderWidth")

	DllStructSetData($tNCM, "cbSize", DllStructGetSize($tNCM))

	Local $aResult = DllCall("user32.dll", "bool", "SystemParametersInfoForDpi", _
			"uint", $SPI_GETNONCLIENTMETRICS, _
			"uint", DllStructGetSize($tNCM), _
			"ptr", DllStructGetPtr($tNCM), _
			"uint", 0, _
			"uint", $iDPI)

	If @error Or Not $aResult[0] Then
		$aResult = DllCall("user32.dll", "bool", "SystemParametersInfo", _
				"uint", $SPI_GETNONCLIENTMETRICS, _
				"uint", DllStructGetSize($tNCM), _
				"ptr", DllStructGetPtr($tNCM), _
				"uint", 0)
	EndIf

	; Obtain LOGFONT structure for default dialog font
	Local $tLOGFONT = DllStructCreate("long lfHeight;long lfWidth;long lfEscapement;long lfOrientation;" & _
			"long lfWeight;byte lfItalic;byte lfUnderline;byte lfStrikeOut;byte lfCharSet;" & _
			"byte lfOutPrecision;byte lfClipPrecision;byte lfQuality;byte lfPitchAndFamily;" & _
			"wchar lfFaceName[32]", DllStructGetPtr($tNCM, $sFontNCM))

	; Obtain font handle for default font
	Local $hFont = _WinAPI_CreateFontIndirect($tLOGFONT)

	Return $hFont
EndFunc   ;==>__PM_GetNCMFont

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_WinAPI_DefSubclassProc
; Description ...: This fixed version of the _WinAPI_DefSubclassProc function prevents some subclassing crashes.
; Author.........: jugador
; ===============================================================================================================================
Func __PM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
	Return DllCall('comctl32.dll', 'lresult', 'DefSubclassProc', 'hwnd', $hWnd, 'uint', $iMsg, 'wparam', $wParam, _
			'lparam', $lParam)[0]
EndFunc   ;==>__PM_WinAPI_DefSubclassProc

; #FUNCTION# ====================================================================================================================
; Name ..........: _WinAPI_AreDpiAwarenessContextsEqual
; Description ...: Determines whether two DPI_AWARENESS_CONTEXT values are identical.
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_AreDpiAwarenessContextsEqual($iContextA, $iContextB)
	Local $aResult = DllCall("user32.dll", "bool", "AreDpiAwarenessContextsEqual", "int_ptr", $iContextA, "int_ptr", $iContextB)
	If @error Or Not IsArray($aResult) Then Return SetError(1, @error, False)
	Return ($aResult[0] <> 0)
EndFunc   ;==>_WinAPI_AreDpiAwarenessContextsEqual

; #FUNCTION# ====================================================================================================================
; Name ..........: _WinAPI_GetWindowDpiAwarenessContext
; Description ...: Returns the DPI_AWARENESS_CONTEXT associated with a window.
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_GetWindowDpiAwarenessContext($hWnd)
	Local $aResult = DllCall("user32.dll", "int_ptr", "GetWindowDpiAwarenessContext", "hwnd", $hWnd)
	If @error Or Not IsArray($aResult) Then Return SetError(1, @error, 0)
	If Not $aResult[0] Then Return SetError(2, 0, 0)
	Return $aResult[0]
EndFunc   ;==>_WinAPI_GetWindowDpiAwarenessContext

; #FUNCTION# ====================================================================================================================
; Name ..........: _WinAPI_GetThreadDpiAwarenessContext
; Description ...: Gets the DPI_AWARENESS_CONTEXT for the current thread.
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_GetThreadDpiAwarenessContext()
	Local $aResult = DllCall("user32.dll", "int_ptr", "GetThreadDpiAwarenessContext")
	If @error Or Not IsArray($aResult) Then Return SetError(1, @error, 0)
	If Not $aResult[0] Then Return SetError(2, 0, 0)
	Return $aResult[0]
EndFunc   ;==>_WinAPI_GetThreadDpiAwarenessContext

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_ScaleToolbar
; Description ...: Delete and restore toolbar buttons with same properties (needed for scaling buttons with BTNS_AUTOSIZE).
; Author.........: WildByDesign
; ===============================================================================================================================
Func __PM_ScaleToolbar($hToolbar, $fPrevDPI, $iDPI)
	Local $iCmdID, $iState, $iStyle, $iParam, $iImage, $iString
	Local $iCount = _GUICtrlToolbar_ButtonCount($hToolbar)
	If $iCount <= 0 Then Return

	Local $aToolBtns[$iCount][6]

	Local $tButton = DllStructCreate($tagTBBUTTON)
	Local $pButton = DllStructGetPtr($tButton)

	For $i = 0 To $iCount - 1
		_SendMessage($hToolbar, $TB_GETBUTTON, $i, $pButton)
		$iStyle = DllStructGetData($tButton, "Style")
		$iState = DllStructGetData($tButton, "State")
		$iParam = DllStructGetData($tButton, "Param")
		$iImage = DllStructGetData($tButton, "Bitmap")
		$iString = DllStructGetData($tButton, "String")
		$iCmdID = DllStructGetData($tButton, "Command")

		; Fill array with all details to restore later
		$aToolBtns[$i][0] = $iCmdID
		$aToolBtns[$i][1] = $iStyle
		$aToolBtns[$i][2] = $iState
		$aToolBtns[$i][3] = $iImage
		$aToolBtns[$i][4] = $iParam
		$aToolBtns[$i][5] = $iString
	Next

	; Delete all buttons and separators
	For $i = UBound($aToolBtns) - 1 To 0 Step -1
		_SendMessage($hToolbar, $TB_DELETEBUTTON, $i)
	Next

	; Add all buttons and separators with previous styles, states, etc.
	For $i = 0 To UBound($aToolBtns) - 1
		$iCmdID = $aToolBtns[$i][0]
		$iStyle = $aToolBtns[$i][1]
		$iState = $aToolBtns[$i][2]
		$iImage = $aToolBtns[$i][3]
		$iParam = $aToolBtns[$i][4]
		$iString = $aToolBtns[$i][5]

		If BitAND($iStyle, $BTNS_SEP) Then
			; Scale separator width
			$iImage = _WinAPI_MulDiv(($iImage / $fPrevDPI), $iDPI, 96)
		EndIf
		_GUICtrlToolbar_AddButton($hToolbar, $iCmdID, $iImage, $iString, $iStyle, $iState, $iParam)
	Next

	; Get button padding and spacing metrics
	Local $aMetrics = _GUICtrlToolbar_GetMetrics($hToolbar)
	If IsArray($aMetrics) Then
		Local $iPadW = $aMetrics[0]
		Local $iPadH = $aMetrics[1]
		Local $iSpaceW = $aMetrics[2]
		Local $iSpaceH = $aMetrics[3]

		; Scale metrics
		$iPadW = _WinAPI_MulDiv(($iPadW / $fPrevDPI), $iDPI, 96)
		$iPadH = _WinAPI_MulDiv(($iPadH / $fPrevDPI), $iDPI, 96)
		$iSpaceW = _WinAPI_MulDiv(($iSpaceW / $fPrevDPI), $iDPI, 96)
		$iSpaceH = _WinAPI_MulDiv(($iSpaceH / $fPrevDPI), $iDPI, 96)

		; Set scaled metrics
		_GUICtrlToolbar_SetMetrics($hToolbar, $iPadW, $iPadH, $iSpaceW, $iSpaceH)
	EndIf
	;_ArrayDisplay($aToolBtns, "Toolbar Buttons", Default, 0, Default, "CmdID|Style|State|Bitmap|Param|String")
EndFunc   ;==>__PM_ScaleToolbar

; #FUNCTION# ====================================================================================================================
; Name ..........: __PM_GetWindowRect
; Description ...: A faster GetWindowRect function, particularly in busy loops.
; Author.........: WildByDesign
; ===============================================================================================================================
Func __PM_GetWindowRect($hWnd, $tRect)
	Local $aCall = DllCall("user32.dll", "bool", "GetWindowRect", "hwnd", $hWnd, "struct*", $tRect)
	If @error Or Not $aCall[0] Then Return SetError(@error + 10, @extended, 0)
	Return $tRect
EndFunc   ;==>__PM_GetWindowRect
