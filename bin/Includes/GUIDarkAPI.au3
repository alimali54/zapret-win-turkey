#include-once

; #INDEX# =======================================================================================================================
; Title .........: GUIDarkAPI UDF Library for AutoIt3
; AutoIt Version : 3.3.18.0
; Language ......: English
; Description ...: API support library for GUIDarkTheme UDF
; Author ........: WildByDesign (all Dark Mode functions by UEZ)
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _WinAPI_AllowDarkModeForApp
; _WinAPI_AllowDarkModeForWindow
; _WinAPI_FlushMenuThemes
; _WinAPI_GetIsImmersiveColorUsingHighContrast
; _WinAPI_IsDarkModeAllowedForApp
; _WinAPI_IsDarkModeAllowedForWindow
; _WinAPI_OpenNcThemeData
; _WinAPI_RefreshImmersiveColorPolicyState
; _WinAPI_SetPreferredAppMode
; _WinAPI_ShouldAppsUseDarkMode
; _WinAPI_ShouldSystemUseDarkMode
; ===============================================================================================================================

; #GLOBAL CONSTANTS# ============================================================================================================
Global Const $APPMODE_DEFAULT = 0
Global Const $APPMODE_ALLOWDARK = 1
Global Const $APPMODE_FORCEDARK = 2
Global Const $APPMODE_FORCELIGHT = 3
Global Const $APPMODE_MAX = 4

Global Const $IHCM_USE_CACHED_VALUE = 0
Global Const $IHCM_REFRESH = 1
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_ShouldAppsUseDarkMode()
	Local $aResult = DllCall("UxTheme.dll", "bool", 132)
	If @error Then Return SetError(1, 0, False)
	Return ($aResult[0] <> 0)
EndFunc   ;==>_WinAPI_ShouldAppsUseDarkMode

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_AllowDarkModeForWindow($hWND, $bAllow = True)
	Local $aResult = DllCall("UxTheme.dll", "bool", 133, "hwnd", $hWND, "bool", $bAllow)
	If @error Then Return SetError(1, 0, False)
	Return ($aResult[0] <> 0)
EndFunc   ;==>_WinAPI_AllowDarkModeForWindow

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_FlushMenuThemes()
	DllCall("UxTheme.dll", "none", 136)
	If @error Then Return SetError(1, 0, False)
	Return True
EndFunc   ;==>_WinAPI_FlushMenuThemes

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_RefreshImmersiveColorPolicyState()
	DllCall("UxTheme.dll", "none", 104)
	If @error Then Return SetError(1, 0, False)
	Return True
EndFunc   ;==>_WinAPI_RefreshImmersiveColorPolicyState

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_IsDarkModeAllowedForWindow($hWND)
	Local $aResult = DllCall("UxTheme.dll", "bool", 137, "hwnd", $hWND)
	If @error Then Return SetError(1, 0, False)
	Return ($aResult[0] <> 0)
EndFunc   ;==>_WinAPI_IsDarkModeAllowedForWindow

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_GetIsImmersiveColorUsingHighContrast($iIMMERSIVE_HC_CACHE_MODE)
	Local $aResult = DllCall("UxTheme.dll", "bool", 106, "long", $iIMMERSIVE_HC_CACHE_MODE)
	If @error Then Return SetError(1, 0, False)
	Return ($aResult[0] <> 0)
EndFunc   ;==>_WinAPI_GetIsImmersiveColorUsingHighContrast

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_OpenNcThemeData($hWND, $tClassList)
	Local $aResult = DllCall("UxTheme.dll", "hwnd", 49, "hwnd", $hWND, "struct*", $tClassList)
	If @error Then Return SetError(1, 0, False)
	Return $aResult[0]
EndFunc   ;==>_WinAPI_OpenNcThemeData

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_ShouldSystemUseDarkMode()
	Local $aResult = DllCall("UxTheme.dll", "bool", 138)
	If @error Then Return SetError(1, 0, False)
	Return ($aResult[0] <> 0)
EndFunc   ;==>_WinAPI_ShouldSystemUseDarkMode

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_IsDarkModeAllowedForApp()
	Local $aResult = DllCall("UxTheme.dll", "bool", 139)
	If @error Then Return SetError(1, 0, False)
	Return ($aResult[0] <> 0)
EndFunc   ;==>_WinAPI_IsDarkModeAllowedForApp

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_AllowDarkModeForApp($bAllow = True) ;Windows 10 Build 17763
	Return _WinAPI_SetPreferredAppMode($bAllow ? 1 : 0) ; 1 = AllowDark, 0 = Default
EndFunc   ;==>_WinAPI_AllowDarkModeForApp

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_SetPreferredAppMode($iPreferredAppMode) ;Windows 10 Build 18362+
	Local $aResult = DllCall("UxTheme.dll", "long", 135, "long", $iPreferredAppMode)
	If @error Then Return SetError(1, 0, False)
	Return $aResult[0]
EndFunc   ;==>_WinAPI_SetPreferredAppMode
