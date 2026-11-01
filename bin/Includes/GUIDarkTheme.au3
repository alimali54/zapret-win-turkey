#include-once
#include "GUIDarkTheme.includes.au3"
#include "PMv2.au3"

; #INDEX# =======================================================================================================================
; Title .........: GUIDarkTheme UDF Library for AutoIt3
; AutoIt Version : 3.3.18.0
; Language ......: English
; Description ...: UDF library for applying dark theme to win32 controls
; Author(s) .....: WildByDesign (including code from NoNameCode, argumentum, UEZ, pixelsearch, ahmet, MattyD, ioa747, Nine and more)
; Version .......: 2026.10.26
; Link ..........: https://www.autoitscript.com/forum/topic/213613-guidarktheme-udf/
; Notes .........: This UDF is not compatible with WS_EX_COMPOSITED extended style
; ...............: Window messages used for controls:	WM_CTLCOLOR*, WM_NOTIFY, WM_SETTINGCHANGE, WM_PARENTNOTIFY, WM_SETCURSOR
; ...............: Window messages used for menubar:	WM_DRAWITEM, WM_NCACTIVATE, WM_MEASUREITEM, WM_WINDOWPOSCHANGED
; ...............: TrayAutoPause is disabled to prevent subclassing crashes
; ===============================================================================================================================

Global $__DM_g_Version = "2026.10.26"
Global $darkmode
Global $osbuild

; #CURRENT# =====================================================================================================================
; _GUIDarkMenu_Register
; _GUIDarkMenu_SetColors
; _GUIDarkTheme_AccentColorSet
; _GUIDarkTheme_ApplyAuto
; _GUIDarkTheme_ApplyDark
; _GUIDarkTheme_ApplyLight
; _GUIDarkTheme_AutoTheme
; _GUIDarkTheme_CtrlBorderSet
; _GUIDarkTheme_GUICtrlAllSetDarkTheme
; _GUIDarkTheme_GUICtrlSetDarkTheme
; _GUIDarkTheme_GUISetDarkTheme
; _GUIDarkTheme_SetCornerPref
; _GUIDarkTheme_SwitchTheme
; _GUIDarkTheme_ToolbarSetTrans
; _GUIDarkTheme_Version
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
; __GUIDarkMenu_CreateFont
; __GUIDarkMenu_GetTopMenuItems
; __GUIDarkMenu_MenuBarBKColor
; __GUIDarkMenu_PaintWhiteLine
; __GUIDarkMenu_WM_ACTIVATE
; __GUIDarkMenu_WM_DRAWITEM
; __GUIDarkMenu_WM_MEASUREITEM
; __GUIDarkMenu_WM_WINDOWPOSCHANGED
; __GUIDarkTheme_BrushCleanup
; __GUIDarkTheme_ButtonProc
; __GUIDarkTheme_CheckedPNG
; __GUIDarkTheme_CreateBrushes
; __GUIDarkTheme_CreatePens
; __GUIDarkTheme_DateProc
; __GUIDarkTheme_GetCtrlColors
; __GUIDarkTheme_GetCtrlStyleString
; __GUIDarkTheme_GetCtrlStyleString2
; __GUIDarkTheme_GetImages
; __GUIDarkTheme_GetStyleString
; __GUIDarkTheme_GroupProc
; __GUIDarkTheme_HotkeyProc
; __GUIDarkTheme_hWnd2Styles
; __GUIDarkTheme_IPAddrProc
; __GUIDarkTheme_OnExit
; __GUIDarkTheme_PenCleanup
; __GUIDarkTheme_ScrollbarProc
; __GUIDarkTheme_SetBandColor
; __GUIDarkTheme_StatusProc
; __GUIDarkTheme_SubclassCleanup
; __GUIDarkTheme_SubclassProc
; __GUIDarkTheme_SysLinkProc
; __GUIDarkTheme_TabProc
; __GUIDarkTheme_TrackbarProc
; __GUIDarkTheme_UncheckedPNG
; __GUIDarkTheme_UpDownProc
; __GUIDarkTheme_WM_CTLCOLOR
; __GUIDarkTheme_WM_NOTIFY
; __GUIDarkTheme_WM_SETCURSOR
; __GUIDarkTheme_WM_SETTINGCHANGE
; __GUIDarkTheme_WndProc
; ===============================================================================================================================

; #GLOBAL VARIABLES# ============================================================================================================
;
; Main Color Variable gets set when _GUIDarkTheme_GUISetDarkTheme() is called which determines if dark or light mode.
;
;	   Main Color Variable				Customize Dark Mode Colors (RGB)			Customize Light Mode Colors (RGB)
Global $__DM_g_iGuiBkColor, 		$__DM_g_iGuiBkColorDark		= 0x202020,		$__DM_g_iGuiBkColorLight     = 0xFFFFFF
Global $__DM_g_iTextColor,			$__DM_g_iTextColorDark		= 0xFFFFFF,		$__DM_g_iTextColorLight      = 0x000000
Global $__DM_g_iCtrlBkColor,		$__DM_g_iCtrlBkColorDark	= 0x383838,		$__DM_g_iCtrlBkColorLight    = 0xFFFFFF
Global $__DM_g_iBorderColor,		$__DM_g_iBorderColorDark	= 0x7A7A7A,		$__DM_g_iBorderColorLight    = 0x646464
Global $__DM_g_iSizeboxPaint,		$__DM_g_iSizeboxPaintDark	= 0x171717,		$__DM_g_iSizeboxPaintLight   = 0xF0F0F0
Global $__DM_g_iMenuBkColor,		$__DM_g_iMenuBkColorDark	= 0x202020,		$__DM_g_iMenuBkColorLight    = 0xF0F0F0
Global $__DM_g_iMenuHotColor,		$__DM_g_iMenuHotColorDark	= 0x303030,		$__DM_g_iMenuHotColorLight   = 0xE5E5E5
Global $__DM_g_iMenuSelColor,		$__DM_g_iMenuSelColorDark	= 0x272727,		$__DM_g_iMenuSelColorLight   = 0xEFEFEF
Global $__DM_g_iMenuTextColor,		$__DM_g_iMenuTextColorDark	= 0xE0E0E0,		$__DM_g_iMenuTextColorLight  = 0x000000
Global $__DM_g_iStatusBkColor,		$__DM_g_iStatusBkColorDark	= 0x191919,		$__DM_g_iStatusBkColorLight  = 0xF0F0F0
Global $__DM_g_iBtnBkColorDef,		$__DM_g_iBtnBkColorDefDark	= 0x333333,		$__DM_g_iBtnBkColorDefLight  = 0xF4F4F4
Global $__DM_g_iBtnBkColorHov,		$__DM_g_iBtnBkColorHovDark	= 0x454545,		$__DM_g_iBtnBkColorHovLight  = 0xE0EFF9
Global $__DM_g_iBtnBkColorSel,		$__DM_g_iBtnBkColorSelDark 	= 0x666666,		$__DM_g_iBtnBkColorSelLight  = 0xCCE4F7
Global $__DM_g_iBtnBkColorFoc,		$__DM_g_iBtnBkColorFocDark 	= 0x333333,		$__DM_g_iBtnBkColorFocLight  = 0xF4F4F4
Global $__DM_g_iBtnBkColorDis,		$__DM_g_iBtnBkColorDisDark 	= 0x333333,		$__DM_g_iBtnBkColorDisLight  = 0xF4F4F4
Global $__DM_g_iBtnBorderDef,		$__DM_g_iBtnBorderDefDark 	= 0x9B9B9B,		$__DM_g_iBtnBorderDefLight   = 0xBCBCBC
Global $__DM_g_iBtnBorderHov,		$__DM_g_iBtnBorderHovDark 	= 0x9B9B9B,		$__DM_g_iBtnBorderHovLight   = 0xBCBCBC
Global $__DM_g_iBtnBorderSel,		$__DM_g_iBtnBorderSelDark 	= 0x9B9B9B,		$__DM_g_iBtnBorderSelLight   = 0xBCBCBC
Global $__DM_g_iBtnBorderFoc,		$__DM_g_iBtnBorderFocDark 	= 0xFFFFFF,		$__DM_g_iBtnBorderFocLight   = 0xBCBCBC
Global $__DM_g_iBtnBorderDis,		$__DM_g_iBtnBorderDisDark 	= 0x404040,		$__DM_g_iBtnBorderDisLight   = 0xBCBCBC
Global $__DM_g_iTabColor,			$__DM_g_iTabColorDark 		= 0x303030,		$__DM_g_iTabColorLight       = 0xDBDBDB
Global $__DM_g_iExtraGray,			$__DM_g_iExtraGrayDark 		= 0x5E5E5E,		$__DM_g_iExtraGrayLight      = 0xCFCFCF

Global $__DM_g_iAccentColor = 0x0078D4
Global $__DM_g_iMsgBoxTopColor = 0x323232
Global $__DM_g_iMsgBoxBottomColor = 0x202020
Global $__DM_g_iMsgBoxButtonColor = $__DM_g_iMsgBoxBottomColor
Global $__DM_g_iMsgBoxTextColor = _WinAPI_SwitchColor(0xFFFFFF)

Global $__DM_g_hThreadID_WH_CBT = 0
Global $__DM_g_bUseDarkMode = _WinAPI_ShouldAppsUseDarkMode()
Global $__DM_g_bDarkModeLast
Global $__DM_g_hDialogProc = 0, $__DM_g_pDialogProc = 0
Global $__DM_g_bShowCtrlBorder = True
Global $__DM_g_bShowEditActive = True
Global $__DM_g_bPreviousRun = False
Global $__DM_g_bMicaEnabled = False

Global $__DM_g_bCustomButtonsEnable = False
Global $__DM_g_iCustomButtonRadius = 6

Global $__DM_g_hSubclassProc = 0, $__DM_g_pSubclassProc = 0
Global $__DM_g_hTabProc = 0, $__DM_g_pTabProc = 0
Global $__DM_g_hUpDownProc = 0, $__DM_g_pUpDownProc = 0
Global $__DM_g_hButtonProc = 0, $__DM_g_pButtonProc = 0
Global $__DM_g_hGroupProc = 0, $__DM_g_pGroupProc = 0
Global $__DM_g_hHotkeyProc = 0, $__DM_g_pHotkeyProc = 0
Global $__DM_g_hIpAddrProc = 0, $__DM_g_pIpAddrProc = 0
Global $__DM_g_hWndProc = 0, $__DM_g_pWndProc = 0
Global $__DM_g_hStatusProc = 0, $__DM_g_pStatusProc = 0
Global $__DM_g_hDateProc = 0, $__DM_g_pDateProc = 0
Global $__DM_g_hScrollbarProc = 0, $__DM_g_pScrollbarProc = 0
Global $__DM_g_hSysLinkProc = 0, $__DM_g_pSysLinkProc = 0
Global $__DM_g_hTrackbarProc = 0, $__DM_g_pTrackbarProc = 0
; ===============================================================================================================================

; #INTERNAL_USE_ONLY GLOBAL VARIABLES # =========================================================================================
Global $__DM_g_b24H2Plus = __DM_DarkThemeAvailability()
;$__DM_g_b24H2Plus = False ; just for debugging, simulating older OS during testing
Global $__DM_g_aMenuText = []
Global $__DM_g_iDpiRatio = 1
Global $__DM_g_iDpi = 100
Global $__DM_g_hMenuFont = 0
Global $g_hThemeWnd = 0
Global $__DM_g_hMDL2Font = 0
Global $__DM_g_iTimerCycles = 0
Global $__DM_g_GUICtrlSysLink_Data[4] = [-1, "", "", 0]
Global $__DM_g_GUICtrlSysLink_Callback = ""

Global $__DM_g_aEnumBuffer[256]
Global $__DM_g_iEnumCount = 0, $__DM_g_hEnumCallback = 0, $__DM_g_pEnumCallback = 0

Global $__DM_g_hThemeStatus = 0
Global $__DM_g_hThemeButton = 0
Global $__DM_g_hThemeTrackbar = 0

Global $__DM_g_aFontList[0][4]
Global $__DM_g_aFontSizes[0]

Global $__DM_g_hBrushCtrl = 0, $__DM_g_hBrushGui = 0, $__DM_g_hBrushSizebox = 0
Global $__DM_g_hBrushBtnDef = 0, $__DM_g_hBrushBtnHov = 0, $__DM_g_hBrushBtnSel = 0, $__DM_g_hBrushBtnFoc = 0, $__DM_g_hBrushBtnDis = 0
Global $__DM_g_hBrushGlyph = 0
Global $__DM_g_hBrushMenuBk = 0, $__DM_g_hBrushMenuSel = 0, $__DM_g_hBrushMenuHot = 0
Global $__DM_g_hBrushAccent = 0, $__DM_g_hBrushAccentHot = 0
Global $__DM_g_hBrushTab = 0
Global $__DM_g_hBrushGray = 0
Global $__DM_g_hBrushMsgBoxTop = 0, $__DM_g_hBrushMsgBoxBottom = 0
Global $__DM_g_hBrushHdr = 0, $__DM_g_hBrushHdrHot = 0, $__DM_g_hBrushHdrSel = 0
Global $__DM_g_hBrushBorder = 0, $__DM_g_hBrushStatus = 0

Global $__DM_g_hPenBtnBor = 0, $__DM_g_hPenGui = 0, $__DM_g_hPenBorder = 0
Global $__DM_g_hPenAccent = 0, $__DM_g_hPenBlack = 0, $__DM_g_hPenLight = 0
Global $__DM_g_hPen2Accent = 0, $__DM_g_hPen2Border = 0, $__DM_g_hPen2Ctrl = 0
Global $__DM_g_hPenBtnDef = 0, $__DM_g_hPenBtnHov = 0, $__DM_g_hPenBtnSel = 0, $__DM_g_hPenBtnFoc = 0, $__DM_g_hPenBtnDis = 0
; ===============================================================================================================================

; #GLOBAL CONSTANTS# ============================================================================================================
Global Const $__DM_WM_CHANGETHEME = $WM_APP + 10
Global Const $__DM_WM_COLORMODECHANGED = $WM_APP + 11
Global Const $WM_DPICHANGED_AFTERPARENT = 0x02E3

Global Const $TVS_EX_DOUBLEBUFFER = 0x0004

Global Const $DWM_SYSTEMBACKDROP_TYPE = 38
Global Const $DWMSBT_AUTO = 0
Global Const $DWMSBT_NONE = 1
Global Const $DWMSBT_MAINWINDOW = 2
Global Const $DWMSBT_TRANSIENTWINDOW = 3
Global Const $DWMSBT_TABBEDWINDOW = 4

Global Const $TKP_TRACK = 1
Global Const $TKP_TRACKVERT = 2
Global Const $TKP_THUMB = 3
Global Const $TKP_THUMBBOTTOM = 4
Global Const $TKP_THUMBTOP = 5
Global Const $TKP_THUMBVERT = 6
Global Const $TKP_THUMBLEFT = 7
Global Const $TKP_THUMBRIGHT = 8
Global Const $TKP_TICS = 9
Global Const $TKP_TICSVERT = 10

Global Const $TUS_NORMAL = 1
Global Const $TUS_HOT = 2
Global Const $TUS_PRESSED = 3
Global Const $TUS_FOCUSED = 4
Global Const $TUS_DISABLED = 5

Global Const $DWMWCP_DEFAULT = 0
Global Const $DWMWCP_DONOTROUND = 1
Global Const $DWMWCP_ROUND = 2
Global Const $DWMWCP_ROUNDSMALL = 3

Global Const $BP_RADIOBUTTON = 2
Global Const $BP_CHECKBOX = 3
Global Const $BP_GROUPBOX = 4

Global Const $GBS_NORMAL = 1
Global Const $GBS_DISABLED = 2

Global Const $ETO_OPAQUE = 0x0002
Global Const $ETO_CLIPPED = 0x0004

Global Const $SP_GRIPPER = 3

Global Const $HKM_SETHOTKEY = 0x0401
Global Const $HKM_GETHOTKEY = 0x0402

Global Const $PBST_NORMAL = 0x0001
Global Const $PBST_ERROR = 0x0002
Global Const $PBST_PAUSED = 0x0003

Global Const $LM_GETIDEALHEIGHT = 0x0701
Global Const $LM_GETITEM = 0x0703
Global Const $LM_HITTEST = 0x0700
Global Const $LM_SETITEM = 0x0702
Global Const $LM_GETIDEALSIZE = $LM_GETIDEALHEIGHT

Global Const $LIF_ITEMINDEX = 0x01
Global Const $LIF_STATE = 0x02
Global Const $LIF_ITEMID = 0x04
Global Const $LIF_URL = 0x08

Global Const $LIS_ENABLED = 0x02
Global Const $LIS_FOCUSED = 0x01
Global Const $LIS_VISITED = 0x04
Global Const $LIS_HOTTRACK = 0x08
Global Const $LIS_DEFAULTCOLORS = 0x10

Global Const $HCBT_MOVESIZE = 0
Global Const $HCBT_MINMAX = 1
Global Const $HCBT_QS = 2
Global Const $HCBT_CREATEWND = 3
Global Const $HCBT_DESTROYWND = 4
Global Const $HCBT_ACTIVATE = 5
Global Const $HCBT_CLICKSKIPPED = 6
Global Const $HCBT_KEYSKIPPED = 7
Global Const $HCBT_SYSCOMMAND = 8
Global Const $HCBT_SETFOCUS = 9

Global Const $CBS_UNCHECKEDNORMAL = 1
Global Const $CBS_UNCHECKEDHOT = 2
Global Const $CBS_UNCHECKEDPRESSED = 3
Global Const $CBS_UNCHECKEDDISABLED = 4
Global Const $CBS_CHECKEDNORMAL = 5
Global Const $CBS_CHECKEDHOT = 6
Global Const $CBS_CHECKEDPRESSED = 7
Global Const $CBS_CHECKEDDISABLED = 8
Global Const $CBS_MIXEDNORMAL = 9
Global Const $CBS_MIXEDHOT = 10
Global Const $CBS_MIXEDPRESSED = 11
Global Const $CBS_MIXEDDISABLED = 12

Global Const $RBS_UNCHECKEDNORMAL = 1
Global Const $RBS_UNCHECKEDHOT = 2
Global Const $RBS_UNCHECKEDPRESSED = 3
Global Const $RBS_UNCHECKEDDISABLED = 4
Global Const $RBS_CHECKEDNORMAL = 5
Global Const $RBS_CHECKEDHOT = 6
Global Const $RBS_CHECKEDPRESSED = 7
Global Const $RBS_CHECKEDDISABLED = 8

Global Const $ODT_MENU = 1
Global Const $ODS_SELECTED = 0x0001
Global Const $ODS_DISABLED = 0x0004
Global Const $ODS_HOTLIGHT = 0x0040
Global Const $ODS_NOACCEL = 0x0100
Global Const $PRF_CLIENT = 0x0004

Global Const $TBCDRF_USECDCOLORS = 0x800000
Global Const $TBCDRF_NOBACKGROUND = 0x400000
Global Const $TBCDRF_HILITEHOTTRACK = 0x20000

Global Const $tagLITEM = "uint Mask;int Link;uint State;uint StateMask;wchar ID[48];wchar Url[2073]"
Global Const $tagLHITTESTINFO = "int X;int Y;" & $tagLITEM
Global Const $tagNMLINK = "struct;hwnd hwndFrom;uint_PTR idFrom;int code;" & (@AutoItX64 ? "int pad;" : "") & "endstruct;" & $tagLITEM

Global Const $tagNMTBCUSTOMDRAW = $tagNMHDR & ";dword dwDrawStage;handle hdc;" & $tagRECT & ";dword_ptr dwItemSpec;uint uItemState;lparam lItemlParam;" & _
		"ptr hbrMonoDither;ptr hbrLines;ptr hpenLines;dword clrText;dword clrMark;dword clrTextHighlight;dword clrBtnFace;dword clrBtnHighlight;dword clrHighlightHotTrack;" & _
		"long TextLeft;long TextTop;long TextRight;long TextBottom;int nStringBkMode;int nHLStringBkMode;int iListGap;"

Global Const $__DM_tagNMCUSTOMDRAW = _
		$tagNMHDR & ";" & _                                    ; Contains NM_CUSTOMDRAW / NMHDR header among other things
		"dword dwDrawStage;" & _                               ; Current drawing stage (CDDS_*)
		"handle hdc;" & _                                      ; Device Context Handle
		"long left;long top;long right;long bottom;" & _       ; Drawing rectangle
		"dword_ptr dwItemSpec;" & _                            ; Item index or other info (depending on the control)
		"uint uItemState;" & _                                 ; State Flags (CDIS_SELECTED, CDIS_FOCUS etc.)
		"lparam lItemlParam"                                   ; lParam set by the item (e.g., via LVITEM.lParam)

Global Const $__DM_g_Style_Gui[32][2] = _
		[[0x80000000, 'WS_POPUP'], _
		[0x40000000, 'WS_CHILD'], _
		[0x20000000, 'WS_MINIMIZE'], _
		[0x10000000, 'WS_VISIBLE'], _
		[0x08000000, 'WS_DISABLED'], _
		[0x04000000, 'WS_CLIPSIBLINGS'], _
		[0x02000000, 'WS_CLIPCHILDREN'], _
		[0x01000000, 'WS_MAXIMIZE'], _
		[0x00CF0000, 'WS_OVERLAPPEDWINDOW'], _ ; (WS_CAPTION | WS_SYSMENU | WS_SIZEBOX | WS_MINIMIZEBOX | WS_MAXIMIZEBOX) aka 'WS_TILEDWINDOW'
		[0x00C00000, 'WS_CAPTION'], _      ; (WS_BORDER | WS_DLGFRAME)
		[0x00800000, 'WS_BORDER'], _
		[0x00400000, 'WS_DLGFRAME'], _
		[0x00200000, 'WS_VSCROLL'], _
		[0x00100000, 'WS_HSCROLL'], _
		[0x00080000, 'WS_SYSMENU'], _
		[0x00040000, 'WS_SIZEBOX'], _
		[0x00020000, '! WS_MINIMIZEBOX ! WS_GROUP'], _ ; ! GUI ! Control
		[0x00010000, '! WS_MAXIMIZEBOX ! WS_TABSTOP'], _ ; ! GUI ! Control
		[0x00002000, 'DS_CONTEXTHELP'], _
		[0x00001000, 'DS_CENTERMOUSE'], _
		[0x00000800, 'DS_CENTER'], _
		[0x00000400, 'DS_CONTROL'], _
		[0x00000200, 'DS_SETFOREGROUND'], _
		[0x00000100, 'DS_NOIDLEMSG'], _
		[0x00000080, 'DS_MODALFRAME'], _
		[0x00000040, 'DS_SETFONT'], _
		[0x00000020, 'DS_LOCALEDIT'], _
		[0x00000010, 'DS_NOFAILCREATE'], _
		[0x00000008, 'DS_FIXEDSYS'], _
		[0x00000004, 'DS_3DLOOK'], _
		[0x00000002, 'DS_SYSMODAL'], _
		[0x00000001, 'DS_ABSALIGN']]
;
; [0x80880000, 'WS_POPUPWINDOW']
; [0x20000000, 'WS_ICONIC']
; [0x00040000, 'WS_THICKFRAME']
;
; [0x00000000, 'WS_OVERLAPPED'] ; also named 'WS_TILED'

Global Const $__DM_g_Style_GuiExtended[21][2] = _
		[[0x08000000, 'WS_EX_NOACTIVATE'], _
		[0x02000000, 'WS_EX_COMPOSITED'], _
		[0x00400000, 'WS_EX_LAYOUTRTL'], _
		[0x00100000, '! WS_EX_NOINHERITLAYOUT ! GUI_WS_EX_PARENTDRAG'], _ ; ! GUI ! Control (label or pic, AutoIt "draggable" feature on 2 controls)
		[0x00080000, 'WS_EX_LAYERED'], _
		[0x00040000, 'WS_EX_APPWINDOW'], _
		[0x00020000, 'WS_EX_STATICEDGE'], _
		[0x00010000, 'WS_EX_CONTROLPARENT'], _ ; AutoIt adds a "draggable" feature to this GUI extended style behavior
		[0x00004000, 'WS_EX_LEFTSCROLLBAR'], _
		[0x00002000, 'WS_EX_RTLREADING'], _
		[0x00001000, 'WS_EX_RIGHT'], _
		[0x00000400, 'WS_EX_CONTEXTHELP'], _
		[0x00000200, 'WS_EX_CLIENTEDGE'], _
		[0x00000100, 'WS_EX_WINDOWEDGE'], _
		[0x00000080, 'WS_EX_TOOLWINDOW'], _
		[0x00000040, 'WS_EX_MDICHILD'], _
		[0x00000020, 'WS_EX_TRANSPARENT'], _
		[0x00000010, 'WS_EX_ACCEPTFILES'], _
		[0x00000008, 'WS_EX_TOPMOST'], _
		[0x00000004, 'WS_EX_NOPARENTNOTIFY'], _
		[0x00000001, 'WS_EX_DLGMODALFRAME']]
;
; [0x00000300, 'WS_EX_OVERLAPPEDWINDOW']
; [0x00000188, 'WS_EX_PALETTEWINDOW']
;
; [0x00000000, 'WS_EX_LEFT']
; [0x00000000, 'WS_EX_LTRREADING']
; [0x00000000, 'WS_EX_RIGHTSCROLLBAR']

Global Const $__DM_g_Style_Avi[5][2] = _
		[[0x0010, 'ACS_NONTRANSPARENT'], _
		[0x0008, 'ACS_TIMER'], _
		[0x0004, 'ACS_AUTOPLAY'], _
		[0x0002, 'ACS_TRANSPARENT'], _
		[0x0001, 'ACS_CENTER']]

Global Const $__DM_g_Style_Button[28][2] = _
		[[0x8000, 'BS_FLAT'], _
		[0x4000, 'BS_NOTIFY'], _
		[0x2000, 'BS_MULTILINE'], _
		[0x1000, 'BS_PUSHLIKE'], _
		[0x0C00, 'BS_VCENTER'], _
		[0x0800, 'BS_BOTTOM'], _
		[0x0400, 'BS_TOP'], _
		[0x0300, 'BS_CENTER'], _
		[0x0200, 'BS_RIGHT'], _
		[0x0100, 'BS_LEFT'], _
		[0x0080, 'BS_BITMAP'], _
		[0x0040, 'BS_ICON'], _
		[0x0020, 'BS_RIGHTBUTTON'], _
		[0x000F, 'BS_DEFCOMMANDLINK'], _
		[0x000E, 'BS_COMMANDLINK'], _
		[0x000D, 'BS_DEFSPLITBUTTON'], _
		[0x000C, 'BS_SPLITBUTTON'], _
		[0x000B, 'BS_OWNERDRAW'], _
		[0x000A, 'BS_PUSHBOX'], _
		[0x0009, 'BS_AUTORADIOBUTTON'], _
		[0x0008, 'BS_USERBUTTON'], _
		[0x0007, 'BS_GROUPBOX'], _
		[0x0006, 'BS_AUTO3STATE'], _
		[0x0005, 'BS_3STATE'], _
		[0x0004, 'BS_RADIOBUTTON'], _
		[0x0003, 'BS_AUTOCHECKBOX'], _
		[0x0002, 'BS_CHECKBOX'], _
		[0x0001, 'BS_DEFPUSHBUTTON']]

Global Const $__DM_g_Style_Combo[13][2] = _
		[[0x4000, 'CBS_LOWERCASE'], _
		[0x2000, 'CBS_UPPERCASE'], _
		[0x0800, 'CBS_DISABLENOSCROLL'], _
		[0x0400, 'CBS_NOINTEGRALHEIGHT'], _
		[0x0200, 'CBS_HASSTRINGS'], _
		[0x0100, 'CBS_SORT'], _
		[0x0080, 'CBS_OEMCONVERT'], _
		[0x0040, 'CBS_AUTOHSCROLL'], _
		[0x0020, 'CBS_OWNERDRAWVARIABLE'], _
		[0x0010, 'CBS_OWNERDRAWFIXED'], _
		[0x0003, 'CBS_DROPDOWNLIST'], _
		[0x0002, 'CBS_DROPDOWN'], _
		[0x0001, 'CBS_SIMPLE']]

Global Const $__DM_g_Style_Common[12][2] = _ ; "for rebar controls, toolbar controls, and status windows (msdn)"
		[[0x0083, 'CCS_RIGHT'], _
		[0x0082, 'CCS_NOMOVEX'], _
		[0x0081, 'CCS_LEFT'], _
		[0x0080, 'CCS_VERT'], _
		[0x0040, 'CCS_NODIVIDER'], _
		[0x0020, 'CCS_ADJUSTABLE'], _
		[0x0010, 'CCS_NOHILITE'], _
		[0x0008, 'CCS_NOPARENTALIGN'], _
		[0x0004, 'CCS_NORESIZE'], _
		[0x0003, 'CCS_BOTTOM'], _
		[0x0002, 'CCS_NOMOVEY'], _
		[0x0001, 'CCS_TOP']]

Global Const $__DM_g_Style_DateTime[7][2] = _
		[[0x0020, 'DTS_RIGHTALIGN'], _
		[0x0010, 'DTS_APPCANPARSE'], _
		[0x000C, 'DTS_SHORTDATECENTURYFORMAT'], _
		[0x0009, 'DTS_TIMEFORMAT'], _
		[0x0004, 'DTS_LONGDATEFORMAT'], _
		[0x0002, 'DTS_SHOWNONE'], _
		[0x0001, 'DTS_UPDOWN']]
;
; [0x0000, 'DTS_SHORTDATEFORMAT']

Global Const $__DM_g_Style_Edit[13][2] = _
		[[0x2000, 'ES_NUMBER'], _
		[0x1000, 'ES_WANTRETURN'], _
		[0x0800, 'ES_READONLY'], _
		[0x0400, 'ES_OEMCONVERT'], _
		[0x0100, 'ES_NOHIDESEL'], _
		[0x0080, 'ES_AUTOHSCROLL'], _
		[0x0040, 'ES_AUTOVSCROLL'], _
		[0x0020, 'ES_PASSWORD'], _
		[0x0010, 'ES_LOWERCASE'], _
		[0x0008, 'ES_UPPERCASE'], _
		[0x0004, 'ES_MULTILINE'], _
		[0x0002, 'ES_RIGHT'], _
		[0x0001, 'ES_CENTER']]

Global Const $__DM_g_Style_Header[10][2] = _
		[[0x1000, 'HDS_OVERFLOW'], _
		[0x0800, 'HDS_NOSIZING'], _
		[0x0400, 'HDS_CHECKBOXES'], _
		[0x0200, 'HDS_FLAT'], _
		[0x0100, 'HDS_FILTERBAR'], _
		[0x0080, 'HDS_FULLDRAG'], _
		[0x0040, 'HDS_DRAGDROP'], _
		[0x0008, 'HDS_HIDDEN'], _
		[0x0004, 'HDS_HOTTRACK'], _
		[0x0002, 'HDS_BUTTONS']]
;
; [0x0000, '$HDS_HORZ']

Global Const $__DM_g_Style_ListBox[16][2] = _
		[[0x8000, 'LBS_COMBOBOX'], _
		[0x4000, 'LBS_NOSEL'], _
		[0x2000, 'LBS_NODATA'], _
		[0x1000, 'LBS_DISABLENOSCROLL'], _
		[0x0800, 'LBS_EXTENDEDSEL'], _
		[0x0400, 'LBS_WANTKEYBOARDINPUT'], _
		[0x0200, 'LBS_MULTICOLUMN'], _
		[0x0100, 'LBS_NOINTEGRALHEIGHT'], _
		[0x0080, 'LBS_USETABSTOPS'], _
		[0x0040, 'LBS_HASSTRINGS'], _
		[0x0020, 'LBS_OWNERDRAWVARIABLE'], _
		[0x0010, 'LBS_OWNERDRAWFIXED'], _
		[0x0008, 'LBS_MULTIPLESEL'], _
		[0x0004, 'LBS_NOREDRAW'], _
		[0x0002, 'LBS_SORT'], _
		[0x0001, 'LBS_NOTIFY']]
;
; [0xA00003, 'LBS_STANDARD'] ; i.e. (LBS_NOTIFY | LBS_SORT | WS_VSCROLL | WS_BORDER) help file correct, ListBoxConstants.au3 incorrect

Global Const $__DM_g_Style_ListView[17][2] = _
		[[0x8000, 'LVS_NOSORTHEADER'], _
		[0x4000, 'LVS_NOCOLUMNHEADER'], _
		[0x2000, 'LVS_NOSCROLL'], _
		[0x1000, 'LVS_OWNERDATA'], _
		[0x0800, 'LVS_ALIGNLEFT'], _
		[0x0400, 'LVS_OWNERDRAWFIXED'], _
		[0x0200, 'LVS_EDITLABELS'], _
		[0x0100, 'LVS_AUTOARRANGE'], _
		[0x0080, 'LVS_NOLABELWRAP'], _
		[0x0040, 'LVS_SHAREIMAGELISTS'], _
		[0x0020, 'LVS_SORTDESCENDING'], _
		[0x0010, 'LVS_SORTASCENDING'], _
		[0x0008, 'LVS_SHOWSELALWAYS'], _
		[0x0004, 'LVS_SINGLESEL'], _
		[0x0003, 'LVS_LIST'], _
		[0x0002, 'LVS_SMALLICON'], _
		[0x0001, 'LVS_REPORT']]
;
; [0x0000, 'LVS_ICON']
; [0x0000, 'LVS_ALIGNTOP']

Global Const $__DM_g_Style_ListViewExtended[20][2] = _
		[[0x00100000, 'LVS_EX_SIMPLESELECT'], _
		[0x00080000, 'LVS_EX_SNAPTOGRID'], _
		[0x00020000, 'LVS_EX_HIDELABELS'], _
		[0x00010000, 'LVS_EX_DOUBLEBUFFER'], _
		[0x00008000, 'LVS_EX_BORDERSELECT'], _
		[0x00004000, 'LVS_EX_LABELTIP'], _
		[0x00002000, 'LVS_EX_MULTIWORKAREAS'], _
		[0x00001000, 'LVS_EX_UNDERLINECOLD'], _
		[0x00000800, 'LVS_EX_UNDERLINEHOT'], _
		[0x00000400, 'LVS_EX_INFOTIP'], _
		[0x00000200, 'LVS_EX_REGIONAL'], _
		[0x00000100, 'LVS_EX_FLATSB'], _
		[0x00000080, 'LVS_EX_TWOCLICKACTIVATE'], _
		[0x00000040, 'LVS_EX_ONECLICKACTIVATE'], _
		[0x00000020, 'LVS_EX_FULLROWSELECT'], _
		[0x00000010, 'LVS_EX_HEADERDRAGDROP'], _
		[0x00000008, 'LVS_EX_TRACKSELECT'], _
		[0x00000004, 'LVS_EX_CHECKBOXES'], _
		[0x00000002, 'LVS_EX_SUBITEMIMAGES'], _
		[0x00000001, 'LVS_EX_GRIDLINES']]

Global Const $__DM_g_Style_MonthCal[8][2] = _
		[[0x0100, 'MCS_NOSELCHANGEONNAV'], _
		[0x0080, 'MCS_SHORTDAYSOFWEEK'], _
		[0x0040, 'MCS_NOTRAILINGDATES'], _
		[0x0010, 'MCS_NOTODAY'], _
		[0x0008, 'MCS_NOTODAYCIRCLE'], _
		[0x0004, 'MCS_WEEKNUMBERS'], _
		[0x0002, 'MCS_MULTISELECT'], _
		[0x0001, 'MCS_DAYSTATE']]

Global Const $__DM_g_Style_Pager[3][2] = _
		[[0x0004, 'PGS_DRAGNDROP'], _
		[0x0002, 'PGS_AUTOSCROLL'], _
		[0x0001, 'PGS_HORZ']]
;
; [0x0000, 'PGS_VERT']

Global Const $__DM_g_Style_Progress[4][2] = _
		[[0x0010, 'PBS_SMOOTHREVERSE'], _
		[0x0008, 'PBS_MARQUEE'], _
		[0x0004, 'PBS_VERTICAL'], _
		[0x0001, 'PBS_SMOOTH']]

Global Const $__DM_g_Style_Rebar[8][2] = _
		[[0x8000, 'RBS_DBLCLKTOGGLE'], _
		[0x4000, 'RBS_VERTICALGRIPPER'], _
		[0x2000, 'RBS_AUTOSIZE'], _
		[0x1000, 'RBS_REGISTERDROP'], _
		[0x0800, 'RBS_FIXEDORDER'], _
		[0x0400, 'RBS_BANDBORDERS'], _
		[0x0200, 'RBS_VARHEIGHT'], _
		[0x0100, 'RBS_TOOLTIPS']]

Global Const $__DM_g_Style_RichEdit[8][2] = _      ; will also use plenty (not all) of Edit styles
		[[0x01000000, 'ES_SELECTIONBAR'], _
		[0x00400000, 'ES_VERTICAL'], _      ; Asian-language support only (msdn)
		[0x00080000, 'ES_NOIME'], _         ; ditto
		[0x00040000, 'ES_SELFIME'], _       ; ditto
		[0x00008000, 'ES_SAVESEL'], _
		[0x00004000, 'ES_SUNKEN'], _
		[0x00002000, 'ES_DISABLENOSCROLL'], _ ; same value as 'ES_NUMBER' => issue ?
		[0x00000008, 'ES_NOOLEDRAGDROP']]   ; same value as 'ES_UPPERCASE' but RichRdit controls do not support 'ES_UPPERCASE' style (msdn)

Global Const $__DM_g_Style_Scrollbar[5][2] = _
		[[0x0010, 'SBS_SIZEGRIP'], _
		[0x0008, 'SBS_SIZEBOX'], _
		[0x0004, 'SBS_RIGHTALIGN or SBS_BOTTOMALIGN'], _ ; i.e. use SBS_RIGHTALIGN with SBS_VERT, use SBS_BOTTOMALIGN with SBS_HORZ (msdn)
		[0x0002, 'SBS_LEFTALIGN or SBS_TOPALIGN'], _ ; i.e. use SBS_LEFTALIGN  with SBS_VERT, use SBS_TOPALIGN    with SBS_HORZ (msdn)
		[0x0001, 'SBS_VERT']]
;
; [0x0000, 'SBS_HORZ']

Global Const $__DM_g_Style_Slider[13][2] = _ ; i.e. trackbar
		[[0x1000, 'TBS_TRANSPARENTBKGND'], _
		[0x0800, 'TBS_NOTIFYBEFOREMOVE'], _
		[0x0400, 'TBS_DOWNISLEFT'], _
		[0x0200, 'TBS_REVERSED'], _
		[0x0100, 'TBS_TOOLTIPS'], _
		[0x0080, 'TBS_NOTHUMB'], _
		[0x0040, 'TBS_FIXEDLENGTH'], _
		[0x0020, 'TBS_ENABLESELRANGE'], _
		[0x0010, 'TBS_NOTICKS'], _
		[0x0008, 'TBS_BOTH'], _
		[0x0004, 'TBS_LEFT or TBS_TOP'], _ ; i.e. TBS_LEFT tick marks when vertical slider, or TBS_TOP tick marks when horizontal slider
		[0x0002, 'TBS_VERT'], _
		[0x0001, 'TBS_AUTOTICKS']]
;
; [0x0000, 'TBS_RIGHT']
; [0x0000, 'TBS_BOTTOM']
; [0x0000, 'TBS_HORZ']

Global Const $__DM_g_Style_Static[29][2] = _
		[[0xC000, 'SS_WORDELLIPSIS'], _
		[0x8000, 'SS_PATHELLIPSIS'], _
		[0x4000, 'SS_ENDELLIPSIS'], _
		[0x2000, 'SS_EDITCONTROL'], _
		[0x1000, 'SS_SUNKEN'], _
		[0x0800, 'SS_REALSIZEIMAGE'], _
		[0x0400, 'SS_RIGHTJUST'], _
		[0x0200, 'SS_CENTERIMAGE'], _
		[0x0100, 'SS_NOTIFY'], _
		[0x0080, 'SS_NOPREFIX'], _
		[0x0040, 'SS_REALSIZECONTROL'], _
		[0x0012, 'SS_ETCHEDFRAME'], _
		[0x0011, 'SS_ETCHEDVERT'], _
		[0x0010, 'SS_ETCHEDHORZ'], _
		[0x000F, 'SS_ENHMETAFILE'], _
		[0x000E, 'SS_BITMAP'], _
		[0x000D, 'SS_OWNERDRAW'], _
		[0x000C, 'SS_LEFTNOWORDWRAP'], _
		[0x000B, 'SS_SIMPLE'], _
		[0x000A, 'SS_USERITEM'], _
		[0x0009, 'SS_WHITEFRAME'], _
		[0x0008, 'SS_GRAYFRAME'], _
		[0x0007, 'SS_BLACKFRAME'], _
		[0x0006, 'SS_WHITERECT'], _
		[0x0005, 'SS_GRAYRECT'], _
		[0x0004, 'SS_BLACKRECT'], _
		[0x0003, 'SS_ICON'], _
		[0x0002, 'SS_RIGHT'], _
		[0x0001, 'SS_CENTER']]
;
; [0x0000, 'SS_LEFT']

Global Const $__DM_g_Style_StatusBar[2][2] = _
		[[0x0800, 'SBARS_TOOLTIPS'], _
		[0x0100, 'SBARS_SIZEGRIP']]
;
; [0x0800, 'SBT_TOOLTIPS']

Global Const $__DM_g_Style_Tab[17][2] = _
		[[0x8000, 'TCS_FOCUSNEVER'], _
		[0x4000, 'TCS_TOOLTIPS'], _
		[0x2000, 'TCS_OWNERDRAWFIXED'], _
		[0x1000, 'TCS_FOCUSONBUTTONDOWN'], _
		[0x0800, 'TCS_RAGGEDRIGHT'], _
		[0x0400, 'TCS_FIXEDWIDTH'], _
		[0x0200, 'TCS_MULTILINE'], _
		[0x0100, 'TCS_BUTTONS'], _
		[0x0080, 'TCS_VERTICAL'], _
		[0x0040, 'TCS_HOTTRACK'], _
		[0x0020, 'TCS_FORCELABELLEFT'], _
		[0x0010, 'TCS_FORCEICONLEFT'], _
		[0x0008, 'TCS_FLATBUTTONS'], _
		[0x0004, 'TCS_MULTISELECT'], _
		[0x0002, 'TCS_RIGHT'], _
		[0x0002, 'TCS_BOTTOM'], _
		[0x0001, 'TCS_SCROLLOPPOSITE']]
;
; [0x0000, 'TCS_TABS']
; [0x0000, 'TCS_SINGLELINE']
; [0x0000, 'TCS_RIGHTJUSTIFY']

Global Const $__DM_g_Style_Toolbar[8][2] = _
		[[0x8000, 'TBSTYLE_TRANSPARENT'], _
		[0x4000, 'TBSTYLE_REGISTERDROP'], _
		[0x2000, 'TBSTYLE_CUSTOMERASE'], _
		[0x1000, 'TBSTYLE_LIST'], _
		[0x0800, 'TBSTYLE_FLAT'], _
		[0x0400, 'TBSTYLE_ALTDRAG'], _
		[0x0200, 'TBSTYLE_WRAPABLE'], _
		[0x0100, 'TBSTYLE_TOOLTIPS']]

Global Const $__DM_g_Style_TreeView[16][2] = _
		[[0x8000, 'TVS_NOHSCROLL'], _
		[0x4000, 'TVS_NONEVENHEIGHT'], _
		[0x2000, 'TVS_NOSCROLL'], _
		[0x1000, 'TVS_FULLROWSELECT'], _
		[0x0800, 'TVS_INFOTIP'], _
		[0x0400, 'TVS_SINGLEEXPAND'], _
		[0x0200, 'TVS_TRACKSELECT'], _
		[0x0100, 'TVS_CHECKBOXES'], _
		[0x0080, 'TVS_NOTOOLTIPS'], _
		[0x0040, 'TVS_RTLREADING'], _
		[0x0020, 'TVS_SHOWSELALWAYS'], _
		[0x0010, 'TVS_DISABLEDRAGDROP'], _
		[0x0008, 'TVS_EDITLABELS'], _
		[0x0004, 'TVS_LINESATROOT'], _
		[0x0002, 'TVS_HASLINES'], _
		[0x0001, 'TVS_HASBUTTONS']]

Global Const $__DM_g_Style_UpDown[9][2] = _
		[[0x0100, 'UDS_HOTTRACK'], _
		[0x0080, 'UDS_NOTHOUSANDS'], _
		[0x0040, 'UDS_HORZ'], _
		[0x0020, 'UDS_ARROWKEYS'], _
		[0x0010, 'UDS_AUTOBUDDY'], _
		[0x0008, 'UDS_ALIGNLEFT'], _
		[0x0004, 'UDS_ALIGNRIGHT'], _
		[0x0002, 'UDS_SETBUDDYINT'], _
		[0x0001, 'UDS_WRAP']]

; ===============================================================================================================================

; GDI+ Startup
_GDIPlus_Startup()

Opt("TrayAutoPause", 0) ; disabling TrayAutoPause prevents subclassing crashes

OnAutoItExitRegister("__GUIDarkTheme_OnExit")

; Early creation of Dark MsgBox brushes
If Not $__DM_g_hBrushMsgBoxTop Then $__DM_g_hBrushMsgBoxTop = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iMsgBoxTopColor))
If Not $__DM_g_hBrushMsgBoxBottom Then $__DM_g_hBrushMsgBoxBottom = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iMsgBoxBottomColor))

; Create MsgBox subclass and hook
If Not $__DM_g_hDialogProc Then $__DM_g_hDialogProc = DllCallbackRegister(__DM_DialogProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
If Not $__DM_g_pDialogProc Then $__DM_g_pDialogProc = DllCallbackGetPtr($__DM_g_hDialogProc)
Global $__DM_g_hMsgProc = DllCallbackRegister(__DM_CBTHookProc, "int", "uint;wparam;lparam")
Global $__DM_g_hThreadID = _WinAPI_GetCurrentThreadId()
If Not $__DM_g_hThreadID_WH_CBT Then $__DM_g_hThreadID_WH_CBT = _WinAPI_SetWindowsHookEx($WH_CBT, DllCallbackGetPtr($__DM_g_hMsgProc), Null, $__DM_g_hThreadID)

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_OnExit()
	; Enumerate all AutoIt v3 GUI windows under current PID and GUIDelete on exit
	; Needed in case user forgets to use GUIDelete()
	Local $aData = _WinAPI_EnumProcessWindows(@AutoItPID, False)
	For $i = 1 To $aData[0][0]
		If $aData[$i][1] = "AutoIt v3 GUI" Then GUIDelete($aData[$i][0])
	Next
	; Font cleanup
	If $__DM_g_hMenuFont Then _WinAPI_DeleteObject($__DM_g_hMenuFont)
	; Dark msgbox cleanup
	If $__DM_g_hDialogProc Then DllCallbackFree($__DM_g_hDialogProc)
	If $__DM_g_hThreadID_WH_CBT Then _WinAPI_UnhookWindowsHookEx($__DM_g_hThreadID_WH_CBT)
	If $__DM_g_hMsgProc Then DllCallbackFree($__DM_g_hMsgProc)
	__GUIDarkTheme_SubclassCleanup()
	__GUIDarkTheme_BrushCleanup()
	__GUIDarkTheme_PenCleanup()
	If $__DM_g_hEnumCallback Then DllCallbackFree($__DM_g_hEnumCallback)
	If $__DM_g_hThemeTrackbar Then _WinAPI_CloseThemeData($__DM_g_hThemeTrackbar)
	If $__DM_g_hThemeStatus Then _WinAPI_CloseThemeData($__DM_g_hThemeStatus)
	If $__DM_g_hThemeButton Then _WinAPI_CloseThemeData($__DM_g_hThemeButton)
	If $__DM_g_hMDL2Font Then _WinAPI_DeleteObject($__DM_g_hMDL2Font)
	_GDIPlus_Shutdown()
EndFunc   ;==>__GUIDarkTheme_OnExit

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_ScrollbarProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Switch $iMsg
		Case $WM_THEMECHANGED, $WM_DPICHANGED_AFTERPARENT
			; Theme handles become invalid after theme changes or DPI changes
			If $__DM_g_hThemeStatus Then
				_WinAPI_CloseThemeData($__DM_g_hThemeStatus)
				$__DM_g_hThemeStatus = 0
			EndIf

			Return 0

		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			If $__DM_g_hThemeStatus Then
				_WinAPI_CloseThemeData($__DM_g_hThemeStatus)
				$__DM_g_hThemeStatus = 0
			EndIf
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_ERASEBKGND
			Return 1 ; Prevent background erasing to avoid flickering

		Case $WM_PAINT
			Local $tPAINTSTRUCT
			Local $hDC = _WinAPI_BeginPaint($hWnd, $tPAINTSTRUCT)
			Local $iWidth = DllStructGetData($tPAINTSTRUCT, 'rPaint', 3) - DllStructGetData($tPAINTSTRUCT, 'rPaint', 1)
			Local $iHeight = DllStructGetData($tPAINTSTRUCT, 'rPaint', 4) - DllStructGetData($tPAINTSTRUCT, 'rPaint', 2)

			; Paint SizeGrip only when window is not maximized
			If Not $__DM_g_hThemeStatus Then $__DM_g_hThemeStatus = _WinAPI_OpenThemeData(_WinAPI_GetParent($hWnd), 'Status')
			Local $tRectGrip = _WinAPI_CreateRectEx(0, 0, $iWidth, $iHeight)
			If Not BitAND(WinGetState(_WinAPI_GetParent($hWnd)), $WIN_STATE_MAXIMIZED) Then
				_WinAPI_DrawThemeBackground($__DM_g_hThemeStatus, $SP_GRIPPER, 0, $hDC, $tRectGrip)
			EndIf

			_WinAPI_EndPaint($hWnd, $tPAINTSTRUCT)
			Return 0
	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_ScrollbarProc

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_StatusProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Switch $iMsg
		Case $WM_THEMECHANGED, $WM_DPICHANGED_AFTERPARENT
			; Theme handles become invalid after theme changes or DPI changes
			If $__DM_g_hThemeStatus Then
				_WinAPI_CloseThemeData($__DM_g_hThemeStatus)
				$__DM_g_hThemeStatus = 0
			EndIf

			Return 0

		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_ERASEBKGND
			Return 1 ; Prevent background erasing to avoid flickering

		Case $WM_PAINT
			Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
			Local $hDC = _WinAPI_BeginPaint($hWnd, $tPaint)

			Local $tClient = _WinAPI_GetClientRect($hWnd)
			Local $iW = $tClient.Right
			Local $iH = $tClient.Bottom

			; Setup double buffering to prevent flicker
			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iW, $iH)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			_WinAPI_FillRect($hMemDC, DllStructGetPtr($tClient), $__DM_g_hBrushStatus)

			; Setup font
			Local $hFont = _SendMessage($hWnd, $WM_GETFONT, 0, 0)
			If Not $hFont Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
			Local $hOldFont = _WinAPI_SelectObject($hMemDC, $hFont)

			_WinAPI_SetTextColor($hMemDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
			_WinAPI_SetBkMode($hMemDC, $TRANSPARENT)

			Local $aParts = _GUICtrlStatusBar_GetParts($hWnd)
			Local $iTextFlags = BitOR($DT_SINGLELINE, $DT_NOCLIP, $DT_VCENTER, $DT_LEFT)
			Local $hPen = $__DM_g_hPenBorder
			Local $o_Orig = _WinAPI_SelectObject($hMemDC, $hPen)
			Local $tTextRect, $iEdgeRight, $sText, $iFlag
			Local $bNoBorders = False
			For $i = 0 To $aParts[0] - 1
				$tTextRect = _GUICtrlStatusBar_GetRectEx($hWnd, $i)
				$iFlag = _GUICtrlStatusBar_GetTextLengthEx($hWnd, $i)
				If BitAND($iFlag, $SBT_NOBORDERS) Then $bNoBorders = True
				$iEdgeRight = $aParts[$i + 1]
				If $iEdgeRight <> -1 And Not $bNoBorders Then
					_WinAPI_DrawLine($hMemDC, $iEdgeRight, $tTextRect.top - 1, $iEdgeRight, $tTextRect.bottom)
				EndIf

				$sText = _GUICtrlStatusBar_GetText($hWnd, $i)
				$tTextRect.left = $tTextRect.left + 6
				_WinAPI_DrawText($hMemDC, $sText, $tTextRect, $iTextFlags)
			Next

			; outer frame, optional depending on $SBT_NOBORDERS
			If Not $bNoBorders Then _WinAPI_FrameRect($hMemDC, $tClient, $__DM_g_hBrushBorder)

			_WinAPI_SelectObject($hMemDC, $o_Orig)

			; Draw grip
			Local Const $TS_TRUE = 1
			If Not $__DM_g_hThemeStatus Then $__DM_g_hThemeStatus = _WinAPI_OpenThemeData(_WinAPI_GetParent($hWnd), 'Status')
			Local $tSIZE = _WinAPI_GetThemePartSize($__DM_g_hThemeStatus, $SP_GRIPPER, 0, Null, Null, $TS_TRUE)
			Local $iGripSize = $tSIZE.X

			Local $iWidth = _WinAPI_GetClientWidth($hWnd)
			Local $iHeight = _WinAPI_GetClientHeight($hWnd)
			Local $tRectGrip = _WinAPI_CreateRectEx($iWidth - $iGripSize, $iHeight - $iGripSize, $iGripSize, $iGripSize)
			If Not BitAND(WinGetState(_WinAPI_GetParent($hWnd)), $WIN_STATE_MAXIMIZED) Then
				_WinAPI_DrawThemeBackground($__DM_g_hThemeStatus, 3, 0, $hMemDC, $tRectGrip)
			EndIf

			_WinAPI_BitBlt($hDC, 0, 0, $iW, $iH, $hMemDC, 0, 0, $SRCCOPY)

			_WinAPI_SelectObject($hMemDC, $hOldFont)
			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)

			_WinAPI_EndPaint($hWnd, $tPaint)
			Return 0
	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_StatusProc

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_GroupProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Switch $iMsg
		Case $WM_THEMECHANGED, $WM_DPICHANGED_AFTERPARENT
			; Theme handles become invalid after theme changes or DPI changes
			If $__DM_g_hThemeButton Then
				_WinAPI_CloseThemeData($__DM_g_hThemeButton)
				$__DM_g_hThemeButton = 0
			EndIf

			Return 0

		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_ERASEBKGND
			Return 1

		Case $WM_PAINT
			Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
			Local $hDC = _WinAPI_BeginPaint($hWnd, $tPaint)

			Local $tClient = _WinAPI_GetClientRect($hWnd)
			Local $iW = $tClient.Right
			Local $iH = $tClient.Bottom

			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iW, $iH)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			Local $hFont = _SendMessage($hWnd, $WM_GETFONT, 0, 0)
			If Not $hFont Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
			Local $hOldFont = _WinAPI_SelectObject($hMemDC, $hFont)

			Local $sText = _WinAPI_GetWindowText($hWnd)
			Local $tTextSize = _WinAPI_GetTextExtentPoint32($hMemDC, $sText)
			Local $iTextWidth = $tTextSize.X
			Local $iTextHeight = $tTextSize.Y

			; exclude clip testing
			Local $tCR = _WinAPI_GetClientRect($hWnd)
			$tCR.Top = $tCR.Top + $iTextHeight + 2
			$tCR.Bottom = $tCR.Bottom - 5
			$tCR.Left = $tCR.Left + 5
			$tCR.Right = $tCR.Right - 5
			_WinAPI_ExcludeClipRect($hDC, $tCR)
			_WinAPI_ExcludeClipRect($hMemDC, $tCR)

			_WinAPI_DrawThemeParentBackground($hWnd, $hMemDC, $tClient)

			Local $hGraphics = _GDIPlus_GraphicsCreateFromHDC($hMemDC)
			_GDIPlus_GraphicsSetSmoothingMode($hGraphics, 2)

			Local $iRadius = 1
			Local $iX = 0
			Local $iY = Int($iTextHeight / 2)
			Local $iWidth = $iW - 1 - $iX
			Local $iHeight = $iH - 1 - $iY - 1

			Local $hPath = _GDIPlus_PathCreate()
			_GDIPlus_PathAddLine($hPath, $iX + $iRadius, $iY, $iX + $iWidth - $iRadius, $iY)
			_GDIPlus_PathAddArc($hPath, $iX + $iWidth - ($iRadius * 2), $iY, $iRadius * 2, $iRadius * 2, 270, 90)
			_GDIPlus_PathAddLine($hPath, $iX + $iWidth, $iY + $iRadius, $iX + $iWidth, $iY + $iHeight - $iRadius)
			_GDIPlus_PathAddArc($hPath, $iX + $iWidth - ($iRadius * 2), $iY + $iHeight - ($iRadius * 2), $iRadius * 2, $iRadius * 2, 0, 90)
			_GDIPlus_PathAddLine($hPath, $iX + $iWidth - $iRadius, $iY + $iHeight, $iX + $iRadius, $iY + $iHeight)
			_GDIPlus_PathAddArc($hPath, $iX, $iY + $iHeight - ($iRadius * 2), $iRadius * 2, $iRadius * 2, 90, 90)
			_GDIPlus_PathAddLine($hPath, $iX, $iY + $iHeight - $iRadius, $iX, $iY + $iRadius)
			_GDIPlus_PathAddArc($hPath, $iX, $iY, $iRadius * 2, $iRadius * 2, 180, 90)
			_GDIPlus_PathCloseFigure($hPath)

			If $sText <> "" Then
				Local $hRegion = _GDIPlus_RegionCreate()
				_GDIPlus_RegionCombineRect($hRegion, 7, 0, $iTextWidth + 4, $iTextHeight, 0)
				_GDIPlus_GraphicsSetClipRegion($hGraphics, $hRegion, 3)
				_GDIPlus_RegionDispose($hRegion)
			EndIf

			Local $hPen = _GDIPlus_PenCreate(0xFF525252, 1)
			_GDIPlus_GraphicsDrawPath($hGraphics, $hPath, $hPen)

			_GDIPlus_GraphicsResetClip($hGraphics)
			_GDIPlus_PenDispose($hPen)
			_GDIPlus_PathDispose($hPath)

			If $sText <> "" Then
				If Not $__DM_g_hThemeButton Then $__DM_g_hThemeButton = _WinAPI_OpenThemeData($hWnd, "DarkMode_Explorer::Button")
				Local $tDTTOPTS = DllStructCreate($tagDTTOPTS)
				DllStructSetData($tDTTOPTS, 'Size', DllStructGetSize($tDTTOPTS))
				DllStructSetData($tDTTOPTS, 'Flags', $DTT_TEXTCOLOR)
				DllStructSetData($tDTTOPTS, 'clrText', 0xFFFFFF)

				Local $iTextFlags = BitOR($DT_SINGLELINE, $DT_LEFT, $DT_TOP)
				Local $tDrawTextRect = _WinAPI_CreateRectEx(9, 0, $iTextWidth, $iTextHeight)

				_WinAPI_DrawThemeTextEx($__DM_g_hThemeButton, $BP_GROUPBOX, $GBS_NORMAL, $hMemDC, $sText, $tDrawTextRect, $iTextFlags, $tDTTOPTS)
			EndIf

			_GDIPlus_GraphicsDispose($hGraphics)

			_WinAPI_BitBlt($hDC, 0, 0, $iW, $iH, $hMemDC, 0, 0, $SRCCOPY)

			_WinAPI_SelectObject($hMemDC, $hOldFont)
			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)

			_WinAPI_EndPaint($hWnd, $tPaint)
			Return 0

	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_GroupProc

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_ButtonProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID
	Switch $iMsg
		Case $WM_THEMECHANGED, $WM_DPICHANGED_AFTERPARENT
			; Theme handles become invalid after theme changes or DPI changes
			If $__DM_g_hThemeButton Then
				_WinAPI_CloseThemeData($__DM_g_hThemeButton)
				$__DM_g_hThemeButton = 0
			EndIf

			Return 0

		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_ERASEBKGND
			Return 1 ; Prevent background erasing to avoid flickering

		Case $WM_PAINT
			Local $iPartID, $sStyles = __GUIDarkTheme_hWnd2Styles($hWnd)
			If StringInStr($sStyles, "BS_AUTORADIOBUTTON") Then $iPartID = $BP_RADIOBUTTON
			If StringInStr($sStyles, "CHECKBOX") Then $iPartID = $BP_CHECKBOX
			If StringInStr($sStyles, "BS_AUTO3STATE") Then $iPartID = $BP_CHECKBOX

			If Not $__DM_g_hThemeButton Then $__DM_g_hThemeButton = _WinAPI_OpenThemeData($hWnd, "DarkMode_Explorer::Button")

			Local $iStateID = 0

			Local Const $BST_HOT = 0x0200

			Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
			Local $hDC = _WinAPI_BeginPaint($hWnd, $tPaint)

			Local $tClient = _WinAPI_GetClientRect($hWnd)
			Local $iW = $tClient.Right
			Local $iH = $tClient.Bottom

			; Initiate double buffering
			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iW, $iH)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			Local $iState = _GUICtrlButton_GetState($hWnd)

			; Determine StateID from current state
			Switch $iPartID
				Case $BP_CHECKBOX
					Switch _WinAPI_IsWindowEnabled($hWnd)
						Case True
							If BitAND($iState, $BST_INDETERMINATE) Then
								If BitAND($iState, $BST_HOT) Then
									$iStateID = $CBS_MIXEDHOT
								Else
									$iStateID = $CBS_MIXEDNORMAL
								EndIf
							ElseIf BitAND($iState, $BST_CHECKED) Then
								If BitAND($iState, $BST_HOT) Then
									$iStateID = $CBS_CHECKEDHOT
								Else
									$iStateID = $CBS_CHECKEDNORMAL
								EndIf
							Else
								If BitAND($iState, $BST_HOT) Then
									$iStateID = $CBS_UNCHECKEDHOT
								Else
									$iStateID = $CBS_UNCHECKEDNORMAL
								EndIf
							EndIf
						Case False
							If BitAND($iState, $BST_INDETERMINATE) Then
								$iStateID = $CBS_MIXEDDISABLED
							ElseIf BitAND($iState, $BST_CHECKED) Then
								$iStateID = $CBS_CHECKEDDISABLED
							Else
								$iStateID = $CBS_UNCHECKEDDISABLED
							EndIf
					EndSwitch

				Case $BP_RADIOBUTTON
					Switch _WinAPI_IsWindowEnabled($hWnd)
						Case True
							If BitAND($iState, $BST_CHECKED) Then
								If BitAND($iState, $BST_HOT) Then
									$iStateID = $RBS_CHECKEDHOT
								Else
									$iStateID = $RBS_CHECKEDNORMAL
								EndIf
							Else
								If BitAND($iState, $BST_HOT) Then
									$iStateID = $RBS_UNCHECKEDHOT
								Else
									$iStateID = $RBS_UNCHECKEDNORMAL
								EndIf
							EndIf
						Case False
							If BitAND($iState, $BST_CHECKED) Then
								$iStateID = $RBS_CHECKEDDISABLED
							Else
								$iStateID = $RBS_UNCHECKEDDISABLED
							EndIf
					EndSwitch
			EndSwitch

			; Determine DrawText $DT_* flags based on detected styles
			Local $iTextFlags
			Select
				Case StringInStr($sStyles, "BS_RIGHT") <> 0
					$iTextFlags = BitOR($DT_SINGLELINE, $DT_NOCLIP, $DT_VCENTER, $DT_RIGHT)
				Case StringInStr($sStyles, "BS_CENTER") <> 0
					$iTextFlags = BitOR($DT_SINGLELINE, $DT_NOCLIP, $DT_VCENTER, $DT_CENTER)
				Case Else
					$iTextFlags = BitOR($DT_SINGLELINE, $DT_NOCLIP, $DT_VCENTER, $DT_LEFT)
			EndSelect

			; GetThemeBackgroundContentRect
			Local $tTextRect = _WinAPI_GetThemeBackgroundContentRect($__DM_g_hThemeButton, $iPartID, $iStateID, $hMemDC, $tClient)
			Local $tSIZE = _WinAPI_GetThemePartSize($__DM_g_hThemeButton, $iPartID, 0, Null, Null, $TS_TRUE)

			; Get text from control
			Local $sText = _WinAPI_GetWindowText($hWnd)

			; DrawThemeParentBackground
			_WinAPI_DrawThemeParentBackground($hWnd, $hMemDC, $tClient)

			; DrawThemeBackground
			Local $iWidth = $tSIZE.X
			Local $iHeight = $tSIZE.Y
			Local $iClientHeight = $tClient.Bottom - $tClient.Top
			Local $iHeightPad = ($iClientHeight - $iHeight)
			Local $tRect = _WinAPI_CreateRectEx(0, 0, $iWidth, $iHeight + $iHeightPad)
			_WinAPI_DrawThemeBackground($__DM_g_hThemeButton, $iPartID, $iStateID, $hMemDC, $tRect)

			; Set flags for DTTOPTS structure
			Local $tDTTOPTS = DllStructCreate($tagDTTOPTS)
			DllStructSetData($tDTTOPTS, 'Size', DllStructGetSize($tDTTOPTS))
			DllStructSetData($tDTTOPTS, 'Flags', $DTT_TEXTCOLOR)
			DllStructSetData($tDTTOPTS, 'clrText', _WinAPI_IsWindowEnabled($hWnd) ? 0xFFFFFF : 0x808080)

			; Setup font
			Local $hFont = _SendMessage($hWnd, $WM_GETFONT, 0, 0)
			If Not $hFont Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
			Local $hOldFont = _WinAPI_SelectObject($hMemDC, $hFont)

			$tTextRect.Left = $tTextRect.Left + $tSIZE.X + 3
			$tTextRect.Right = $tTextRect.Right + $tSIZE.X + 3

			;_WinAPI_SetBkMode($hMemDC, $TRANSPARENT)
			;_WinAPI_SetBkColor($hMemDC, _WinAPI_SwitchColor($__DM_g_iCtrlBkColor))
			;_WinAPI_SetTextColor($hMemDC, _WinAPI_SwitchColor($__DM_g_iTextColor))

			_WinAPI_DrawThemeTextEx($__DM_g_hThemeButton, $BP_CHECKBOX, $iStateID, $hMemDC, $sText, $tTextRect, $iTextFlags, $tDTTOPTS)
			;_WinAPI_DrawText($hMemDC, $sText, $tTextRect, $iTextFlags)

			_WinAPI_BitBlt($hDC, 0, 0, $iW, $iH, $hMemDC, 0, 0, $SRCCOPY)

			; Cleanup
			_WinAPI_SelectObject($hDC, $hOldFont)
			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)

			_WinAPI_EndPaint($hWnd, $tPaint)
			Return 0

	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_ButtonProc

; #FUNCTION# ====================================================================================================================
; Author.........: Nine
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_UpDownProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Local Static $bHover
	Local $bHorz = BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $UDS_HORZ)
	Local $tRectTmp, $iPos, $hBrush
	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_PAINT
			Local $tPaint, $hDC = _WinAPI_BeginPaint($hWnd, $tPaint)
			Local $tRect = _WinAPI_GetClientRect($hWnd)
			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $tRect.right, $tRect.bottom)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			Local $hPen = $__DM_g_hPenBtnBor
			_WinAPI_SelectObject($hMemDC, $hPen)
			$hBrush = $__DM_g_hBrushBtnDef
			_WinAPI_SetBkMode($hMemDC, $TRANSPARENT)
			_WinAPI_SelectObject($hMemDC, $hBrush)
			_WinAPI_Rectangle($hMemDC, $tRect)
			If $bHorz Then
				_WinAPI_DrawLine($hMemDC, Int($tRect.right / 2), 0, Int($tRect.right / 2), $tRect.bottom)
			Else
				_WinAPI_DrawLine($hMemDC, 0, Int($tRect.bottom / 2), $tRect.right, Int($tRect.bottom / 2))
			EndIf

			If $bHover Then
				If $bHorz Then
					$iPos = Round(_WinAPI_GetMousePos(True, $hWnd).x / _WinAPI_GetClientRect($hWnd).right, 0)
				Else
					$iPos = Round(_WinAPI_GetMousePos(True, $hWnd).y / _WinAPI_GetClientRect($hWnd).bottom, 0)
				EndIf

				If _IsPressed($VK_LBUTTON, 'user32.dll') Then
					$hBrush = $__DM_g_hBrushBtnSel
				Else
					$hBrush = $__DM_g_hBrushBtnHov
				EndIf

				$tRectTmp = _WinAPI_GetClientRect($hWnd)
				If $iPos Then
					If $bHorz Then
						$tRectTmp.left = Int($tRect.right / 2)
					Else
						$tRectTmp.top = Int($tRect.bottom / 2)
					EndIf
				Else
					If $bHorz Then
						$tRectTmp.right = Int($tRect.right / 2)
					Else
						$tRectTmp.bottom = Int($tRect.bottom / 2)
					EndIf
				EndIf
				_WinAPI_SelectObject($hMemDC, $hBrush)
				_WinAPI_Rectangle($hMemDC, $tRectTmp)
			EndIf

			_WinAPI_SetTextColor($hMemDC, $__DM_g_iTextColor)
			$tRectTmp = _WinAPI_GetClientRect($hWnd)
			Local $iFH = 7 * $__DM_g_iDpiRatio
			Local $sFontName = "Segoe MDL2 Assets"
			Local $hFont = _WinAPI_CreateFont($iFH, 0, 0, 0, $FW_NORMAL, False, False, False, _
					$DEFAULT_CHARSET, $OUT_DEFAULT_PRECIS, $CLIP_DEFAULT_PRECIS, $PROOF_QUALITY, $DEFAULT_PITCH, $sFontName)
			_WinAPI_SelectObject($hMemDC, $hFont)
			If $bHorz Then
				$tRectTmp.top = Int(($tRect.bottom - $iFH) / 2)
				$tRectTmp.right = $tRect.right / 2
				_WinAPI_DrawText($hMemDC, ChrW(0xEDD9), $tRectTmp, BitOR($DT_CENTER, $DT_VCENTER, $DT_NOCLIP))
				$tRectTmp.left = Int($tRect.right / 2)
				$tRectTmp.right = $tRect.right
				_WinAPI_DrawText($hMemDC, ChrW(0xEDDA), $tRectTmp, BitOR($DT_CENTER, $DT_VCENTER, $DT_NOCLIP))
			Else
				$tRectTmp.top = Int((Round($tRect.bottom / 2) - $iFH) / 2)
				_WinAPI_DrawText($hMemDC, ChrW(0xEDDB), $tRectTmp, BitOR($DT_CENTER, $DT_VCENTER, $DT_NOCLIP))
				$tRectTmp.top += Round($tRect.bottom / 2)
				_WinAPI_DrawText($hMemDC, ChrW(0xEDDC), $tRectTmp, BitOR($DT_CENTER, $DT_VCENTER, $DT_NOCLIP))
			EndIf

			_WinAPI_BitBlt($hDC, 0, 0, $tRect.right, $tRect.bottom, $hMemDC, 0, 0, $SRCCOPY)

			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)
			_WinAPI_DeleteObject($hFont)
			_WinAPI_EndPaint($hWnd, $tPaint)
		Case $WM_MOUSEMOVE
			$bHover = True
			_WinAPI_TrackMouseEvent($hWnd, $TME_LEAVE)
			_WinAPI_InvalidateRect($hWnd, 0, False)
			Return
		Case $WM_MOUSELEAVE
			$bHover = False
			_WinAPI_InvalidateRect($hWnd, 0, False)
			Return
	EndSwitch
	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_UpDownProc

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: mLipok, WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_TabProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_LBUTTONDOWN
			; Force focus to tab control on any click
			_WinAPI_SetFocus($hWnd)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_ERASEBKGND
			Return 1 ; Prevent background erasing to avoid flickering

		Case $WM_PAINT
			Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
			Local $hDC = _WinAPI_BeginPaint($hWnd, $tPaint)
			If @error Or Not $hDC Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

			Local $iImage, $iIconWidth, $hImageList = _GUICtrlTab_GetImageList($hWnd)
			If $hImageList Then
				$iIconWidth = _GUIImageList_GetIconWidth($hImageList)
			EndIf

			Local $tClient = _WinAPI_GetClientRect($hWnd)
			Local $iWidth = $tClient.Right
			Local $iHeight = $tClient.Bottom

			; Prepare Double Buffering
			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			; Fill background but exclude overlapping GUI controls from painting
			Local $hChild, $hParent = _WinAPI_GetParent($hWnd)
			Local $aCR, $aPR = _WinAPI_GetWindowRectAsArray($hWnd)
			Local Enum $eLeft, $eTop, $eRight, $eBottom
			Local $iLeftCR, $iTopCR, $iRightCR, $iBottomCR
			Local $aCtrls = __DM_EnumChildWindows($hParent)
			If IsArray($aCtrls) Then
				For $i = 0 To UBound($aCtrls) - 1
					$hChild = $aCtrls[$i]
					If $hChild <> $hWnd Then
						$aCR = _WinAPI_GetWindowRectAsArray($hChild)

						; Only exclude controls that lie fully within the tab control area
						If $aCR[$eLeft] >= $aPR[$eLeft] And $aCR[$eRight] <= $aPR[$eRight] And $aCR[$eTop] >= $aPR[$eTop] And $aCR[$eBottom] <= $aPR[$eBottom] Then
							If _WinAPI_IsWindowVisible($hChild) Then
								$iLeftCR = $aCR[$eLeft] - $aPR[$eLeft]
								$iTopCR = $aCR[$eTop] - $aPR[$eTop]
								$iRightCR = $aCR[$eRight] - $aPR[$eLeft]
								$iBottomCR = $aCR[$eBottom] - $aPR[$eTop]
								; Exclude from offscreen bitmap (prevents black fill)
								DllCall("gdi32.dll", "int", "ExcludeClipRect", "handle", $hMemDC, "int", $iLeftCR, "int", $iTopCR, "int", $iRightCR, "int", $iBottomCR)
								; Exclude from screen DC (prevents BitBlt overwrite)
								DllCall("gdi32.dll", "int", "ExcludeClipRect", "handle", $hDC, "int", $iLeftCR, "int", $iTopCR, "int", $iRightCR, "int", $iBottomCR)
							EndIf
						EndIf
					EndIf
				Next
			EndIf

			; Determine if tab control contains an UpDown (spin) control
			Local $hTabUpDown = _WinAPI_FindChildByClass($hWnd, "msctls_updown32")
			If $hTabUpDown And _WinAPI_IsWindowVisible($hTabUpDown) Then
				Local $tCR = _WinAPI_GetWindowRect($hTabUpDown)
				Local $tPR = _WinAPI_GetWindowRect($hWnd)

				; Exclude UpDown control from being painted over
				DllCall('gdi32.dll', "int", "ExcludeClipRect", "handle", $hDC, "int", $tCR.Left - $tPR.Left, "int", _
						$tCR.Top - $tPR.Top - 100, "int", $tCR.Right - $tPR.Left, "int", $tCR.Bottom - $tPR.Top + 2)
			EndIf

			; Fill entire tab control with GUI background color
			_WinAPI_FillRect($hMemDC, $tClient, $__DM_g_hBrushGui)

			Local $iTabCount = _SendMessage($hWnd, $TCM_GETITEMCOUNT, 0, 0)
			Local $iCurSel = _SendMessage($hWnd, $TCM_GETCURSEL, 0, 0)

			; Setup font
			Local $hFont = _SendMessage($hWnd, $WM_GETFONT, 0, 0)
			If Not $hFont Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
			Local $hOldFont = _WinAPI_SelectObject($hMemDC, $hFont)

			; Prepare the Body Frame (The area beneath the tabs)
			Local $tFirstTabRect = DllStructCreate($tagRECT)
			_SendMessage($hWnd, $TCM_GETITEMRECT, 0, DllStructGetPtr($tFirstTabRect))

			Local $tBodyRect = DllStructCreate($tagRECT)
			$tBodyRect.Left = 0
			$tBodyRect.Top = $tFirstTabRect.Bottom  ; Starts at the bottom edge of the tabs
			$tBodyRect.Right = $iWidth
			$tBodyRect.Bottom = $iHeight

			_WinAPI_FillRect($hMemDC, $tBodyRect, $__DM_g_hBrushGui)
			_WinAPI_FrameRect($hMemDC, $tBodyRect, $__DM_g_hBrushBorder)

			_WinAPI_SetBkMode($hMemDC, $TRANSPARENT)
			_WinAPI_SetTextColor($hMemDC, _WinAPI_SwitchColor($__DM_g_iTextColor))

			; Draw individual tabs
			Local $tRect = DllStructCreate($tagRECT)
			Local $tOpenLine = DllStructCreate($tagRECT)
			Local $tTextRect = DllStructCreate($tagRECT)
			For $i = 0 To $iTabCount - 1
				Local $bSelected = ($i = $iCurSel)

				_SendMessage($hWnd, $TCM_GETITEMRECT, $i, DllStructGetPtr($tRect))
				If $tRect.Right < 0 Or $tRect.Left > $iWidth Then ContinueLoop

				If $bSelected Then
					; Draw selected tab
					$tRect.top -= 2

					; Fill tab background
					_WinAPI_FillRect($hMemDC, $tRect, $__DM_g_hBrushGui)

					; Draw border ONLY for the active tab (Top, Left, Right)
					_WinAPI_FrameRect($hMemDC, $tRect, $__DM_g_hBrushBorder)

					; OPEN BOTTOM: Draw a line in tab-color over the body-border to merge them
					$tOpenLine.Left = $tRect.Left + 1
					$tOpenLine.Top = $tRect.Bottom - 1 ; Exactly on the border line of the body
					$tOpenLine.Right = $tRect.Right - 1
					$tOpenLine.Bottom = $tRect.Bottom + 1
					_WinAPI_FillRect($hMemDC, $tOpenLine, $__DM_g_hBrushGui)

					; Draw selection indicator with accent color
					Local $iLeft = $tRect.Left
					Local $iTop = $tRect.Top
					Local $iRight = $tRect.Right
					Local $hPen = $__DM_g_hPen2Accent
					Local $hOldPen = _WinAPI_SelectObject($hMemDC, $hPen)
					_WinAPI_MoveTo($hMemDC, $iLeft + 1, $iTop)
					_WinAPI_LineTo($hMemDC, $iRight - 2, $iTop + 1)
					_WinAPI_SelectObject($hMemDC, $hOldPen)
				Else
					; draw tab
					$tRect.top -= 0
					$tRect.bottom += 1
					$tRect.Left -= 1
					$tRect.Right += 1

					; Fill tab background
					_WinAPI_FillRect($hMemDC, $tRect, $__DM_g_hBrushTab)

					; Draw rectangle around non active tabs
					_WinAPI_FrameRect($hMemDC, $tRect, $__DM_g_hBrushBorder)
				EndIf

				; Draw images (if available)
				If $hImageList Then
					$iImage = _GUICtrlTab_GetItemImage($hWnd, $i)
					If $iImage > -1 Then
						_GUIImageList_Draw($hImageList, $i, $hMemDC, $tRect.Left + ($bSelected ? 2 : 3), $tRect.top + ($bSelected ? 2 : 2))
					EndIf
				EndIf

				; Draw text centered
				Local $sText = _GUICtrlTab_GetItemText($hWnd, $i)
				With $tTextRect
					.Left = $tRect.Left + ($bSelected ? 6 : 7) + $iIconWidth
					.Top = $tRect.Top + ($bSelected ? 1 : 3)
					.Right = $tRect.Right - 6
					.Bottom = $tRect.Bottom - 3
				EndWith
				DllCall("user32.dll", "int", "DrawTextW", "handle", $hMemDC, "wstr", $sText, "int", -1, "struct*", $tTextRect, "uint", BitOR($DT_LEFT, $DT_VCENTER, $DT_SINGLELINE, $DT_NOCLIP))

			Next

			; Copy memory DC to screen DC (BitBlt)
			_WinAPI_BitBlt($hDC, 0, 0, $iWidth, $iHeight, $hMemDC, 0, 0, $SRCCOPY)

			; Cleanup
			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_SelectObject($hMemDC, $hOldFont)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)
			_WinAPI_EndPaint($hWnd, $tPaint)
			Return 0

		Case $WM_PARENTNOTIFY
			; Fired when a child window is created inside the tab control.
			; The tab spinner (msctls_updown32) is created lazily by Windows when tabs overflow -
			; it doesn't exist at init time, so we theme it here the moment it appears.
			If _WinAPI_LoWord($wParam) = $WM_CREATE Then
				Local $hNewChild = HWnd($lParam) ; lParam carries the new child's HWND as integer - must cast!
				If _WinAPI_GetClassName($hNewChild) = "msctls_updown32" Then
					If Not $__DM_g_hUpDownProc Then
						$__DM_g_hUpDownProc = DllCallbackRegister(__GUIDarkTheme_UpDownProc, "lresult", _
								"hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
						$__DM_g_pUpDownProc = DllCallbackGetPtr($__DM_g_hUpDownProc)
					EndIf
					_WinAPI_SetWindowSubclass($hNewChild, $__DM_g_pUpDownProc, $hNewChild, $__DM_g_hUpDownProc)
				EndIf
			EndIf
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_TabProc

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_DateProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	Local $hDC
	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_NOTIFY
			Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
			Local $iCode = $tNMHDR.Code

			; this is needed to remove the white border from MonthCal drop down
			If $iCode = $NM_CUSTOMDRAW Then
				Local $tNMCUSTOMDRAW = DllStructCreate($__DM_tagNMCUSTOMDRAW, $lParam)
				Local $dwDrawStage = $tNMCUSTOMDRAW.dwDrawStage
				$hDC = $tNMCUSTOMDRAW.hdc

				Switch $dwDrawStage
					Case $CDDS_PREPAINT
						Return $CDRF_NOTIFYITEMDRAW
				EndSwitch
			EndIf

		Case $WM_PAINT
			Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
			$hDC = _WinAPI_BeginPaint($hWnd, $tPaint)

			Local $tClient = _WinAPI_GetClientRect($hWnd)
			Local $iW = $tClient.Right
			Local $iH = $tClient.Bottom

			; --- Memory DC for flicker-free rendering ---
			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iW, $iH)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			; 1. Let Windows draw the light-mode control into memory DC
			_SendMessage($hWnd, $WM_PRINTCLIENT, $hMemDC, $PRF_CLIENT)

			; 2. Invert all pixels (background becomes black, text white, selection orange)
			Local $tRect = DllStructCreate($tagRECT)
			$tRect.right = $iW
			$tRect.bottom = $iH
			_WinAPI_InvertRect($hMemDC, $tRect)

			; --- 3. PIXEL HACK: destroy orange highlight & set background color ---
			Local $iSize = $iW * $iH
			Local $tPixels = DllStructCreate("dword c[" & $iSize & "]")
			; Load pixel array directly from bitmap memory
			Local $iBytes = DllCall('gdi32.dll', "long", "GetBitmapBits", "handle", $hBitmap, "long", $iSize * 4, "ptr", DllStructGetPtr($tPixels))[0]

			If $iBytes = $iSize * 4 Then
				Local $iPixel, $r, $g, $b, $iGray
				For $i = 1 To $iSize
					$iPixel = $tPixels.c(($i))

					; Split into color channels
					$b = BitAND($iPixel, 0xFF)
					$g = BitAND(BitShift($iPixel, 8), 0xFF)
					$r = BitAND(BitShift($iPixel, 16), 0xFF)

					; Convert to grayscale (orange becomes mid-gray)
					$iGray = Int(($r + $g + $b) / 3)

					; Very dark pixel = inverted white background
					If $iGray < 15 Then
						$iPixel = $__DM_g_iGuiBkColor ; Replace with exact GUI background color
					Else
						; Grayscale value for text (white) and selection (gray)
						; (negative BitShift shifts left in AutoIt)
						$iPixel = BitOR(BitShift($iGray, -16), BitShift($iGray, -8), $iGray)
					EndIf

					$tPixels.c(($i)) = $iPixel
				Next
				; Write cleaned pixels back into the bitmap
				DllCall('gdi32.dll', "long", "SetBitmapBits", "handle", $hBitmap, "long", $iSize * 4, "ptr", DllStructGetPtr($tPixels))
			EndIf
			; --- END PIXEL HACK ---

			; --- Border color (hover effect) ---
			Local $tCursorPos = DllStructCreate($tagPOINT)
			DllCall('user32.dll', "bool", "GetCursorPos", "struct*", $tCursorPos)
			DllCall('user32.dll', "bool", "ScreenToClient", "hwnd", $hWnd, "struct*", $tCursorPos)

			; --- Draw border ---
			Local $hPen = $__DM_g_hPenBorder
			Local $hNullBr = _WinAPI_GetStockObject(5)
			Local $hOldPen = _WinAPI_SelectObject($hMemDC, $hPen)
			Local $hOldBr = _WinAPI_SelectObject($hMemDC, $hNullBr)
			DllCall('gdi32.dll', "bool", "Rectangle", "handle", $hMemDC, "int", 0, "int", 0, "int", $iW, "int", $iH)
			_WinAPI_SelectObject($hMemDC, $hOldPen)
			_WinAPI_SelectObject($hMemDC, $hOldBr)

			; --- Copy finished result to screen in one step (no flicker) ---
			_WinAPI_BitBlt($hDC, 0, 0, $iW, $iH, $hMemDC, 0, 0, $SRCCOPY)

			; --- Cleanup ---
			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)
			_WinAPI_EndPaint($hWnd, $tPaint)
			Return 0

		Case $WM_ERASEBKGND
			Return 1

	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_DateProc

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_WndProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Local Const $WM_DPICHANGED = 0x02E0
	Local $iRet, $iDPI

	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_DPICHANGED
			; Obtain new DPI value (raw)
			$iDPI = _WinAPI_LoWord($wParam)
			$__DM_g_iDpiRatio = $iDPI / 96
			Local $hOldMenuFont = $__DM_g_hMenuFont
			$__DM_g_hMenuFont = _PM_GetMenuFont($iDPI)
			_GUIDarkMenu_Register($hWnd)
			If $hOldMenuFont Then _WinAPI_DeleteObject($hOldMenuFont)

			If $__DM_g_hThemeStatus Then
				_WinAPI_CloseThemeData($__DM_g_hThemeStatus)
				$__DM_g_hThemeStatus = 0
			EndIf

			If $__DM_g_hThemeButton Then
				_WinAPI_CloseThemeData($__DM_g_hThemeButton)
				$__DM_g_hThemeButton = 0
			EndIf

			If $__DM_g_hMDL2Font Then
				_WinAPI_DeleteObject($__DM_g_hMDL2Font)
				$__DM_g_hMDL2Font = 0
			EndIf

			Local $aCtrls = _WinAPI_EnumChildWindows($hWnd, False)
			Local $hCtrl, $sClass
			If IsArray($aCtrls) Then
				_ArrayColInsert($aCtrls, 2)
				_ArrayColInsert($aCtrls, 2)
				_ArrayColInsert($aCtrls, 2)
				_ArrayColInsert($aCtrls, 2)
				_ArrayColInsert($aCtrls, 2)
				For $i = 1 To $aCtrls[0][0]
					$hCtrl = $aCtrls[$i][0]
					$sClass = $aCtrls[$i][1]
					If $sClass = 'msctls_progress32' Then
						; Remove WS_EX_STATICEDGE from msctls_progress32 (seems to get added back during each WM_DPICHANGED)
						_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitXOR(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), $WS_EX_STATICEDGE))
						_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
					EndIf
				Next
			EndIf

			$iRet = __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If $iMsg = $WM_DPICHANGED Then Return 0
			Return $iRet

		Case $WM_NOTIFY
			$iRet = __GUIDarkTheme_WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
			If $iRet == "GUI_RUNDEFMSG" Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			Return $iRet

		Case $WM_PARENTNOTIFY
			If _WinAPI_LoWord($wParam) = $WM_CREATE Then
				Local $hChild = HWnd($lParam)
				Local $bEnableDarkTheme = $__DM_g_bUseDarkMode
				_GUIDarkTheme_GUICtrlSetDarkTheme($hWnd, $hChild, $bEnableDarkTheme)
			EndIf
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_DPICHANGED_POSTSCALE
			$iDPI = $wParam
			__DM_ScaleCheckBoxes($hWnd, $iDPI)

	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_WndProc

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: Nine, WildByDesign, argumentum
; ===============================================================================================================================
Func __GUIDarkTheme_WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	Local $hBrush, $tRect, $hPen, $hOldPen, $hOldBr, $hOldBrush, $tTextRect, $hFont, $hOldFont, $iState, $iTextFlags
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	Local $hFrom = $tNMHDR.hWndFrom
	Local $iCode = $tNMHDR.Code
	If $iCode = $NM_CUSTOMDRAW Then
		If Not $__DM_g_bUseDarkMode Then Return $GUI_RUNDEFMSG
		Local $tNMCD = DllStructCreate($__DM_tagNMCUSTOMDRAW, $lParam)
		Local $dwStage = $tNMCD.dwDrawStage
		Local $hDC = $tNMCD.hdc
		Switch _WinAPI_GetClassName($hFrom)
			Case "SysListView32"
				Local $tCustomDraw = DllStructCreate($tagNMLVCUSTOMDRAW, $lParam)

				Local $tHeader, $iGroupID, $bIsCollapsible, $bCollapsed, $iMiddle, $iLabelW, $iAlign, $iHeaderW
				Local $iChevron, $bNoHeader = False
				If $tCustomDraw.dwItemType = $LVCDI_GROUP Then
					If $tCustomDraw.dwDrawStage <> $CDDS_PREPAINT Then Return $GUI_RUNDEFMSG
					$hDC = $tCustomDraw.hDC
					$iGroupID = $tCustomDraw.dwItemSpec
					$iState = _GetListViewGroupState($hFrom, $iGroupID)
					$bIsCollapsible = (BitAND($iState, $LVGS_COLLAPSIBLE) <> 0)
					$bCollapsed = (BitAND($iState, $LVGS_COLLAPSED) <> 0)
					$bNoHeader = (BitAND($iState, $LVGS_NOHEADER) <> 0)
					$iChevron = Round((16 * $__DM_g_iDpiRatio) + (16 / $__DM_g_iDpiRatio))

					If $bNoHeader Then Return $GUI_RUNDEFMSG

					; rcText provides the exact rectangle coordinates needed for LVGGR_HEADER
					$tHeader = DllStructCreate($tagRECT, DllStructGetPtr($tCustomDraw, "TextLeft"))
					Local $iTextLeft = $tCustomDraw.TextLeft
					Local $iTextRight = $tCustomDraw.TextRight

					; Group header width
					$iHeaderW = $iTextRight - $iTextLeft

					; Get group header label rect
					Local Static $tLabelRect = DllStructCreate($tagRECT)
					DllStructSetData($tLabelRect, "Top", $LVGGR_LABEL)
					_SendMessage($hFrom, $LVM_GETGROUPRECT, $iGroupID, DllStructGetPtr($tLabelRect))

					; Group header label width
					$iLabelW = $tLabelRect.right - $tLabelRect.left

					Local $aGroupInfo = _GUICtrlListView_GetGroupInfo($hFrom, $iGroupID)
					Local $sText = $aGroupInfo[0]

					$iAlign = $tCustomDraw.uAlign

					Switch $iAlign
						Case $LVGA_HEADER_LEFT
							; Handle left alignment logic
							$iTextFlags = BitOR($DT_LEFT, $DT_WORDBREAK, $DT_NOCLIP, $DT_SINGLELINE)
						Case $LVGA_HEADER_CENTER
							; Handle center alignment logic
							$iTextFlags = BitOR($DT_CENTER, $DT_WORDBREAK, $DT_NOCLIP, $DT_SINGLELINE)
							$tLabelRect.left = ($iHeaderW / 2) - ($iLabelW / 2) - ($bIsCollapsible ? $iChevron : 0) + 10 + 5
							$tLabelRect.right = ($tLabelRect.left + $iLabelW)
						Case $LVGA_HEADER_RIGHT
							; Handle right alignment logic
							$iTextFlags = BitOR($DT_RIGHT, $DT_WORDBREAK, $DT_NOCLIP, $DT_SINGLELINE)
							$tLabelRect.left = $iHeaderW - $iLabelW - ($bIsCollapsible ? $iChevron : 10)
							$tLabelRect.right = ($tLabelRect.left + $iLabelW)
					EndSwitch

					If $bIsCollapsible Then $tHeader.right = $tHeader.right - $iChevron

					$iMiddle = ($tHeader.bottom - $tHeader.top) / 2

					_WinAPI_SelectObject($hDC, $__DM_g_hPenBtnBor)
					_WinAPI_DrawLine($hDC, $tHeader.left + 10, $tHeader.top + $iMiddle, $tHeader.right - ($bIsCollapsible ? 0 : 10), $tHeader.top + $iMiddle)

					_WinAPI_SetBkColor($hDC, $__DM_g_iCtrlBkColor)
					_WinAPI_SetBkMode($hDC, $OPAQUE)
					_WinAPI_SetTextColor($hDC, 0xFFFFFF)
					_WinAPI_DrawText($hDC, " " & $sText & " ", $tLabelRect, $iTextFlags)
					; Switching back to TRANSPARENT fixes some visual glitches
					_WinAPI_SetBkMode($hDC, $TRANSPARENT)

					If Not $__DM_g_hMDL2Font Then $__DM_g_hMDL2Font = _WinAPI_CreateFont(_PM_PtToPx(8, $hWnd), 0, 0, 0, $FW_NORMAL, False, False, False, $DEFAULT_CHARSET, $OUT_DEFAULT_PRECIS, $CLIP_DEFAULT_PRECIS, $DEFAULT_QUALITY, $DEFAULT_PITCH, "Segoe MDL2 Assets")

					If $bIsCollapsible Then
						$hOldFont = _WinAPI_SelectObject($hDC, $__DM_g_hMDL2Font)
						$tHeader.right = $tHeader.right + 25
						_WinAPI_DrawText($hDC, ChrW($bCollapsed ? 0xE974 : 0xE972), $tHeader, BitOR($DT_RIGHT, $DT_VCENTER, $DT_SINGLELINE))
						_WinAPI_SelectObject($hDC, $hOldFont)
					EndIf
					Return $CDRF_SKIPDEFAULT
				EndIf

			Case "Button"
				Local $sStyles = __GUIDarkTheme_hWnd2Styles($hFrom)
				If StringInStr($sStyles, "SPLITBUTTON") Then
					$tCustomDraw = DllStructCreate($__DM_tagNMCUSTOMDRAW, $lParam)
					Local $iDrawStage = DllStructGetData($tCustomDraw, "dwDrawStage")
					$iState = DllStructGetData($tCustomDraw, "uItemState")
					If $iDrawStage = $CDDS_PREPAINT Then
						; Only override painting if the button is disabled
						If BitAND($iState, $CDIS_DISABLED) Then
							$hDC = DllStructGetData($tCustomDraw, "hdc")
							$tRect = DllStructCreate($tagRECT, DllStructGetPtr($tCustomDraw, "Left"))
							DllStructSetData($tRect, "Left", DllStructGetData($tRect, "Left") + 1)
							DllStructSetData($tRect, "Top", DllStructGetData($tRect, "Top") + 1)
							DllStructSetData($tRect, "Right", DllStructGetData($tRect, "Right") - 1)
							DllStructSetData($tRect, "Bottom", DllStructGetData($tRect, "Bottom") - 1)

							Local $iLeft = DllStructGetData($tRect, "Left")
							Local $iTop = DllStructGetData($tRect, "Top")
							Local $iRight = DllStructGetData($tRect, "Right")
							Local $iBottom = DllStructGetData($tRect, "Bottom")

							Local $iBtnHeight = $iBottom - $iTop

							Local $fScale = __DM_WinAPI_GetDPIForWindow($hWnd) / 96.0
							If @error Then $fScale = 1

							; Paint DPI-scaled rounded background fill and border frame simultaneously
							$hBrush = $__DM_g_hBrushBtnDis
							$hPen = $__DM_g_hPenBtnDis
							$hOldBr = _WinAPI_SelectObject($hDC, $hBrush)
							$hOldPen = _WinAPI_SelectObject($hDC, $hPen)

							_WinAPI_RoundRect($hDC, $tRect, 8, 8)

							_WinAPI_SelectObject($hDC, $hOldPen)
							_WinAPI_SelectObject($hDC, $hOldBr)

							; Use _GUICtrlButton_GetSplitInfo to cleanly determine the dropdown arrow split position under current DPI
							Local $aSplitInfo = _GUICtrlButton_GetSplitInfo($hFrom)
							Local $iSplitX = $iRight - Round(20 * $fScale)

							If IsArray($aSplitInfo) Then
								$iSplitX = $iRight - $aSplitInfo[2]
							EndIf

							; Draw button text inside the main body section
							Local $sButtonText = _GUICtrlButton_GetText($hFrom)
							$hFont = _SendMessage($hFrom, $WM_GETFONT)
							$hOldFont = 0
							If $hFont Then $hOldFont = _WinAPI_SelectObject($hDC, $hFont)

							$tTextRect = DllStructCreate($tagRECT)
							DllStructSetData($tTextRect, "Left", $iLeft + Round(4 * $fScale))
							DllStructSetData($tTextRect, "Top", $iTop)
							DllStructSetData($tTextRect, "Right", $iSplitX - Round(4 * $fScale))
							DllStructSetData($tTextRect, "Bottom", $iBottom)

							_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor(0xCCCCCC))
							_WinAPI_SetBkColor($hDC, _WinAPI_SwitchColor($__DM_g_iBtnBkColorDis))
							_WinAPI_SetBkMode($hDC, $OPAQUE)
							_WinAPI_DrawText($hDC, $sButtonText, $tTextRect, BitOR($DT_CENTER, $DT_SINGLELINE, $DT_VCENTER, $DT_NOCLIP))

							If $hOldFont Then _WinAPI_SelectObject($hDC, $hOldFont)

							; Draw separator line
							Local $hSepPen = $__DM_g_hPenLight
							_WinAPI_SelectObject($hDC, $hSepPen)
							_WinAPI_DrawLine($hDC, $iSplitX, $iTop + 3, $iSplitX, $iBottom - 3)

							; Measurements and positioning for drawing glyph
							$hBrush = $__DM_g_hBrushGlyph
							$hPen = _WinAPI_GetStockObject($NULL_PEN)

							$hOldBrush = _WinAPI_SelectObject($hDC, $hBrush)
							$hOldPen = _WinAPI_SelectObject($hDC, $hPen)

							Local $iGlyphW, $iGlyphH, $iAdjH = 2
							Switch ($fScale * 100)
								Case 100
									$iGlyphW = 9
									$iGlyphH = 5
								Case 125
									$iGlyphW = 11
									$iGlyphH = 6
								Case 150
									$iGlyphW = 15
									$iGlyphH = 8
								Case 175
									$iGlyphW = 17
									$iGlyphH = 9
									$iAdjH = 3
								Case 200
									$iGlyphW = 19
									$iGlyphH = 10
								Case 300
									$iGlyphW = 29
									$iGlyphH = 15
								Case 350
									$iGlyphW = 35
									$iGlyphH = 18
								Case Else
									$iGlyphW = Ceiling($fScale * 9.5)
									$iGlyphH = Ceiling($fScale * 5)
							EndSwitch

							Local $iCenterX = Round(($aSplitInfo[2] - $iGlyphW) / 2)

							; Define the triangle vertices
							Local $aPoints[3][2] = [ _
									[$iSplitX + $iCenterX, (($iBtnHeight - $iGlyphH) / 2) + $iAdjH], _ ; Top-Left (X, Y)
									[$iSplitX + $iCenterX + $iGlyphW, (($iBtnHeight - $iGlyphH) / 2) + $iAdjH], _ ; Top-Right (X, Y)
									[$iSplitX + $iCenterX + ($iGlyphW / 2), (($iBtnHeight - $iGlyphH) / 2) + $iGlyphH + $iAdjH] _ ; Bottom-Center (X, Y)
									]

							; Draw the polygon
							_WinAPI_Polygon($hDC, $aPoints)

							; Clean up GDI handles
							_WinAPI_SelectObject($hDC, $hOldBrush)
							_WinAPI_SelectObject($hDC, $hOldPen)
							_WinAPI_DeleteObject($hPen)

							; Skip default processing for disabled state, letting the theme rule everything else
							Return $CDRF_SKIPDEFAULT

						EndIf
						Return $CDRF_DODEFAULT
					EndIf
				Else
					Return $GUI_RUNDEFMSG ; TODO: remove custom buttons later
					; custom buttons here
					If Not $__DM_g_bCustomButtonsEnable Then Return $GUI_RUNDEFMSG
					$tRect = DllStructCreate($tagRECT, DllStructGetPtr($tNMCD, "left"))
					Switch $tNMCD.dwDrawStage
						Case $CDDS_PREPAINT
							If BitAND($tNMCD.uItemState, $CDIS_HOT) Then
								; set hot button color
								$hPen = $__DM_g_hPenBtnHov
								$hBrush = $__DM_g_hBrushBtnHov
							EndIf
							If BitAND($tNMCD.uItemState, $CDIS_SELECTED) Then
								; set selected button color
								$hPen = $__DM_g_hPenBtnSel
								$hBrush = $__DM_g_hBrushBtnSel
							EndIf
							If BitAND($tNMCD.uItemState, $CDIS_FOCUS) And Not BitAND($tNMCD.uItemState, $CDIS_HOT) Then
								; set focus button color
								$hPen = $__DM_g_hPenBtnFoc
								$hBrush = $__DM_g_hBrushBtnFoc
							EndIf
							If BitAND($tNMCD.uItemState, $CDIS_DISABLED) Then
								; set disabled button color
								$hPen = $__DM_g_hPenBtnDis
								$hBrush = $__DM_g_hBrushBtnDis
							EndIf
							If Not BitAND($tNMCD.uItemState, $CDIS_HOT) And Not BitAND($tNMCD.uItemState, $CDIS_SELECTED) And Not BitAND($tNMCD.uItemState, $CDIS_DISABLED) And Not BitAND($tNMCD.uItemState, $CDIS_FOCUS) Then
								$hPen = $__DM_g_hPenBtnDef
								$hBrush = $__DM_g_hBrushBtnDef
							EndIf
							Local $hObj = _WinAPI_SelectObject($hDC, $hBrush)
							_WinAPI_FillRect($tNMCD.hdc, $tRect, $__DM_g_hBrushGui) ; covers previous button
							$hOldPen = _WinAPI_SelectObject($hDC, $hPen)
							_WinAPI_InflateRect($tRect, -1, -1)
							_WinAPI_RoundRect($hDC, $tRect, $__DM_g_iCustomButtonRadius, $__DM_g_iCustomButtonRadius)
							_WinAPI_SelectObject($hDC, $hObj)
							_WinAPI_SelectObject($hDC, $hOldPen)
							Return $GUI_RUNDEFMSG
					EndSwitch
				EndIf
				;If Not $__DM_g_bCustomButtonsEnable Then Return $GUI_RUNDEFMSG
				;If Not IsString(GUICtrlRead($tNMCD.IDFrom)) Then Return $GUI_RUNDEFMSG
				;Local $sStyles = __GUIDarkTheme_hWnd2Styles($hFrom)
				;If StringInStr($sStyles, "SPLITBUTTON") Then Return $GUI_RUNDEFMSG

			Case "ReBarWindow32"
				Switch $dwStage
					Case $CDDS_PREPAINT
						$hBrush = $__DM_g_hBrushGui
						$tRect = DllStructCreate($tagRECT, DllStructGetPtr($tNMCD, "left"))
						_WinAPI_FillRect($hDC, $tRect, $hBrush)
						Local $iBandCount = _GUICtrlRebar_GetBandCount($hFrom)
						_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
						_WinAPI_SetBkMode($hDC, $TRANSPARENT)
						Local $sBandText, $tBandRect, $iW, $iH, $tGripRect
						$iTextFlags = BitOR($DT_SINGLELINE, $DT_NOCLIP, $DT_VCENTER, $DT_LEFT)

						$hFont = _SendMessage($hFrom, $WM_GETFONT, 0, 0)
						If Not $hFont Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
						$hOldFont = _WinAPI_SelectObject($hDC, $hFont)

						For $i = 0 To $iBandCount - 1
							$sBandText = _GUICtrlRebar_GetBandText($hFrom, $i)
							$tBandRect = _GUICtrlRebar_GetBandRectEx($hFrom, $i)
							$iW = $tBandRect.Right - $tBandRect.Left
							$iH = $tBandRect.Bottom - $tBandRect.Top
							$tTextRect = _WinAPI_CreateRectEx($tBandRect.Left + 10, $tBandRect.Top, $iW, $iH)
							If $sBandText Then _WinAPI_DrawText($hDC, $sBandText, $tTextRect, $iTextFlags)
							$tGripRect = _WinAPI_CreateRectEx($tBandRect.Left + 4, $tBandRect.Top + 2, 2, $iH - 4)
							_WinAPI_FillRect($hDC, $tGripRect, $__DM_g_hBrushBorder)
						Next
						_WinAPI_SelectObject($hDC, $hOldFont)

						Return $CDRF_SKIPDEFAULT

					Case Else
						Return $GUI_RUNDEFMSG
				EndSwitch

				Return $GUI_RUNDEFMSG

			Case "ToolbarWindow32"
				Local $tTool = DllStructCreate($tagNMTBCUSTOMDRAW, $lParam)

				Switch $dwStage
					Case $CDDS_PREPAINT
						$hBrush = $__DM_g_hBrushGui
						$tRect = DllStructCreate($tagRECT, DllStructGetPtr($tTool, "left"))
						_WinAPI_FillRect($tTool.hdc, $tRect, $hBrush)

						Return $CDRF_NOTIFYITEMDRAW

					Case $CDDS_ITEMPREPAINT
						$iState = $tTool.uItemState

						If BitAND($iState, $CDIS_HOT) Then
							$tTool.clrText = $__DM_g_iTextColor
							$tTool.clrTextHighlight = $__DM_g_iTextColor
							$tTool.hbrLines = $__DM_g_hBrushAccent

							$tRect = DllStructCreate($tagRECT, DllStructGetPtr($tTool, "left"))
							$hPen = $__DM_g_hPenBtnBor
							_WinAPI_SelectObject($tTool.hdc, $hPen)
							$hBrush = BitAND($iState, $CDIS_SELECTED) ? $__DM_g_hBrushBtnSel : $__DM_g_hBrushBtnHov
							_WinAPI_SelectObject($tTool.hdc, $hBrush)
							_WinAPI_RoundRect($tTool.hdc, $tRect, 8, 8)

							; clear item state or else this will not work
							$tTool.uItemState = Null

							Return $TBCDRF_USECDCOLORS
						EndIf

						If BitAND($iState, $CDIS_CHECKED) Then
							$tTool.clrText = $__DM_g_iTextColor
							$tTool.clrTextHighlight = $__DM_g_iTextColor
							$tTool.hbrLines = $__DM_g_hBrushAccent

							$tRect = DllStructCreate($tagRECT, DllStructGetPtr($tTool, "left"))
							$hPen = $__DM_g_hPenBtnBor
							_WinAPI_SelectObject($tTool.hdc, $hPen)
							$hBrush = BitAND($iState, $CDIS_SELECTED) ? $__DM_g_hBrushBtnSel : $__DM_g_hBrushBtnHov
							_WinAPI_SelectObject($tTool.hdc, $hBrush)
							_WinAPI_RoundRect($tTool.hdc, $tRect, 8, 8)

							; clear item state or else this will not work
							$tTool.uItemState = Null

							Return $TBCDRF_USECDCOLORS
						EndIf

						If Not BitAND($iState, $CDIS_DISABLED) Then
							$tTool.clrText = $__DM_g_iTextColor
							$tTool.clrTextHighlight = $__DM_g_iTextColor
							$tTool.hbrLines = $__DM_g_hBrushAccent

							Return $TBCDRF_USECDCOLORS
						EndIf
				EndSwitch

			Case "msctls_trackbar32"
				Local $dwItemSpec = $tNMCD.dwItemSpec

				Switch $dwStage
					Case $CDDS_PREPAINT
						; Request item-level notifications so we get TBCD_THUMB and TBCD_CHANNEL
						Return $CDRF_NOTIFYITEMDRAW

					Case $CDDS_ITEMPREPAINT
						; Build a RECT structure pointer using the coordinates provided in NMCUSTOMDRAW
						$tRect = DllStructCreate("struct;long Left;long Top;long Right;long Bottom;endstruct", DllStructGetPtr($tNMCD, "left"))

						Switch $dwItemSpec
							Case $TBCD_THUMB
								Local $iPartID = $TKP_THUMBBOTTOM
								Local $iStyle = _WinAPI_GetWindowLong($hFrom, $GWL_STYLE)
								Select
									Case BitAND($iStyle, $TBS_NOTHUMB)
										Return $CDRF_SKIPDEFAULT
									Case BitAND($iStyle, $TBS_VERT)
										Select
											Case BitAND($iStyle, $TBS_RIGHT)
												$iPartID = $TKP_THUMBRIGHT
											Case BitAND($iStyle, $TBS_LEFT)
												$iPartID = $TKP_THUMBLEFT
											Case BitAND($iStyle, $TBS_BOTH)
												$iPartID = $TKP_THUMBVERT
											Case Else
												$iPartID = $TKP_THUMBRIGHT
										EndSelect
									Case BitAND($iStyle, $TBS_TOP)
										$iPartID = $TKP_THUMBTOP
									Case BitAND($iStyle, $TBS_BOTH)
										$iPartID = $TKP_THUMB
									Case BitAND($iStyle, $TBS_BOTTOM)
										$iPartID = $TKP_THUMBBOTTOM
									Case Else
										$iPartID = $TKP_THUMBBOTTOM
								EndSelect

								$iState = $TUS_NORMAL
								If BitAND($tNMCD.uItemState, $CDIS_SELECTED) Then $iState = $TUS_NORMAL

								Local $iCtrlState = WinGetState($hFrom)
								If Not BitAND($iCtrlState, $WIN_STATE_ENABLED) Then $iState = $TUS_DISABLED

								Local $iL = $tNMCD.left
								Local $iT = $tNMCD.top
								Local $iR = $tNMCD.right - 1
								Local $iB = $tNMCD.bottom - 1
								Local $tPt = DllStructCreate($tagPOINT)
								DllCall('user32.dll', "bool", "GetCursorPos", "struct*", $tPt)
								_WinAPI_ScreenToClient($hFrom, $tPt)
								Local $bHot = ($tPt.X >= $iL And $tPt.X <= $iR And $tPt.Y >= $iT And $tPt.Y <= $iB)

								Local $bIsHoveredHot = False
								If $bHot And Not BitAND($tNMCD.uItemState, $CDIS_SELECTED) Then
									$bIsHoveredHot = True
								EndIf

								; Initiate double buffering
								Local $iWidth = $tRect.Right - $tRect.Left
								Local $iHeight = $tRect.Bottom - $tRect.Top

								If $iWidth > 0 And $iHeight > 0 Then
									Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
									Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
									Local $hOldBitmap = _WinAPI_SelectObject($hMemDC, $hBitmap)

									; Copy existing screen background into buffer to prevent black artifacts
									_WinAPI_BitBlt($hMemDC, 0, 0, $iWidth, $iHeight, $hDC, $tRect.Left, $tRect.Top, $SRCCOPY)

									Local $tMemRect = DllStructCreate("struct;long Left;long Top;long Right;long Bottom;endstruct")
									$tMemRect.Left = 0
									$tMemRect.Top = 0
									$tMemRect.Right = $iWidth
									$tMemRect.Bottom = $iHeight

									If Not $__DM_g_hThemeTrackbar Then $__DM_g_hThemeTrackbar = _WinAPI_OpenThemeData($hWnd, "TRACKBAR")

									; Draw thumb with uxtheme
									If $__DM_g_hThemeTrackbar Then _WinAPI_DrawThemeBackground($__DM_g_hThemeTrackbar, $iPartID, $iState, $hMemDC, $tMemRect)

									; If hovered, alpha-blend a lighter colored thumb to make initial thumb brighter
									If $bIsHoveredHot Then
										Local $hHighlightDC = _WinAPI_CreateCompatibleDC($hDC)
										Local $hHighlightBmp = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
										Local $hOldHighlightBmp = _WinAPI_SelectObject($hHighlightDC, $hHighlightBmp)

										; Draw thumb with uxtheme using a lighter theme resource to blend
										If $__DM_g_hThemeTrackbar Then _WinAPI_DrawThemeBackground($__DM_g_hThemeTrackbar, $iPartID, $TUS_PRESSED, $hHighlightDC, $tMemRect)

										; Alpha blend the entire highlight state buffer over the normal buffer
										_WinAPI_AlphaBlend($hMemDC, 0, 0, $iWidth, $iHeight, $hHighlightDC, 0, 0, $iWidth, $iHeight, 80, True)

										_WinAPI_SelectObject($hHighlightDC, $hOldHighlightBmp)
										_WinAPI_DeleteObject($hHighlightBmp)
										_WinAPI_DeleteDC($hHighlightDC)
									EndIf

									; Copy memory DC to screen DC
									_WinAPI_BitBlt($hDC, $tRect.Left, $tRect.Top, $iWidth, $iHeight, $hMemDC, 0, 0, $SRCCOPY)

									_WinAPI_SelectObject($hMemDC, $hOldBitmap)
									_WinAPI_DeleteObject($hBitmap)
									_WinAPI_DeleteDC($hMemDC)
								EndIf

								Return $CDRF_SKIPDEFAULT

							Case $TBCD_CHANNEL
								Local $tChannelRect = _WinAPI_CreateRect($tNMCD.left, $tNMCD.top, $tNMCD.right, $tNMCD.bottom)
								_WinAPI_FillRect($hDC, $tChannelRect, $__DM_g_hBrushGray)
								Return $CDRF_SKIPDEFAULT

							Case $TBCD_TICS
								Return $CDRF_DODEFAULT
						EndSwitch
				EndSwitch
		EndSwitch
	ElseIf $iCode = $RBN_MINMAX Then
		If _WinAPI_GetClassName($hFrom) <> "ReBarWindow32" Then Return $GUI_RUNDEFMSG
		; Return 1 here is a temporary fix to prevent a crash with Rebar subclassing on this specific message
		Return 1
	Else
		If _WinAPI_GetClassName($hFrom) = "SysDateTimePick32" Then
			If Not $__DM_g_bUseDarkMode Then Return $GUI_RUNDEFMSG
			Switch $iCode
				Case $DTN_DROPDOWN
					; Remove theme from SysMonthCal32
					Local $hMonthCal = _GUICtrlDTP_GetMonthCal($hFrom)
					Local $iCalPad
					Switch Int($__DM_g_iDpiRatio * 100)
						Case 100
							$iCalPad = 14
						Case 125
							$iCalPad = 12
						Case 150
							$iCalPad = 10
						Case 175
							$iCalPad = 8
						Case 200
							$iCalPad = 8
						Case Else
							$iCalPad = 8
					EndSwitch
					Local $iCalPadW = $iCalPad * $__DM_g_iDpiRatio
					Local $iCalPadH = $iCalPad * $__DM_g_iDpiRatio
					_WinAPI_SetWindowTheme($hMonthCal, "", "")
					_SendMessage($hMonthCal, $WM_THEMECHANGED, 0, 0)

					; the parent of floating SysMonthCal32 is a DropDown class window container
					Local $hCalParent = _WinAPI_GetParent($hMonthCal)

					; add WS_BORDER
					_WinAPI_SetWindowLong($hMonthCal, $GWL_STYLE, BitOR(_WinAPI_GetWindowLong($hMonthCal, $GWL_STYLE), $WS_BORDER))
					_WinAPI_SetWindowPos($hMonthCal, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

					Local $iCalW = _GUICtrlMonthCal_GetMinReqWidth($hMonthCal)
					Local $iCalH = _GUICtrlMonthCal_GetMinReqHeight($hMonthCal)

					; resize DropDown window for padding (this frames the SysMonthCal32 window)
					If $hCalParent Then
						Local $aPos = WinGetPos($hCalParent)
						If IsArray($aPos) Then
							Local $iFlags = BitOR($SWP_NOMOVE, $SWP_NOZORDER, $SWP_NOACTIVATE, $SWP_NOOWNERZORDER)
							_WinAPI_SetWindowPos($hCalParent, 0, $aPos[0], $aPos[1], $iCalW + $iCalPadW, $iCalH + $iCalPadH, $iFlags)
						EndIf
					EndIf

					; set timer to capture SysShadow handle which is created yet
					AdlibRegister("__DM_CalendarTimer", 5)

				Case $DTN_CLOSEUP
					; kill timer
					AdlibUnRegister("__DM_CalendarTimer")
			EndSwitch
		EndIf
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>__GUIDarkTheme_WM_NOTIFY

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __DM_CalendarTimer()
	Local $hSysShadow = 0
	$hSysShadow = _WinAPI_FindChildByClass(Null, "SysShadow")

	If Not $hSysShadow Then
		$__DM_g_iTimerCycles += 1
		If $__DM_g_iTimerCycles <= 10 Then Return 0 ; shadow not showing yet
		; Else user likely has "Show shadows under windows" disabled, no need to keep trying
	EndIf

	; Find SysMonthCal32 to apply delayed theme removal in case of initial timing issue
	Local $aWindows = _WinAPI_EnumWindows(True)
	If @error = 0 Then
		For $i = 1 To $aWindows[0][0]
			If $aWindows[$i][1] = "SysMonthCal32" Then
				; Remove theme from SysMonthCal32
				_WinAPI_SetWindowTheme($aWindows[$i][0], "", "")
				_SendMessage($aWindows[$i][0], $WM_THEMECHANGED, 0, 0)
			EndIf
		Next
	EndIf

	$__DM_g_iTimerCycles = 0

	If $hSysShadow Then
		; Move SysShadow to align with calendar dropdown
		Local $aPos = WinGetPos($hSysShadow)
		If IsArray($aPos) Then WinMove($hSysShadow, "", $aPos[0] - 3, $aPos[1] - 3, $aPos[2], $aPos[3])
	EndIf

	AdlibUnRegister("__DM_CalendarTimer")

	Return 0
EndFunc   ;==>__DM_CalendarTimer

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func _WinAPI_GetWindowRectAsArray($hWnd)
	Local $tRect = _WinAPI_GetWindowRect($hWnd)
	If @error Then
		Local $aError[4] = [0, 0, 0, 0]
		Return SetError(@error, @extended, $aError)
	EndIf

	; Extract the struct data into a standard AutoIt array and return it
	Local $aRect[4] = [DllStructGetData($tRect, "Left"), DllStructGetData($tRect, "Top"), DllStructGetData($tRect, "Right"), DllStructGetData($tRect, "Bottom")]
	Return $aRect
EndFunc   ;==>_WinAPI_GetWindowRectAsArray

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func __GUIDarkTheme_hWnd2Styles($hWnd)
	Return __GUIDarkTheme_GetCtrlStyleString(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE), _WinAPI_GetClassName($hWnd))
EndFunc   ;==>__GUIDarkTheme_hWnd2Styles

; #FUNCTION# ====================================================================================================================
; Author.........: Yashied
; Modified ......: pixelsearch, SmOke_N
; ===============================================================================================================================
Func __GUIDarkTheme_GetStyleString($iStyle, $fExStyle)
	Local $Text = '', $Data = $fExStyle ? $__DM_g_Style_GuiExtended : $__DM_g_Style_Gui

	For $i = 0 To UBound($Data) - 1
		If BitAND($iStyle, $Data[$i][0]) = $Data[$i][0] Then
			$iStyle = BitAND($iStyle, BitNOT($Data[$i][0]))
			If StringLeft($Data[$i][1], 1) <> "!" Then
				$Text &= $Data[$i][1] & ', '
			Else
				; ex. '! WS_MINIMIZEBOX ! WS_GROUP'  =>  'WS_MINIMIZEBOX, '
				$Text &= StringMid($Data[$i][1], 3, StringInStr($Data[$i][1], "!", 2, 2) - 4) & ', '
			EndIf
		EndIf
	Next

	If $iStyle Then $Text = '0x' & Hex($iStyle, 8) & ', ' & $Text

	Return StringRegExpReplace($Text, ',\s\z', '')
EndFunc   ;==>__GUIDarkTheme_GetStyleString

; #FUNCTION# ====================================================================================================================
; Author.........: Yashied
; Modified ......: pixelsearch, SmOke_N
; ===============================================================================================================================
Func __GUIDarkTheme_GetCtrlStyleString($iStyle, $fExStyle, $sClass, $iLVExStyle = 0)

	If $sClass = "AutoIt v3 GUI" Or $sClass = "#32770" Or $sClass = "MDIClient" Then ; control = child GUI, dialog box (msgbox) etc...
		Return __GUIDarkTheme_GetStyleString($iStyle, 0)
	EndIf

	If StringLeft($sClass, 8) = "RichEdit" Then $sClass = "RichEdit" ; RichEdit, RichEdit20A, RichEdit20W, RichEdit50A, RichEdit50W

	Local $Text = ''

	__GUIDarkTheme_GetCtrlStyleString2($iStyle, $Text, $sClass, $iLVExStyle) ; 4th param. in case $sClass = "Ex_SysListView32" (special treatment)

	If $sClass = "ReBarWindow32" Or $sClass = "ToolbarWindow32" Or $sClass = "msctls_statusbar32" Then
		$sClass = "Common" ; "for rebar controls, toolbar controls, and status windows" (msdn)
		__GUIDarkTheme_GetCtrlStyleString2($iStyle, $Text, $sClass)
	ElseIf $sClass = "RichEdit" Then
		$sClass = "Edit" ; "Richedit controls also support many edit control styles (not all)" (msdn)
		__GUIDarkTheme_GetCtrlStyleString2($iStyle, $Text, $sClass)
	EndIf

	Local $Data = $fExStyle ? $__DM_g_Style_GuiExtended : $__DM_g_Style_Gui

	For $i = 0 To UBound($Data) - 1
		If BitAND($iStyle, $Data[$i][0]) = $Data[$i][0] Then
			If (Not BitAND($Data[$i][0], 0xFFFF)) Or ($fExStyle) Then
				$iStyle = BitAND($iStyle, BitNOT($Data[$i][0]))
				If StringLeft($Data[$i][1], 1) <> "!" Then
					$Text &= $Data[$i][1] & ', '
				Else
					; ex. '! WS_MINIMIZEBOX ! WS_GROUP'  =>  'WS_GROUP, '
					$Text &= StringMid($Data[$i][1], StringInStr($Data[$i][1], "!", 2, 2) + 2) & ', '
				EndIf
			EndIf
		EndIf
	Next

	If $iStyle Then $Text = '0x' & Hex($iStyle, 8) & ', ' & $Text

	Return StringRegExpReplace($Text, ',\s\z', '')
EndFunc   ;==>__GUIDarkTheme_GetCtrlStyleString

; #FUNCTION# ====================================================================================================================
; Author.........: Yashied
; Modified ......: pixelsearch, SmOke_N
; ===============================================================================================================================
Func __GUIDarkTheme_GetCtrlStyleString2(ByRef $iStyle, ByRef $Text, $sClass, $iLVExStyle = 0)

	Local $Data

	Switch $sClass  ; $Input[16]
		Case "Button"
			$Data = $__DM_g_Style_Button
		Case "ComboBox", "ComboBoxEx32"
			$Data = $__DM_g_Style_Combo
		Case "Common"
			$Data = $__DM_g_Style_Common ; "for rebar controls, toolbar controls, and status windows (msdn)"
		Case "Edit"
			$Data = $__DM_g_Style_Edit
		Case "ListBox"
			$Data = $__DM_g_Style_ListBox
		Case "msctls_progress32"
			$Data = $__DM_g_Style_Progress
		Case "msctls_statusbar32"
			$Data = $__DM_g_Style_StatusBar
		Case "msctls_trackbar32"
			$Data = $__DM_g_Style_Slider
		Case "msctls_updown32"
			$Data = $__DM_g_Style_UpDown
		Case "ReBarWindow32"
			$Data = $__DM_g_Style_Rebar
		Case "RichEdit"
			$Data = $__DM_g_Style_RichEdit
		Case "Scrollbar"
			$Data = $__DM_g_Style_Scrollbar
		Case "Static"
			$Data = $__DM_g_Style_Static
		Case "SysAnimate32"
			$Data = $__DM_g_Style_Avi
		Case "SysDateTimePick32"
			$Data = $__DM_g_Style_DateTime
		Case "SysHeader32"
			$Data = $__DM_g_Style_Header
		Case "SysListView32"
			$Data = $__DM_g_Style_ListView
		Case "Ex_SysListView32" ; special treatment below
			$Data = $__DM_g_Style_ListViewExtended
		Case "SysMonthCal32"
			$Data = $__DM_g_Style_MonthCal
		Case "SysPager"
			$Data = $__DM_g_Style_Pager
		Case "SysTabControl32", "SciTeTabCtrl"
			$Data = $__DM_g_Style_Tab
		Case "SysTreeView32"
			$Data = $__DM_g_Style_TreeView
		Case "ToolbarWindow32"
			$Data = $__DM_g_Style_Toolbar
		Case Else
			Return
	EndSwitch

	If $sClass <> "Ex_SysListView32" Then
		For $i = 0 To UBound($Data) - 1
			If BitAND($iStyle, $Data[$i][0]) = $Data[$i][0] Then
				$iStyle = BitAND($iStyle, BitNOT($Data[$i][0]))
				$Text = $Data[$i][1] & ', ' & $Text
			EndIf
		Next
	Else
		For $i = 0 To UBound($Data) - 1
			If BitAND($iLVExStyle, $Data[$i][0]) = $Data[$i][0] Then
				$iLVExStyle = BitAND($iLVExStyle, BitNOT($Data[$i][0]))
				$Text = $Data[$i][1] & ', ' & $Text
				If BitAND($iStyle, $Data[$i][0]) = $Data[$i][0] Then
					$iStyle = BitAND($iStyle, BitNOT($Data[$i][0]))
				EndIf
			EndIf
		Next
		If $iLVExStyle Then $Text = 'LVex: 0x' & Hex($iLVExStyle, 8) & ', ' & $Text
		; next test bc LVS_EX_FULLROWSELECT (default AutoIt LV ext style) and WS_EX_TRANSPARENT got both same value 0x20 (hard to solve in some cases)
		If BitAND($iStyle, $WS_EX_TRANSPARENT) = $WS_EX_TRANSPARENT Then ; note that $WS_EX_TRANSPARENT has nothing to do with listview
			$iStyle = BitAND($iStyle, BitNOT($WS_EX_TRANSPARENT))
		EndIf
	EndIf
EndFunc   ;==>__GUIDarkTheme_GetCtrlStyleString2

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_GUISetDarkTheme
; Description ...: Sets the theme for a specified window to either dark or light mode on Windows 10/11.
; Syntax ........: _GUIDarkTheme_GUISetDarkTheme($hGui, $bEnableDarkTheme = True)
; Parameters ....: $hGui          		- The handle to the window.
;				   $bEnableDarkTheme	- If True, sets dark theme. If False, sets light theme. Default is True.
; Return values .: None
; Author ........: DK12000, NoNameCode
; Modified ......: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_GUISetDarkTheme($hGui, $bEnableDarkTheme = Default)
	Local Const $DWMWA_USE_IMMERSIVE_DARK_MODE = 20
	If $bEnableDarkTheme = Default Then $bEnableDarkTheme = True
	Local $iPreferredAppMode = ($bEnableDarkTheme == True) ? $APPMODE_FORCEDARK : $APPMODE_FORCELIGHT
	$__DM_g_iTimerCycles = 0
	; get window DPI for measurement adjustments
	$__DM_g_iDpiRatio = Round(__DM_WinAPI_GetDPIForWindow($hGui) / 96, 2)
	If @error Then $__DM_g_iDpiRatio = 1
	$__DM_g_iDpi = Round(__DM_WinAPI_GetDPIForWindow($hGui) / 96, 2) * 100
	If @error Then $__DM_g_iDpi = 100
	_WinAPI_SetPreferredAppMode($iPreferredAppMode)
	_WinAPI_RefreshImmersiveColorPolicyState()
	_WinAPI_FlushMenuThemes()
	_GUIDarkTheme_GUICtrlSetDarkTheme($hGui, $bEnableDarkTheme)
	_WinAPI_DwmSetWindowAttribute($hGui, $DWMWA_USE_IMMERSIVE_DARK_MODE, $bEnableDarkTheme)
	$__DM_g_bUseDarkMode = _WinAPI_ShouldAppsUseDarkMode()
	; reset dark mode and light mode colors
	$__DM_g_iStatusBkColor = $__DM_g_bUseDarkMode ? $__DM_g_iStatusBkColorDark : $__DM_g_iStatusBkColorLight
	$__DM_g_iGuiBkColor = $__DM_g_bUseDarkMode ? $__DM_g_iGuiBkColorDark : $__DM_g_iGuiBkColorLight
	$__DM_g_iTextColor = $__DM_g_bUseDarkMode ? $__DM_g_iTextColorDark : $__DM_g_iTextColorLight
	$__DM_g_iCtrlBkColor = $__DM_g_bUseDarkMode ? $__DM_g_iCtrlBkColorDark : $__DM_g_iCtrlBkColorLight
	$__DM_g_iBorderColor = $__DM_g_bUseDarkMode ? $__DM_g_iBorderColorDark : $__DM_g_iBorderColorLight
	$__DM_g_iSizeboxPaint = $__DM_g_bUseDarkMode ? $__DM_g_iSizeboxPaintDark : $__DM_g_iSizeboxPaintLight
	$__DM_g_iMenuBkColor = $__DM_g_bUseDarkMode ? $__DM_g_iMenuBkColorDark : $__DM_g_iMenuBkColorLight
	$__DM_g_iMenuHotColor = $__DM_g_bUseDarkMode ? $__DM_g_iMenuHotColorDark : $__DM_g_iMenuHotColorLight
	$__DM_g_iMenuSelColor = $__DM_g_bUseDarkMode ? $__DM_g_iMenuSelColorDark : $__DM_g_iMenuSelColorLight
	$__DM_g_iMenuTextColor = $__DM_g_bUseDarkMode ? $__DM_g_iMenuTextColorDark : $__DM_g_iMenuTextColorLight
	$__DM_g_iBtnBkColorDef = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBkColorDefDark : $__DM_g_iBtnBkColorDefLight
	$__DM_g_iBtnBkColorHov = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBkColorHovDark : $__DM_g_iBtnBkColorHovLight
	$__DM_g_iBtnBkColorSel = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBkColorSelDark : $__DM_g_iBtnBkColorSelLight
	$__DM_g_iBtnBkColorFoc = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBkColorFocDark : $__DM_g_iBtnBkColorFocLight
	$__DM_g_iBtnBkColorDis = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBkColorDisDark : $__DM_g_iBtnBkColorDisLight
	$__DM_g_iBtnBorderDef = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBorderDefDark : $__DM_g_iBtnBorderDefLight
	$__DM_g_iBtnBorderHov = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBorderHovDark : $__DM_g_iBtnBorderHovLight
	$__DM_g_iBtnBorderSel = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBorderSelDark : $__DM_g_iBtnBorderSelLight
	$__DM_g_iBtnBorderFoc = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBorderFocDark : $__DM_g_iBtnBorderFocLight
	$__DM_g_iBtnBorderDis = $__DM_g_bUseDarkMode ? $__DM_g_iBtnBorderDisDark : $__DM_g_iBtnBorderDisLight
	$__DM_g_iTabColor = $__DM_g_bUseDarkMode ? $__DM_g_iTabColorDark : $__DM_g_iTabColorLight
	$__DM_g_iExtraGray = $__DM_g_bUseDarkMode ? $__DM_g_iExtraGrayDark : $__DM_g_iExtraGrayLight

	; create brushes and pens
	__GUIDarkTheme_CreateBrushes()
	__GUIDarkTheme_CreatePens()

	Local $iGUI_BkColor = $__DM_g_iGuiBkColor
	GUISetBkColor($iGUI_BkColor, $hGui)
	Local $hMenu = _GUICtrlMenu_GetMenu($hGui)
	If $hMenu Then __GUIDarkMenu_MenuBarBKColor($hMenu)

	; Register GUI-level window messages
	GUIRegisterMsg($WM_CTLCOLORLISTBOX, "__GUIDarkTheme_WM_CTLCOLOR")
	GUIRegisterMsg($WM_CTLCOLOREDIT, "__GUIDarkTheme_WM_CTLCOLOR")
	GUIRegisterMsg($WM_CTLCOLORSTATIC, "__GUIDarkTheme_WM_CTLCOLOR")

	;Create WM_NOTIFY window procedure
	If Not $__DM_g_hWndProc Then
		$__DM_g_hWndProc = DllCallbackRegister(__GUIDarkTheme_WndProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
		$__DM_g_pWndProc = DllCallbackGetPtr($__DM_g_hWndProc)
	EndIf
	_WinAPI_SetWindowSubclass($hGui, $__DM_g_pWndProc, $hGui, $__DM_g_hWndProc)

	; Subclass individual controls
	If Not $__DM_g_hSubclassProc Then
		$__DM_g_hSubclassProc = DllCallbackRegister(__GUIDarkTheme_SubclassProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
		$__DM_g_pSubclassProc = DllCallbackGetPtr($__DM_g_hSubclassProc)
	EndIf

	; Set titlebar color to match GUI color
	If @OSBuild >= 22000 And Not $__DM_g_bMicaEnabled Then _WinAPI_DwmSetWindowAttribute($hGui, $DWMWA_CAPTION_COLOR, _WinAPI_SwitchColor($__DM_g_iGuiBkColor))
	If $__DM_g_bMicaEnabled Then
		;_WinAPI_DwmSetWindowAttribute($hGui, $DWMWA_CAPTION_COLOR, 0xFFFFFFFF)
		;_WinAPI_SetWindowPos($hGui, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
		;_WinAPI_DwmSetWindowAttribute($hGui, $DWMWA_USE_IMMERSIVE_DARK_MODE, $bEnableDarkTheme)
		;__DM_WinAPI_DwmSetWindowAttribute($hGui, $DWM_SYSTEMBACKDROP_TYPE, $DWMSBT_MAINWINDOW)
		;__DM_WinAPI_DwmSetWindowAttribute($hGui, $DWM_SYSTEMBACKDROP_TYPE, $DWMSBT_MAINWINDOW)
		;_WinAPI_DwmExtendFrameIntoClientArea($hGui, _WinAPI_CreateMargins(-1, -1, -1, -1))
	EndIf
EndFunc   ;==>_GUIDarkTheme_GUISetDarkTheme

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_GUICtrlAllSetDarkTheme
; Description ...: Sets the dark theme to all existing sub Controls from a GUI
; Syntax ........: _GUIDarkTheme_GUICtrlAllSetDarkTheme($hGui[, $bEnableDarkTheme = True)
; Parameters ....: $hGui                - GUI handle
;                  $bEnableDarkTheme    - [optional] a boolean value. Default is True.
; Return values .: None
; Author ........: NoName
; Modified ......: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_GUICtrlAllSetDarkTheme($hGui, $bEnableDarkTheme = Default)
	If $bEnableDarkTheme = Default Then $bEnableDarkTheme = True
	Local $aCtrls = _WinAPI_EnumChildWindows($hGui, False)
	If @error = 0 Then
		For $i = 1 To $aCtrls[0][0]
			_GUIDarkTheme_GUICtrlSetDarkTheme($hGui, $aCtrls[$i][0], $bEnableDarkTheme)
			;ConsoleWrite("EnumChildWindows: " & @TAB & @TAB & "Handle: " & $aCtrls[$i][0] & " : " & "Class: " & $aCtrls[$i][1] & @CRLF)
		Next
	EndIf

	Local $aCtrlsEx = _WinAPI_EnumProcessWindows(0, False) ; allows getting handles for tooltips_class32, ComboLBox, etc.
	If @error = 0 Then
		For $i = 1 To $aCtrlsEx[0][0]
			If $aCtrlsEx[$i][1] = 'tooltips_class32' Then _GUIDarkTheme_GUICtrlSetDarkTheme($hGui, $aCtrlsEx[$i][0], $bEnableDarkTheme)
		Next
	EndIf

	Return $aCtrls
EndFunc   ;==>_GUIDarkTheme_GUICtrlAllSetDarkTheme

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_GUICtrlSetDarkTheme
; Description ...: Sets the dark theme for a specified control.
; Syntax ........: _GUIDarkTheme_GUICtrlSetDarkTheme($hGui, $hCtrl, $bEnableDarkTheme = True)
; Parameters ....: $hGui             - The GUI handle.
;                  $hCtrl            - The control handle.
;                  $bEnableDarkTheme - If True, enables the dark theme; if False, disables it.
;                                      (Default is True for enabling dark theme.)
; Return values .: Success: True
;                  Failure: False and sets the @error flag:
;                           1: Invalid control handle.
;                           2: Error while allowing dark mode for the window.
;                           3: Error while setting the window theme.
;                           4: Error while sending the WM_THEMECHANGED message.
; Author ........: NoNameCode
; Modified ......: WildByDesign
; Remarks .......: This function requires the _WinAPI_SetWindowTheme and __DM_WinAPI_AllowDarkModeForWindow functions.
; Example .......: Yes
; ===============================================================================================================================
Func _GUIDarkTheme_GUICtrlSetDarkTheme($hGui, $hCtrl, $bEnableDarkTheme = Default)
	If $bEnableDarkTheme = Default Then $bEnableDarkTheme = True
	Local $sThemeName = Null, $sThemeList = Null
	Local $iGUI_Ctrl_Color = $__DM_g_iTextColor
	Local $iGUI_Ctrl_BkColor = $__DM_g_iCtrlBkColor
	Local $bSpecialLV = False, $bSpecialTV = False
	Local $sStyles, $iBkColor
	If Not IsHWnd($hCtrl) Then $hCtrl = GUICtrlGetHandle($hCtrl)
	If Not IsHWnd($hCtrl) Then Return SetError(1, 0, False)
	_WinAPI_AllowDarkModeForWindow($hCtrl, $bEnableDarkTheme)
	If @error <> 0 Then Return SetError(2, @error, False)
	;=========
	;ConsoleWrite(@CRLF & _WinAPI_GetClassName($hCtrl))
	Switch _WinAPI_GetClassName($hCtrl)
		Case 'Button'
			$sStyles = __GUIDarkTheme_hWnd2Styles($hCtrl)
			Local $bSubclassButton = False
			Local $bSubclassGroup = False
			If StringInStr($sStyles, "BS_AUTORADIOBUTTON") Or StringInStr($sStyles, "CHECKBOX") Or StringInStr($sStyles, "BS_AUTO3STATE") Then
				; Subclass checkbox and radio buttons only when run older OS
				If Not $__DM_g_b24H2Plus Then $bSubclassButton = True
			EndIf
			If StringInStr($sStyles, "BS_GROUPBOX") Then
				; Subclass groupbox and when run older OS
				If Not $__DM_g_b24H2Plus Then $bSubclassGroup = True
			EndIf

			Switch $bEnableDarkTheme
				Case True
					If $bSubclassGroup Then
						If Not $__DM_g_hGroupProc Then
							$__DM_g_hGroupProc = DllCallbackRegister(__GUIDarkTheme_GroupProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
							$__DM_g_pGroupProc = DllCallbackGetPtr($__DM_g_hGroupProc)
						EndIf
						_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer", "Button")
						_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
						_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pGroupProc, $hCtrl, $__DM_g_hGroupProc)

						Return True
					EndIf

					If $bSubclassButton Then
						If Not $__DM_g_hButtonProc Then
							$__DM_g_hButtonProc = DllCallbackRegister(__GUIDarkTheme_ButtonProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
							$__DM_g_pButtonProc = DllCallbackGetPtr($__DM_g_hButtonProc)
						EndIf
						_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer", "Button")
						_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
						_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pButtonProc, $hCtrl, $__DM_g_hButtonProc)

						Return True
					EndIf

					$sThemeName = 'DarkMode_Explorer'

					If StringInStr($sStyles, "BS_GROUPBOX") Or StringInStr($sStyles, "BS_AUTORADIOBUTTON") Then
						If Not $__DM_g_b24H2Plus Then _WinAPI_SetWindowTheme($hCtrl, "", "")
						$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer'
						GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
						GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $__DM_g_iGuiBkColor)
						_SendMessage($hCtrl, $WM_CHANGEUISTATE, 65537, 0)
						If Not $__DM_g_b24H2Plus Then Return True
					Else
						If StringInStr($sStyles, "CHECKBOX") Then
							GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $__DM_g_iGuiBkColor)
						EndIf
					EndIf
				Case False
					$sThemeName = 'Explorer'
					If StringInStr($sStyles, "BS_GROUPBOX") Or StringInStr($sStyles, "BS_AUTORADIOBUTTON") Then
						GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
						GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $__DM_g_iGuiBkColor)
					Else
						If StringInStr($sStyles, "CHECKBOX") Then
							GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $__DM_g_iGuiBkColor)
						EndIf
					EndIf
			EndSwitch

		Case 'ReBarWindow32'
			_WinAPI_SetWindowTheme($hCtrl, "", "")
			_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
			_GUICtrlRebar_SetColorScheme($hCtrl, $__DM_g_iGuiBkColor, $__DM_g_iGuiBkColor)
			For $i = 0 To _GUICtrlRebar_GetBandCount($hCtrl) - 1
				__GUIDarkTheme_SetBandColor($hCtrl, $i, $__DM_g_iGuiBkColor, $iGUI_Ctrl_Color)
			Next

			; Set default GUI font
			;_SendMessage($hCtrl, $WM_SETFONT, _WinAPI_GetStockObject($DEFAULT_GUI_FONT), True)

			; Style fixes to improve theme design
			_WinAPI_SetWindowLong($hCtrl, $GWL_STYLE, BitOR(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $CCS_NODIVIDER))
			_WinAPI_SetWindowLong($hCtrl, $GWL_STYLE, BitXOR(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $RBS_BANDBORDERS))
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, $SWP_NOMOVE)
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pSubclassProc, $hCtrl, $__DM_g_hSubclassProc)

			Return True

		Case 'ToolbarWindow32'
			If _GUICtrlToolbar_GetStyleFlat($hCtrl) And _GUICtrlToolbar_GetStyleTransparent($hCtrl) Then
				; remove the transparent bit in the case of default AutoIt created toolbar (transparent should not be default)
				_GUICtrlToolbar_SetStyleTransparent($hCtrl, False)
				_GUICtrlToolbar_SetStyleFlat($hCtrl, False)
			EndIf
			If _GUICtrlToolbar_GetStyleTransparent($hCtrl) Then
				_GUICtrlToolbar_SetColorScheme($hCtrl, $__DM_g_iGuiBkColor, $__DM_g_iGuiBkColor)
			Else
				;_GUICtrlToolbar_SetColorScheme($hCtrl, $iGUI_Ctrl_BkColor, $iGUI_Ctrl_BkColor)
				_GUICtrlToolbar_SetColorScheme($hCtrl, $__DM_g_iGuiBkColor, $__DM_g_iGuiBkColor)
			EndIf

			Switch $bEnableDarkTheme
				Case True
					_WinAPI_SetWindowTheme($hCtrl, "DarkMode", "Toolbar")
					_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
				Case False
					_WinAPI_SetWindowTheme($hCtrl, "Explorer")
					_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
			EndSwitch

			Return True

		Case 'SysIPAddress32'
			; Remove WS_EX_CLIENTEDGE from control
			_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			If Not $__DM_g_hIpAddrProc Then
				$__DM_g_hIpAddrProc = DllCallbackRegister(__GUIDarkTheme_IPAddrProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
				$__DM_g_pIpAddrProc = DllCallbackGetPtr($__DM_g_hIpAddrProc)
			EndIf
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pIpAddrProc, $hCtrl, $__DM_g_hIpAddrProc)

			; subclass child Edit boxes so that we can use WM_NCCALCSIZE
			Local $hChild = _WinAPI_GetWindow($hCtrl, $GW_CHILD)
			Local $iCount = 0

			While $hChild And $iCount < 4
				_WinAPI_SetWindowSubclass($hChild, $__DM_g_pIpAddrProc, $hChild, $__DM_g_hIpAddrProc)
				; SetWindowPos with SWP_FRAMECHANGED ensures that WM_NCCALCSIZE gets triggered
				_WinAPI_SetWindowPos($hChild, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
				$hChild = _WinAPI_GetWindow($hChild, $GW_HWNDNEXT)
				$iCount += 1
			WEnd

			Return True

		Case 'msctls_hotkey32'
			; Remove WS_EX_CLIENTEDGE from control
			_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			; Set default GUI font
			;_SendMessage($hCtrl, $WM_SETFONT, _WinAPI_GetStockObject($DEFAULT_GUI_FONT), True)

			If Not $__DM_g_hHotkeyProc Then
				$__DM_g_hHotkeyProc = DllCallbackRegister(__GUIDarkTheme_HotkeyProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
				$__DM_g_pHotkeyProc = DllCallbackGetPtr($__DM_g_hHotkeyProc)
			EndIf
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pHotkeyProc, $hCtrl, $__DM_g_hHotkeyProc)

			Return True

		Case 'msctls_trackbar32'
			GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
			GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $__DM_g_iGuiBkColor)

			; Subclass slider controls to catch WM_ERASEBKGND to prevent background erase causing flicker
			If Not $__DM_g_hTrackbarProc Then
				$__DM_g_hTrackbarProc = DllCallbackRegister("__GUIDarkTheme_TrackbarProc", "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
				$__DM_g_pTrackbarProc = DllCallbackGetPtr($__DM_g_hTrackbarProc)
			EndIf
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pTrackbarProc, $hCtrl, $__DM_g_hTrackbarProc)

			; remove focus rectangle from slider control
			_SendMessage($hCtrl, $WM_CHANGEUISTATE, 65537, 0)

		Case 'SysLink'
			; Allow custom coloring for SysLink control
			_GUICtrlSysLink_AllowColoring($hCtrl)

			If Not $__DM_g_hSysLinkProc Then
				$__DM_g_hSysLinkProc = DllCallbackRegister(__GUIDarkTheme_SysLinkProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
				$__DM_g_pSysLinkProc = DllCallbackGetPtr($__DM_g_hSysLinkProc)
			EndIf
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pSysLinkProc, $hCtrl, $__DM_g_hSysLinkProc)

			Return True

		Case 'msctls_updown32'
			If $bEnableDarkTheme Then
				;$sThemeName = 'DarkMode_Explorer'
				$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer'
			Else
				$sThemeName = 'Explorer'
			EndIf

			; Removing the theme here prevents some theme engine control animations from bleeding through
			_WinAPI_SetWindowTheme($hCtrl, "", "")
			_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)

			If Not $__DM_g_hUpDownProc Then
				$__DM_g_hUpDownProc = DllCallbackRegister(__GUIDarkTheme_UpDownProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
				$__DM_g_pUpDownProc = DllCallbackGetPtr($__DM_g_hUpDownProc)
			EndIf
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pUpDownProc, $hCtrl, $__DM_g_hUpDownProc)
			Return True

		Case 'ListBox'
			_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pSubclassProc, $hCtrl, $__DM_g_hSubclassProc)
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			Switch $bEnableDarkTheme
				Case True
					$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer'
				Case False
					$sThemeName = 'Explorer'
			EndSwitch

			GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
			GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_BkColor)

		Case 'SysTreeView32'
			$sStyles = __GUIDarkTheme_hWnd2Styles($hCtrl)
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pSubclassProc, $hCtrl, $__DM_g_hSubclassProc)
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			Switch $bEnableDarkTheme
				Case True
					;$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer' ; DarkMode_DarkTheme still has some bugs
					$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_Explorer' : 'DarkMode_Explorer'

					; dark mode checkboxes
					If StringInStr($sStyles, "TVS_CHECKBOXES") Then
						$bSpecialTV = True
					EndIf
				Case False
					$sThemeName = 'Explorer'
					; light mode checkboxes
					If StringInStr($sStyles, "TVS_CHECKBOXES") Then
						$bSpecialTV = True
					EndIf
			EndSwitch

			GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
			GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_BkColor)

			; Add TVS_EX_DOUBLEBUFFER extended style to TreeView control
			_GUICtrlTreeView_SetExtendedStyle($hCtrl, $TVS_EX_DOUBLEBUFFER)

		Case 'SysListView32'
			; Add LVS_EX_DOUBLEBUFFER to ListView control
			Local $iExStyle = _GUICtrlListView_GetExtendedListViewStyle($hCtrl)
			_GUICtrlListView_SetExtendedListViewStyle($hCtrl, BitOR($iExStyle, $LVS_EX_DOUBLEBUFFER))

			Switch $bEnableDarkTheme
				Case True
					;$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer' ; DarkMode_DarkTheme border is not great
					$sThemeName = 'DarkMode_Explorer'

					; checkbox dark mode
					If (BitAND(_GUICtrlListView_GetExtendedListViewStyle($hCtrl), $LVS_EX_CHECKBOXES) = $LVS_EX_CHECKBOXES) Then
						$bSpecialLV = True
					EndIf
				Case False
					$sThemeName = 'Explorer'
					; checkbox light mode
					If (BitAND(_GUICtrlListView_GetExtendedListViewStyle($hCtrl), $LVS_EX_CHECKBOXES) = $LVS_EX_CHECKBOXES) Then
						$bSpecialLV = True
					EndIf
			EndSwitch

			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pSubclassProc, $hCtrl, $__DM_g_hSubclassProc)
			_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
			GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_BkColor)

			_SendMessage($hCtrl, $WM_CHANGEUISTATE, 65537, 0)

		Case "RichEdit", "RichEdit20W", "RichEdit50W", "RichEdit60W"
			Switch $bEnableDarkTheme
				Case True
					_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer", "ScrollBar")
					_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
				Case False
					_WinAPI_SetWindowTheme($hCtrl, "Explorer", "ScrollBar")
					_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
			EndSwitch

			; Remove the WS_EX_CLIENTEDGE extended style and apply WS_BORDER instead
			_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
			_WinAPI_SetWindowLong($hCtrl, $GWL_STYLE, BitOR(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $WS_BORDER))
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			_GUICtrlRichEdit_SetBkColor($hCtrl, $__DM_g_iCtrlBkColor)

			; Set default text color
			_RichEdit_SetDefaultTextColor($hCtrl, $__DM_g_iTextColor)

			Return True

		Case 'Edit'
			Local $sEditParent = _WinAPI_GetClassName(_WinAPI_GetParent($hCtrl))
			If $sEditParent <> "ComboBox" And $sEditParent <> "SysIPAddress32" Then
				_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
				_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pSubclassProc, $hCtrl, $__DM_g_hSubclassProc)
				_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
			EndIf

			If $sEditParent = "SysIPAddress32" Then Return True

			Switch $bEnableDarkTheme
				Case True
					$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer'
				Case False
					$sThemeName = 'Explorer'
			EndSwitch

			GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
			GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_BkColor)

			; This clears the initial blue selection highlighting from disabled combobox
			If $sEditParent = "ComboBox" Then _SendMessage($hCtrl, $EM_SETSEL, 0, 0)

		Case 'SysHeader32'
			Switch $bEnableDarkTheme
				Case True
					;$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_ItemsView'
					$sThemeName = 'DarkMode_ItemsView'
				Case False
					$sThemeName = 'ItemsView'
			EndSwitch
			$sThemeList = 'Header'

		Case 'Static'
			Local $iTextColor, $iBkMode
			__GUIDarkTheme_GetCtrlColors($hCtrl, $iTextColor, $iBkColor, $iBkMode)

			Switch $iTextColor
				Case 0x000000
					GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
				Case $__DM_g_iTextColorDark
					GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
				Case $__DM_g_iTextColorLight
					GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
				Case Else
					; skip swapping any custom colors
					GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iTextColor)
			EndSwitch

			Return True

		Case 'SysDateTimePick32'
			If $bEnableDarkTheme Then
				If Not $__DM_g_hDateProc Then
					$__DM_g_hDateProc = DllCallbackRegister(__GUIDarkTheme_DateProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
					$__DM_g_pDateProc = DllCallbackGetPtr($__DM_g_hDateProc)
				EndIf
				_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pDateProc, $hCtrl, $__DM_g_hDateProc)

				; set colors for dropdown calendar
				_GUICtrlDTP_SetMCColor($hCtrl, 0, $__DM_g_iCtrlBkColor)
				_GUICtrlDTP_SetMCColor($hCtrl, 1, $__DM_g_iTextColor)
				_GUICtrlDTP_SetMCColor($hCtrl, 2, _WinAPI_SwitchColor(0x0078D4))
				_GUICtrlDTP_SetMCColor($hCtrl, 3, $__DM_g_iTextColor)
				_GUICtrlDTP_SetMCColor($hCtrl, 4, $__DM_g_iCtrlBkColor)
				_GUICtrlDTP_SetMCColor($hCtrl, 5, $__DM_g_iTextColor)
			EndIf

		Case 'msctls_progress32'
			Local $iProgressHide = False
			; Get state and progress position
			Local $iProgressPos = _SendMessage($hCtrl, $PBM_GETPOS, 0, 0)
			Local $iProgressState = _SendMessage($hCtrl, $PBM_GETSTATE, 0, 0)
			Local $iCtrlState = GUICtrlGetState(_WinAPI_GetDlgCtrlID($hCtrl))
			If BitAND($iCtrlState, $GUI_HIDE) Then $iProgressHide = True

			; Remove theme and WS_EX_STATICEDGE extended style
			_WinAPI_SetWindowTheme($hCtrl, "", "")
			_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitXOR(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), $WS_EX_STATICEDGE))

			; Determine bar color based on state
			; Note: bar color can't be changed for PBST_ERROR or PBST_PAUSED
			Local $iBarColor
			Switch $iProgressState
				Case BitAND($iProgressState, $PBST_NORMAL)
					$iBarColor = _WinAPI_SwitchColor($__DM_g_iAccentColor)
				Case BitAND($iProgressState, $PBST_ERROR)
					$iBarColor = _WinAPI_SwitchColor(0xFF2222)
				Case BitAND($iProgressState, $PBST_PAUSED)
					$iBarColor = _WinAPI_SwitchColor(0xFCE100)
				Case Else
					$iBarColor = _WinAPI_SwitchColor($__DM_g_iAccentColor)
			EndSwitch

			_SendMessage($hCtrl, $PBM_SETBARCOLOR, 0, $iBarColor)
			_SendMessage($hCtrl, $PBM_SETBKCOLOR, 0, $__DM_g_iCtrlBkColor)

			; Add WS_BORDER style
			If BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $PBM_SETMARQUEE) Then
				GUICtrlSetStyle(_WinAPI_GetDlgCtrlID($hCtrl), BitOR($PBM_SETMARQUEE, $WS_BORDER))
			Else
				GUICtrlSetStyle(_WinAPI_GetDlgCtrlID($hCtrl), $WS_BORDER)
			EndIf

			; SetWindowPos is needed to allow the WS_BORDER change
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			; Restore progress to original value since progress is lost after SetWindowLong
			_SendMessage($hCtrl, $PBM_SETPOS, $iProgressPos, 0)
			GUICtrlSetData(_WinAPI_GetDlgCtrlID($hCtrl), $iProgressPos)

			If $iProgressHide Then GUICtrlSetState(_WinAPI_GetDlgCtrlID($hCtrl), $GUI_HIDE)

			Return True

		Case 'Scrollbar'
			If $bEnableDarkTheme Then $sThemeName = 'DarkMode_Explorer'
			$sStyles = __GUIDarkTheme_hWnd2Styles($hCtrl)
			If StringInStr($sStyles, "SBS_SIZEBOX") Or StringInStr($sStyles, "SBS_SIZEGRIP") Then
				_WinAPI_SetWindowPos($hCtrl, $HWND_TOP, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOREDRAW, $SWP_NOSIZE))
				If Not $__DM_g_hScrollbarProc Then
					$__DM_g_hScrollbarProc = DllCallbackRegister(__GUIDarkTheme_ScrollbarProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
					$__DM_g_pScrollbarProc = DllCallbackGetPtr($__DM_g_hScrollbarProc)
				EndIf
				_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pScrollbarProc, $hCtrl, $__DM_g_hScrollbarProc)
			EndIf

		Case 'AutoIt v3 GUI'
			If $bEnableDarkTheme Then
				$sThemeName = 'DarkMode_Explorer'
			EndIf

		Case 'msctls_statusbar32'
			; Register WM_SETCURSOR only if GUI is resizable
			If __GUIDarkTheme_GUI_IsResizable($hGui) Then
				GUIRegisterMsg($WM_SETCURSOR, "__GUIDarkTheme_WM_SETCURSOR")
			EndIf

			If Not $bEnableDarkTheme Then Return True

			If Not $__DM_g_hStatusProc Then
				$__DM_g_hStatusProc = DllCallbackRegister(__GUIDarkTheme_StatusProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
				$__DM_g_pStatusProc = DllCallbackGetPtr($__DM_g_hStatusProc)
			EndIf
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pStatusProc, $hCtrl, $__DM_g_hStatusProc)

			Return True

		Case 'tooltips_class32'
			If $bEnableDarkTheme Then
				;$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer' ; works but is faded
				$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_Explorer' : 'DarkMode_Explorer'
				$sThemeList = 'ToolTip'
			EndIf

		Case 'ComboBox'
			If $bEnableDarkTheme Then
				$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_CFD'
				$sThemeName = 'DarkMode_CFD' ; using older theme version for now
				$sThemeList = 'Combobox'
				_WinAPI_SetWindowTheme($hCtrl, $sThemeName, $sThemeList)
				_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
			EndIf

			If Not $bEnableDarkTheme Then
				$sThemeName = 'CFD'
				$sThemeList = 'Combobox'
				_WinAPI_SetWindowTheme($hCtrl, $sThemeName, $sThemeList)
				_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
			EndIf

			; Remove initial focus rectangle from ComboBox
			_SendMessage($hCtrl, $WM_CHANGEUISTATE, 65537, 0)

			GUICtrlSetColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_Color)
			GUICtrlSetBkColor(_WinAPI_GetDlgCtrlID($hCtrl), $iGUI_Ctrl_BkColor)

			Return True

		Case 'SysMonthCal32'
			_WinAPI_SetWindowLong($hCtrl, $GWL_STYLE, BitOR(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $WS_BORDER))
			_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))

			_GUICtrlMonthCal_SetColor($hCtrl, $MCSC_TEXT, $__DM_g_iTextColor)
			_GUICtrlMonthCal_SetColor($hCtrl, $MCSC_TITLEBK, _WinAPI_SwitchColor(0x0078D4))
			_GUICtrlMonthCal_SetColor($hCtrl, $MCSC_TITLETEXT, $__DM_g_iTextColor)
			_GUICtrlMonthCal_SetColor($hCtrl, $MCSC_BACKGROUND, $__DM_g_iCtrlBkColor)
			_GUICtrlMonthCal_SetColor($hCtrl, $MCSC_MONTHBK, $__DM_g_iCtrlBkColor)
			_GUICtrlMonthCal_SetColor($hCtrl, $MCSC_TRAILINGTEXT, $__DM_g_iTextColor)
			_WinAPI_SetWindowTheme($hCtrl, "", "")
			_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)

			Return True

		Case 'SysTabControl32'
			If $bEnableDarkTheme Then
				$sThemeName = $__DM_g_b24H2Plus ? 'DarkMode_DarkTheme' : 'DarkMode_Explorer'
				$sThemeList = 'Tab'
			Else
				$sThemeName = 'Explorer'
			EndIf

			If Not $__DM_g_hTabProc Then
				_WinAPI_SetWindowPos($hCtrl, $HWND_BOTTOM, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOREDRAW, $SWP_NOSIZE))
				$__DM_g_hTabProc = DllCallbackRegister(__GUIDarkTheme_TabProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
				$__DM_g_pTabProc = DllCallbackGetPtr($__DM_g_hTabProc)
			EndIf
			_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pTabProc, $hCtrl, $__DM_g_hTabProc)

			; remove focus rectangle from tab items
			_SendMessage($hCtrl, $WM_CHANGEUISTATE, 65537, 0)

			; this seems to be needed to fix conflict between group box and tab control
			_WinAPI_SetWindowPos($hCtrl, $HWND_TOP, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOREDRAW, $SWP_NOSIZE))

		Case Else
			$sThemeName = 'DarkMode_Explorer'

	EndSwitch
	;ConsoleWrite(@CRLF & 'Class:' & _WinAPI_GetClassName($hCtrl) & ' Theme:' & $sThemeName & '::' & $sThemeList)
	;=========
	_WinAPI_SetWindowTheme($hCtrl, $sThemeName, $sThemeList)
	If @error <> 0 Then Return SetError(3, @error, False)
	_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
	If @error <> 0 Then Return SetError(4, @error, False)

	Local $iSize, $hChecked, $hUnchecked
	If $bSpecialLV Then
		Local $hImageListLV = _GUICtrlListView_GetImageList($hCtrl, 2)
		$iSize = _GUIImageList_GetIconHeight($hImageListLV)
		_GUIImageList_Remove($hImageListLV)
		If @OSBuild >= 22000 Then
			$hUnchecked = __GUIDarkTheme_GetImages($hGui, 0, 3, $iSize, $iSize)
			$hChecked = __GUIDarkTheme_GetImages($hGui, 5, 3, $iSize, $iSize)
			_GUIImageList_Add($hImageListLV, $hUnchecked)
			_GUIImageList_Add($hImageListLV, $hChecked)
			_WinAPI_DeleteObject($hChecked)
			_WinAPI_DeleteObject($hUnchecked)
		Else
			$hChecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_CheckedPNG($iSize), True)
			$hUnchecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_UncheckedPNG($iSize), True)
			_GUIImageList_Add($hImageListLV, $hUnchecked)
			_GUIImageList_Add($hImageListLV, $hChecked)
			_WinAPI_DeleteObject($hChecked)
			_WinAPI_DeleteObject($hUnchecked)
		EndIf
	EndIf
	If $bSpecialTV Then
		Local $hImageListTV = _GUICtrlTreeView_GetStateImageList($hCtrl)
		$iSize = _GUIImageList_GetIconHeight($hImageListTV)
		_GUIImageList_Remove($hImageListTV)
		If @OSBuild >= 22000 Then
			$hUnchecked = __GUIDarkTheme_GetImages($hGui, 0, 3, $iSize, $iSize)
			$hChecked = __GUIDarkTheme_GetImages($hGui, 5, 3, $iSize, $iSize)
			_GUIImageList_Add($hImageListTV, $hUnchecked)
			_GUIImageList_Add($hImageListTV, $hUnchecked)
			_GUIImageList_Add($hImageListTV, $hChecked)
			_WinAPI_DeleteObject($hChecked)
			_WinAPI_DeleteObject($hUnchecked)
		Else
			$hChecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_CheckedPNG($iSize), True)
			$hUnchecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_UncheckedPNG($iSize), True)
			_GUIImageList_Add($hImageListTV, $hUnchecked)
			_GUIImageList_Add($hImageListTV, $hUnchecked)
			_GUIImageList_Add($hImageListTV, $hChecked)
			_WinAPI_DeleteObject($hChecked)
			_WinAPI_DeleteObject($hUnchecked)
		EndIf
	EndIf

	Return True
EndFunc   ;==>_GUIDarkTheme_GUICtrlSetDarkTheme

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_ApplyAuto($hGui)
	If $__DM_g_bUseDarkMode Then
		_GUIDarkTheme_ApplyDark($hGui)
	Else
		_GUIDarkTheme_ApplyLight($hGui)
	EndIf

	; register WM_SETTINGCHANGE to monitor for system color mode changes
	_GUIDarkTheme_AutoTheme()

	$__DM_g_bPreviousRun = True
	$__DM_g_bMicaEnabled = False
EndFunc   ;==>_GUIDarkTheme_ApplyAuto

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_ApplyDark
; Description ...: Automatically sets dark theme for GUI and all controls (with automatic subclassing when necessary)
; Syntax ........: _GUIDarkTheme_ApplyDark($hGui)
; Parameters ....: $hGui          		- The handle to the window.
; Return values .: None
; Author ........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_ApplyDark($hGui)
	$__DM_g_bDarkModeLast = True
	If $__DM_g_bPreviousRun Then __DM_ThemeCleanupHelper($hGui, 1)

	_GUIDarkTheme_GUISetDarkTheme($hGui, True)
	_GUIDarkTheme_GUICtrlAllSetDarkTheme($hGui, True)
	_GUIDarkMenu_Register($hGui)

	If $__DM_g_bPreviousRun Then __DM_ThemeCleanupHelper($hGui, 2)

	$__DM_g_bPreviousRun = True
	$__DM_g_bMicaEnabled = False
EndFunc   ;==>_GUIDarkTheme_ApplyDark

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_ApplyLight
; Description ...: Automatically sets light theme for GUI and all controls (with automatic subclassing when necessary)
; Syntax ........: _GUIDarkTheme_ApplyLight($hGui)
; Parameters ....: $hGui          		- The handle to the window.
; Return values .: None
; Author ........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_ApplyLight($hGui)
	$__DM_g_bDarkModeLast = False
	If $__DM_g_bPreviousRun Then __DM_ThemeCleanupHelper($hGui, 1)

	_GUIDarkTheme_GUISetDarkTheme($hGui, False)
	_GUIDarkTheme_GUICtrlAllSetDarkTheme($hGui, False)
	_GUIDarkMenu_Register($hGui)

	If $__DM_g_bPreviousRun Then __DM_ThemeCleanupHelper($hGui, 2)

	$__DM_g_bPreviousRun = True
	$__DM_g_bMicaEnabled = False
EndFunc   ;==>_GUIDarkTheme_ApplyLight

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_ApplyMica
; Description ...: Automatically sets dark theme for GUI and all controls (with automatic subclassing when necessary)
; Syntax ........: _GUIDarkTheme_ApplyMica($hGui)
; Parameters ....: $hGui          		- The handle to the window.
; Material ......: $iMaterial			- Eg. $DWMSBT_MAINWINDOW - Windows 11 Build 22621+ required
; Return values .: None
; Author ........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_ApplyMica($hGui, $iMaterial)
	If $__DM_g_bPreviousRun Then __DM_ThemeCleanupHelper($hGui, 1)

	; __DM_WinAPI_DwmSetWindowAttribute($hGui, $DWM_SYSTEMBACKDROP_TYPE, $iMaterial)
	;_WinAPI_DwmExtendFrameIntoClientArea($hGui, _WinAPI_CreateMargins(-1, -1, -1, -1))
	;Global Const $DWMSBT_AUTO = 0
	;Global Const $DWMSBT_NONE = 1
	;Global Const $DWMSBT_MAINWINDOW = 2
	;Global Const $DWMSBT_TRANSIENTWINDOW = 3
	;Global Const $DWMSBT_TABBEDWINDOW = 4
	;$__DM_g_iGuiBkColor
	;$__DM_g_iCtrlBkColor
	$__DM_g_iGuiBkColorDark = 0x000000
	$__DM_g_iMenuBkColorDark = 0x000000
	$__DM_g_iCtrlBkColorDark = 0x121212
	_GUIDarkTheme_GUISetDarkTheme($hGui, True)
	_GUIDarkTheme_GUICtrlAllSetDarkTheme($hGui, True)
	_GUIDarkMenu_Register($hGui)

	If $__DM_g_bPreviousRun Then __DM_ThemeCleanupHelper($hGui, 2)

	__DM_WinAPI_DwmSetWindowAttribute($hGui, $DWM_SYSTEMBACKDROP_TYPE, $iMaterial)
	_WinAPI_DwmExtendFrameIntoClientArea($hGui, _WinAPI_CreateMargins(-1, -1, -1, -1))

	$__DM_g_bPreviousRun = True
	$__DM_g_bMicaEnabled = True
EndFunc   ;==>_GUIDarkTheme_ApplyMica

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; Modified.......: UEZ, argumentum
; ===============================================================================================================================
Func __GUIDarkTheme_CheckedPNG($iSize = 16, $sSavePath = Default)
	Local $Base64String, $iExt = (IsKeyword($sSavePath) ? 0 : 2) ; "BitAND(@extended, 2)" meant that the user wanted to save to disk
	Switch $iSize
		Case 13
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcYOepp4t4AAADpSURBVCjPY2RgYGAwSG9o0IrMz2fjFRBgwAF+ff7w4c7mBQtO9RYWMpuVTJigm1BezszOwcGABzCzc3CI6lpYMDAwMDBGHXj/Hp8N2GxkIkUDAwMDAxuvgAATMQrvbF6Awieo6Uh9AgMDIyNuTY8ObMDQIGHqyKDiE49b06/PHxiONCTi1cDAwMDAgsxR8U1gYGBgYFjjq8hgkN6AVQMDAwMDY8LZ//+xBCsDGy/uQGX69fnDByzBijeemJnZODgkTBwciI2nm2tnzGB+cfbgQTZeAQF+BQ0NfEnp1+cPHy4v6Og4O6WyEgBYG0pIgbNupgAAAABJRU5ErkJggg=='
		Case 20
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcZJn563moAAAEdSURBVDjLY2RgYFDilVZUs66f3yqkpq/GxivAw0AieHRg46FTvQXtX58/vMXII6Vg5bfs/A42XgFeBgrAr88fPm2KNPRktmlYMFNI3UCbgULAzM7BLqRuoMGYcPb/fwYqgV+fP3xkYqAiYOMV4KeqgQwMDAyDw8B3ty4wbIo0xCrHQo5h+4oCGZz61lPuQmTDhNQMiDdwU6Qhw7tbF0g2DKeBNo3zGfYVB8INJdYwBgYGBpwJ+92tCwz7igMZDNLqGS7MbCTKMLwGkuoyogwcHAn71+cPH6hq4LtbFy5Qy7BHBzZsYOSRUlDwW3b+PBuvgACFRdeHTZGGhsy/Pn/4cH/XypU8UgoK/AoaGuQY9PryiRO7cz09vzx/8AAAGLWDCCvF1IEAAAAASUVORK5CYII='
		Case 26
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAYAAACpSkzOAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcaCxCI0dwAAAF1SURBVEjH7da9a8JAGAbwJ1pSh1iyFGqmG5wKHaQgDh10c7FTF7e4uCr4D+heyKpOuhQculgH6WICTgU1q0Uwk41Dy0EChVvs0JamBa3mQyj0mY/8eLjcy8vhI4JEyGm+VIrnZJmPiiI8xF4YhjlSVb1Rq9lPhgEAHADEc7KcrCiKV+BnmEXpw3W5POu125wgEXJ5M5n4jTixbj6RCCcrinJ8lkohoIQPIxEA4K5687kQIwQBhlmUcvJotcIeEsKe8g+tu2z0i2kMq4W1Zw78QTJgNsVFrRVMIyeSbQ4gxIj/0C7IRkhvVNHNJ8As6hnZCMVz8tcHHZgbZCMkSATZ5uAb5hYBgF9HkL0w0C9mwEffh7sbZKufwdnMLbJVI2czcHCF7PRgBYn8kVnHLEqDRuyFYYRmd61W0JA5UtX9LSfMovT1ebk8OU+nPxcJv9ctc6xpYQB4edT1+X2nw0dFkT8SRa/tmEXp9LZeH1YLBXOsaQDwBivy2deCjE70AAAAAElFTkSuQmCC'
		Case 32
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxccGixiVqgAAAGaSURBVFjD7dcxaMJQFIXhk6Skdgh9tAiZSqcigmARxKFD7OTYVad2EbcguDdduolxjEu3bNLSyUy+oSAIgUyBdJKCNJMG7ORipxSxFKOGBIp3CiHh/wgXwmOwNGJOktIVWRZzksQLhCDEmc88zzUptfV22zUp9e8z/kW+oarpsiwjgrF1VR0263UA4KKOA0AyUyjwAiHjgWEwYk6SSp1+HzFMr1oscvlGq3V8nkrFAeAFQpgKnU7DXrhNFpONK+5/ARYxzx7wfwG2rmLYrMcDsDQFw2YdE8eKHmBpCqzOA04usrhuPkcLWI6XOn3wAokOsE08EOC1fLl2mbaNBwKcFW9g6yrelLvQ4wBwsO6BbPX+JwQAV8pTaPFAgL8QYcQDA1YRE8fC5N3aOb4RYBURRhwAmFtzsdj0pQ/6AjEn7RzfGrD/G4YKmM88L674fOZ57PIxKepxTUpZW2+34wLYuqpyX5+jES8QkswUClHHna6mcQAwHhhGlIhfh1Mf4ZqU8gIhR6eiyB0mEmEv3HjQ6w0eazWnq2n+/W+c6MNyCJEgYgAAAABJRU5ErkJggg=='
		Case 40
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAYAAACM/rhtAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxccOPkCF0wAAAHRSURBVFjD7dg9a8JAGAfwRwPBgkKwFNRB4mKhUAgIxTHZHFrM0KVbXdKtDv0Ams3NrPoBBMEh0kVdVCh0Em4SdPEIVDtJwAwiFDtZ0mCLUaNXmv8UuOF+PPeS4/GAJaEEz0f5dDoqiKI/zLJwgEyHCE0HCKGSLBsTjM1jntUHHWAY7iGfv7jLZuGI6VcUBZVleTHT9S8gHWCYVLndDsY5DgjIdIhQQxKExUzXKQCAxGOhEOVFEQjJyWkoRNE+39trs+nxR1j29nk0AgLTkASBunoqFoPnZCytNYuZrntJxQEARHlR9Nz3lksgOF4gPC7QBbpAkoDGGEPtOga1mxh5QGOMoSEJYEwweRU04/wRFlLlNjnAdTh/mCUDuCvOUeA+cLaAq9O3ySbfF852BTc5ifvE2QKuJvoNuW+cLaB5wnVIJ3C2l/gnpFM4AICtXtRWECzBEdzW14y1kk7hdroHzSCncFsvsfsedIH/CmhtGJKU6QAhr9ZWVWKBQ4S8WqdeJxWISrJMGROM6QDDnF0mkyTh+hVFGbWq1b/RAv5YzOejVrVK0T7fsSvZryjKSz6T+dZEt/xjWU7K5YJxjjtUc9MYY6x1VFXrqOp7r9s1j30CYTArpz88OJ4AAAAASUVORK5CYII='
		Case 52
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAADQAAAA0CAYAAADFeBvrAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcdEaKrvmEAAAKqSURBVGje7dq/b9pAFAfwh6kIg1FQJseDdQOKGIkcdWI4MjUDwWsnPFGWSo3yB4QsmdJmbhbK0ipTnKZD1ErNZYoUQTErQuqFARypRZawFIklXeqKumkbwPiX/N18guGjOz/7WS8CfwknYizgQoFbw5hdRiiWSCbBxYyGum70KdXqhHROa7VBW1Xv+13EusDyCGUr1SonYgweTpcoytX+1pbRp3R8PTp+kcrL8vrL4+NFlE6Dx7OI0ulUXpZvv2naoN1q/QFK5WU5W6lWowvxOPgk0YV4XMhJktGj1ERFzGO2+bbZdPs+meX+ev90ddXoU8oAADzePjjwKwYAIJZIJrO71SoAQGRpJZPZfNdsQgByVsrlmFS+WISARMCFAsOtebs8TxJOxJhhlxEKCojlEWL8XAzuKw4MBCwhKASFoBAUghzNoK3C520JukSZ6v+PvIY5K+VgNNRh0G6BgCX/7tA45mfD6d8jZ8VknlUgU9rxJ8hOjOsguzGuguaBcQ00L8zUoKv9F/BGjID6uuIpzNQg86GnHu5OhJo3ZmrQ+isFYonkRCgnMFODllYy8OTw/MEopzAzFYWHopzEzFzl/odyGgMAEJEbd3e2l+HSDgg5yXGMbaD7ULFE0nGMrQ9W6/FzA2P7m4IV5TTG1iM3HqNHwehT4ETs+GvVXDpWlkfA8ij8phCCQpAfQaOhrgcFMxrqOmOdxPBzjB6ljFYnJCggrUEI0yUnJ0EBdU5rNUZrEKI1/L9L3XNFGbRVNXCjMVFz4fb7zY2AJcmPoMu9cln7cnEBMDaN'
			$Base64String &= 'NWirqtG/vuZEjP0ykTUa6vrlXrnc+VCrmWtRS5Omfv14dMTyCHl9Zk6rE/Lp+caGuTO/2od/9DaZVL5Y5ESMWd4jI5o9SrUGIV2iKFrjd4iZH07DnAm7lTVAAAAAAElFTkSuQmCC'
		Case Else ; 16
			If $iSize <> 16 Then $iExt = BitOR($iExt, 1)
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcZFLatj+oAAAEPSURBVDjLY2RgYGDQiioo0IrKz+eRVFBgIAK8u3XhwrWlEybc2bJwIaOKb0KCTcP8+QxkgFO9hYWMfsvPnxdSMzAgx4Avzx48YEw4+/8/AwWAiYFCQJIBdzYvYPj1+QN5BlyY2cBwbdlEBjZeAdINuDCzgeHRgY0MHrP24/fCl2cPGNb4KjJ8ef4Aq2Z02zEM4JFSYDBIq2fYkebI8OX5A4KaGRgYGFjQBVR8ExgYGBgYNkUaMvBIKuDVzMDAwIAzHby7eYGBR0oBr2asLoABIXXiEifTl+cPHpCbiN7dvHCBmYGBkVHaysODHAPOTq6oYH59+cSJL88fPuSRVFDgFJGQIDYTXZjZ0HBz3cyZABhkZ7hwets3AAAAAElFTkSuQmCC'
	EndSwitch
	Local $bString = _WinAPI_Base64Decode($Base64String)
	If @error Then Return SetError(1, $iExt, 0)
	$bString = Binary($bString)
	If Not $iExt Then
		Local Const $hFile = FileOpen($sSavePath & "\checked.png", $FO_BINARY + $FO_OVERWRITE)
		If @error Then Return SetError(2, $iExt, $bString)
		FileWrite($hFile, $bString)
		FileClose($hFile)
	EndIf
	Return SetError(0, $iExt, $bString)
EndFunc   ;==>__GUIDarkTheme_CheckedPNG

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; Modified.......: UEZ, argumentum
; ===============================================================================================================================
Func __GUIDarkTheme_UncheckedPNG($iSize = 16, $sSavePath = Default)
	Local $Base64String, $iExt = (IsKeyword($sSavePath) ? 0 : 2) ; "BitAND(@extended, 2)" meant that the user wanted to save to disk
	Switch $iSize
		Case 13
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcfHO4soF4AAAC3SURBVCjP7dIhDoMwGMXx1y0kX1pDFUdBsgRDgsb3BmThAuwEQyAmwWOruQQWjdxn2lROTbKR6f31+7knAKCqqrYsy1pKGWMn7z3P8zyM43gVxpguSZLaWosQwp6B1hp5nmNd11YMw/Ds+z5mZnyLiNA0DZ+klIcAAIQQoJSKT/ihP3oj7z0T0aGx1hrOOT5HUURpml62bfv4CCJCURRYluUhAMAYc8+yzCildr/nnGNrbTdN0+0FDuRGAoicao0AAAAASUVORK5CYII='
		Case 20
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcgFyEgU+oAAAD6SURBVDjL7dUhboRAFMbxB2smYAjJJMi5AVuSCYaEEEwlvQHFoirgEpDUYcsNukdoBWNIaBUWLBkzBjJiRNW6ihIq+R/gl++ppwEAYIxJnudvhJCrYRgW7Kzv+1vbti+c81nDGJOqqr4YYxZjDKSUuzCEEHieB1EUibIsH7SiKN6XZUkYY3CkOI7BcZwPnVKaDMMAR+u6DgghVx0Adp/5W1JKME3T0uGfO8ETPME/gdu2CYTQYehuXFzXfbRtm0zTdAj0fR+EELfLOI6fWZalSinEOQel1O5lYRhCEASirusn7f4C0jR9pZQme5et6yrmef5umuaZcz7/AC65XdIkaSqyAAAAAElFTkSuQmCC'
		Case 26
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAYAAACpSkzOAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcgMfMt1hcAAAEzSURBVEjH7dahbsJAAIfxf28VCyTNnbgqRPWh5uo4LB5FxfEEm8Iu6AqCR3RJXTXo4wmmeqYGTUXPlGAaZkaCL12ypN8L/Ozn4DfOeTCbzd6n06kaDAYULSrL8pTnuc6ybF2W5QkAHACQUiql1IYQQvM8h7W2jQPGGIQQaJrGJknycTwevxzOeRDH8be1lqZp2hp5xKIogud5drVavb0opTaj0Sjc7XZPQwDger2iKAqEYfjqui7IeDyWxpinIveqqoIxBlJKRTjnQRfIIzYcDinBH9VDPdRDPdRD/xK6XC6WUtoZwBjD+Xw+Ea11IoRAF9h9Uowxmuz3++3tdrNRFD0VY4xhsVigaRqbZdnaAYDJZKKWy2W3u/U4kPP5/FMIIX3fD9pAdV1brXVyOBy294H8AUHOkTVbUaKIAAAAAElFTkSuQmCC'
		Case 32
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxciEmN8xecAAAF/SURBVFjD7ZexiqtAFIb/mFsYheA8gt0y8wDZLpIpAuNL2KTe7JOsWy23tMgjjEWQ4EJe4UxpLqRMoY1ikeJWguUWidvMVw2HA/8Hc5p/hhFCiEgp9SaEiDzPC/BAuq5riKjM8/yTiMphPhseSZKkSqm3vu9BRGia5pH5YIwhDEMwxqC1TrMseweAP+Pw8/mM0+mEvu/xLDabDeI43gNAlmXvcyFEtNvtvoqiwPF4xP1+xzO5XC5wXRdSylci+p4nSfLhed7L4XDAVFyvV6xWKyyXy8ARQkRVVWFK+r6HMQZCiMjxPC949MH9hLqu4ft+4OCXsQJWwApYAStgBayAFbACTtd1TRAEkwczxtC2beMQUck5h+u6kwqEYQgiKh2t9edisYCUcrJwKSUYY8jzPJ3fbrd/vu8HUsrXobk8C9d1sd1usV6vobVOi6L4Oy6nH0qpfV3XqKrqKeV0+OpxOZ2Nlzjn6ziO95zzyPf9h15m27aNMabUWqfGmO9h/h/YFp4sUeI9ggAAAABJRU5ErkJggg=='
		Case 40
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAYAAACM/rhtAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxciKdJ3LMMAAAIZSURBVFjD7dg9q9pQAMbx5/oC1SDEIXAzeZIxLiG+cDFLuxWXOqiLiwX3+g2u2br1gqAfoZQsdnDoVC5IoAbfBuMgmDgJOphB5YBLJ0UunVXo+U+Bs/zI4SzPA96UTCbfp9PpT9lstiAIAsEV8jxv7Hne2DRNY7PZeJdnD6ePaDTKl8vlRj6f/4Ib1u12X0zTNA6Hg38GRqNRvtFo/CaEqJRS9Ho9uK4L13WvghJFEbquQ9M0AIDrumPDMD4cDgc/CACVSuVrJpMpbLdbtNttzGYz+L5/tb+22+3gOA6GwyEURYEoio/hcPjdZDL5FRQEgdTr9e8A0Gw2rwp7G6UUs9kMqVQKiqI8TafT12C1Wv1GCFEHgwFGoxFuHaUUoVAIsixjv9/7AUmSVACwLAv30mKxAABks9lCIJFIqACwWq3uBnh6nIIgkADuPAZkQAZkQAZkQAZkQAZkQAZkQAZkwP8aeBoMJUm6G5QoiqeFYRywbbsDALIs3w1Q13UAwHK5HAf6/f5PAMjlcuB5/ua4eDx+HjJN0zSCm83G4ziOVxTlSVEUOI4DSunNcLVaDZFIBN1u98WyrB9BAJjP539UVf0oiuKjruvgeR6+72O3210FJssyNE1DsVhELBaD67rjVqv1+Xg80vOIznEcXyqVnvP5fP2WV/zPEf0yQRBIqVR6JoSohBD1Gqj1eu3Ztt2xbbvjOM7r5dlfsTLTT1G4ptgAAAAASUVORK5CYII='
		Case 52
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAADQAAAA0CAYAAADFeBvrAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcjAxDX1FQAAAKhSURBVGje7dqxbtpQGAXgg5tICBYzGMmejEd7SRPIksFXYmAMDwCK2apkaRZeIkOmsDAkFi+QPgDIlpLFCDWLPWKzxKo9xIuRxw7RRYQmkSpVAlf3bFw83E/31z+dAj6IpmmkXq+fappGqtWqXCqVeGwxy+UyiaIocF3Xsm3bDILg6b3vCpsHgiDIFxcXt6qqEuxwHMe5N03zMo7j4EMQIcQwDON6/TXm8znCMESWZVsFFItFiKIIRVFWZ2maJnd3d99t2zb/ABFCjPPz81v6++HhAZPJZOuQzVQqFTSbTRweHq7Obm5uDIoq0DG7urr6WSqV+CzLMBqN4Pv+Lk8carUaut0uisUi0jRN+v3+1ziOAw4A1scsDxgA8H0fo9EIAFAul3k6XZwsyweNRqMNALPZLBeYddTj4+NqK6uqSjhCyBn9YDweI29Zv3Oj0TjlNE0jdJslSZI7UJZlmM/nAABVVQknCIIMAGEYIq+hd69WqzJHl8Guree/fSW6HDj8Z2EgBmIgBmIgBmIgBmIgBmIgBmIgBmIgBmIgBmIgBmIgBmIgBvrHoOVymQCvPYC8ht49TdOEo00MURRzC5IkCQAQRVHAua5rAYCiKLl8pUqlglqtBgDwPM/iHMf5Qf9sNpu5A63f2bIsk/M8z6KvdHJystLmIYqirCoyjuPcLxaLJw4ABoNBjy6HTqeTC5SiKOh0OqtlYJrmJQB8AV67aC8vL7+Oj4/b+/v7ODo6As/zO9HCem+jtVottNtt7O3tAQCGw+E3z/NsYKNepuu60ev13tTLfN/H'
			$Base64String &= '8/PzTtTLJEl6Mz2f1stoBEGQDcO4pv2fXY3rutZgMOh9WgBcjyzLB7qun2maRgRBkMvl8lYrmmmaJnEcB67rWtPp9J6O2GZ+A6oXHMXfWhlTAAAAAElFTkSuQmCC'
		Case Else ; 16
			If $iSize <> 16 Then $iExt = BitOR($iExt, 1)
			$Base64String &= 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IB2cksfwAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAAd0SU1FB+oDAxcfO0smFTUAAADBSURBVDjL7cyhDYNAGIbhD1qFqzhxijsmYAOQDZcQgkIg2IDK7oBou0HrCYIEsGxQNvjPkYBlgK5wpJbXP68FAEqpWxRFJWNMwCCt9dT3/XMcx885DMMijuNHXdcgIhMPzrmf5/nbcZyLVVXVt21bf55n7ElKiSRJtO267m4MAEQExpiw8WfH4BgAgL2uq5ZS7oaccxDRdAJgpWl6JSJs22aEPc9DlmVomuZuAUAQBIVSqhRC+CaDZVl013XPYRheP/vGQ/mk4/+CAAAAAElFTkSuQmCC'
	EndSwitch
	Local $bString = _WinAPI_Base64Decode($Base64String)
	If @error Then Return SetError(1, $iExt, 0)
	$bString = Binary($bString)
	If Not $iExt Then
		Local Const $hFile = FileOpen($sSavePath & "\unchecked.png", $FO_BINARY + $FO_OVERWRITE)
		If @error Then Return SetError(2, $iExt, $bString)
		FileWrite($hFile, $bString)
		FileClose($hFile)
	EndIf
	Return SetError(0, $iExt, $bString)
EndFunc   ;==>__GUIDarkTheme_UncheckedPNG

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_GetImages($hGui, $iState, $iPart = 3, $iWidth = 16, $iHeight = 16)
	Local $hTheme = _WinAPI_OpenThemeData($hGui, $__DM_g_bUseDarkMode ? "DarkMode_Explorer::Button" : "Button")
	If @error Then Return SetError(1, 0, 0)
	Local $hDC = _WinAPI_GetDC($hGui)
	Local $hHBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
	Local $hObjOld = _WinAPI_SelectObject($hMemDC, $hHBitmap)
	Local $tRect = _WinAPI_CreateRectEx(0, 0, $iWidth, $iHeight)
	_WinAPI_DrawThemeBackground($hTheme, $iPart, $iState, $hMemDC, $tRect)
	If @error Then
		_WinAPI_CloseThemeData($hTheme)
		Return SetError(2, 0, 0)
	EndIf
	_WinAPI_SelectObject($hMemDC, $hObjOld)
	_WinAPI_ReleaseDC($hGui, $hDC)
	_WinAPI_DeleteDC($hMemDC)
	_WinAPI_CloseThemeData($hTheme)
	Return $hHBitmap
EndFunc   ;==>__GUIDarkTheme_GetImages

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkMenu_WM_MEASUREITEM($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam
	If Not _GUICtrlMenu_GetMenu($hWnd) Then Return $GUI_RUNDEFMSG
	Local $tagMEASUREITEM = "uint CtlType;uint CtlID;uint itemID;uint itemWidth;uint itemHeight;ulong_ptr itemData"
	Local $t = DllStructCreate($tagMEASUREITEM, $lParam)
	If Not IsDllStruct($t) Then Return $GUI_RUNDEFMSG

	If $t.CtlType <> $ODT_MENU Then Return $GUI_RUNDEFMSG

	Local $itemID = $t.itemID

	; itemID is the control ID, not the position!
	; We must derive the position from the itemID
	Local $iPos = -1
	For $i = 0 To UBound($__DM_g_aMenuText) - 1
		If $itemID = $__DM_g_aMenuText[$i][0] Then
			$iPos = $i
			ExitLoop
		EndIf
	Next

	; Fallback: try the itemID directly
	If $iPos < 0 Then $iPos = $itemID
	If $iPos < 0 Or $iPos >= UBound($__DM_g_aMenuText) Then $iPos = 0

	Local $sText = $__DM_g_aMenuText[$iPos][1]

	; Calculate text dimensions
	Local $hDC = _WinAPI_GetDC($hWnd)
	Local $hOldFont = _WinAPI_SelectObject($hDC, $__DM_g_hMenuFont)
	Local $tSIZE = _WinAPI_GetTextExtentPoint32($hDC, $sText)
	Local $iTextWidth = $tSIZE.X
	Local $iTextHeight = $tSIZE.Y

	_WinAPI_SelectObject($hDC, $hOldFont)
	_WinAPI_ReleaseDC($hWnd, $hDC)

	; Set dimensions with padding (with high DPI)
	$t.itemWidth = $iTextWidth - (8 * $__DM_g_iDpiRatio)
	$t.itemHeight = $iTextHeight + 1

	Return 1
EndFunc   ;==>__GUIDarkMenu_WM_MEASUREITEM

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkMenu_WM_DRAWITEM($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	If Not _GUICtrlMenu_GetMenu($hWnd) Then Return $GUI_RUNDEFMSG
	Local $tagDRAWITEM = "uint CtlType;uint CtlID;uint itemID;uint itemAction;uint itemState;ptr hwndItem;handle hDC;" & _
			"long left;long top;long right;long bottom;ulong_ptr itemData"
	Local $t = DllStructCreate($tagDRAWITEM, $lParam)
	If Not IsDllStruct($t) Then Return $GUI_RUNDEFMSG

	If $t.CtlType <> $ODT_MENU Then Return $GUI_RUNDEFMSG

	Local $hDC = $t.hDC
	Local $iLeft = $t.left
	Local $iTop = $t.top
	Local $iRight = $t.right
	Local $iBottom = $t.bottom
	Local $state = $t.itemState
	Local $itemID = $t.itemID

	; convert itemID to position
	Local $iPos = -1
	For $i = 0 To UBound($__DM_g_aMenuText) - 1
		If $itemID = $__DM_g_aMenuText[$i][0] Then
			$iPos = $i
			ExitLoop
		EndIf
	Next

	If $iPos < 0 Then $iPos = $itemID
	If $iPos < 0 Or $iPos >= UBound($__DM_g_aMenuText) Then $iPos = 0

	Local $sText = $__DM_g_aMenuText[$iPos][1]

	; Colors
	Local $clrText = _WinAPI_SwitchColor($__DM_g_iMenuTextColor)

	; Draw item background (selected = lighter)
	Local $bSelected = BitAND($state, $ODS_SELECTED)
	Local $bHot = BitAND($state, $ODS_HOTLIGHT)
	Local $hBrush

	If $bSelected Then
		$hBrush = $__DM_g_hBrushMenuSel
	ElseIf $bHot Then
		$hBrush = $__DM_g_hBrushMenuHot
	Else
		$hBrush = $__DM_g_hBrushMenuBk
	EndIf

	Local $tItemRect = DllStructCreate($tagRECT)
	With $tItemRect
		.left = $iLeft
		.top = $iTop
		.right = $iRight
		.bottom = $iBottom
	EndWith

	_WinAPI_FillRect($hDC, $tItemRect, $hBrush)

	; Setup font
	Local $hOldFont = _WinAPI_SelectObject($hDC, $__DM_g_hMenuFont)

	_WinAPI_SetBkMode($hDC, $TRANSPARENT)
	If _WinAPI_GetForegroundWindow() <> $hWnd Then
		$clrText = $__DM_g_bUseDarkMode ? _WinAPI_ColorAdjustLuma($clrText, -30) : 0x6d6d6d
	EndIf
	_WinAPI_SetTextColor($hDC, $clrText)

	; Determine if keyboard cues (underlines) should be hidden based on ODS_NOACCEL (0x0100)
	Local $iDrawTextFlags = BitOR($DT_SINGLELINE, $DT_VCENTER, $DT_CENTER, $DT_NOCLIP)
	If BitAND($state, $ODS_NOACCEL) Then
		$iDrawTextFlags = BitOR($iDrawTextFlags, $DT_HIDEPREFIX)
	EndIf

	DllCall('user32.dll', "int", "DrawTextW", "handle", $hDC, "wstr", $sText, "int", -1, "ptr", _
			DllStructGetPtr($tItemRect), "uint", $iDrawTextFlags)

	_WinAPI_SelectObject($hDC, $hOldFont)

	Return 1
EndFunc   ;==>__GUIDarkMenu_WM_DRAWITEM

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkMenu_Register($hGui)
	; Get top menu handle
	Local $hMenu = _GUICtrlMenu_GetMenu($hGui)
	; Return from function if no top menu exists
	If Not $hMenu Then Return False

	; Create font
	;If Not $__DM_g_hMenuFont Then $__DM_g_hMenuFont = __GUIDarkMenu_CreateFont("Segoe UI", 9)
	Local $iDPI = __DM_WinAPI_GetDPIForWindow($hGui)
	If @error Then $iDPI = 96
	If Not $__DM_g_hMenuFont Then $__DM_g_hMenuFont = _PM_GetMenuFont($iDPI)

	$__DM_g_aMenuText = __GUIDarkMenu_GetTopMenuItems($hGui)

	For $i = 0 To UBound($__DM_g_aMenuText) - 1
		_GUICtrlMenu_SetItemType($hMenu, $i, $MFT_OWNERDRAW, True)
	Next
	__GUIDarkMenu_MenuBarBKColor($hMenu)

	; Register GUI-level window messages
	GUIRegisterMsg($WM_MEASUREITEM, "__GUIDarkMenu_WM_MEASUREITEM")
	GUIRegisterMsg($WM_DRAWITEM, "__GUIDarkMenu_WM_DRAWITEM")
	GUIRegisterMsg($WM_NCACTIVATE, "__GUIDarkMenu_WM_NCACTIVATE")
	GUIRegisterMsg($WM_WINDOWPOSCHANGED, "__GUIDarkMenu_WM_WINDOWPOSCHANGED")
EndFunc   ;==>_GUIDarkMenu_Register

; #FUNCTION# ====================================================================================================================
; Author.........: Nine
; Modified.......: WildByDesign, argumentum
; ===============================================================================================================================
Func __GUIDarkMenu_GetTopMenuItems($hWnd)
	Local $iItemID = 10000
	Local $hMenu = _GUICtrlMenu_GetMenu($hWnd)
	Local $nItem = _GUICtrlMenu_GetItemCount($hMenu)
	Local $aList[$nItem][2], $tInfo
	Local $tText, $iLen
	For $i = 0 To $nItem - 1
		$tInfo = _GUICtrlMenu_GetItemInfo($hMenu, $i)
		If Not $tInfo.ID Then
			_GUICtrlMenu_SetItemID($hMenu, $i, $iItemID)
			$aList[$i][0] = _GUICtrlMenu_GetItemID($hMenu, $i)
			$iItemID += 1
		Else
			$aList[$i][0] = $tInfo.ID
		EndIf
		;$aList[$i][1] = _GUICtrlMenu_GetItemText($hMenu, $i)
		; retrieve text via GetMenuStringW (works better than _GUICtrlMenu_GetItemText)
		$tText = DllStructCreate("wchar s[256]")
		$iLen = DllCall('user32.dll', "int", "GetMenuStringW", _
				"handle", $hMenu, _
				"uint", $i, _
				"struct*", $tText, _
				"int", 255, _
				"uint", $MF_BYPOSITION)

		If IsArray($iLen) And $iLen[0] > 0 Then
			$aList[$i][1] = $tText.s
		Else
			$aList[$i][1] = ""
		EndIf
	Next
	Return $aList
EndFunc   ;==>__GUIDarkMenu_GetTopMenuItems

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkMenu_SetColors($hWnd, $MenuBG, $MenuHot, $MenuSel, $MenuText)
	Local $hMenu = _GUICtrlMenu_GetMenu($hWnd)
	$__DM_g_iMenuBkColor = $MenuBG
	$__DM_g_iMenuHotColor = $MenuHot
	$__DM_g_iMenuSelColor = $MenuSel
	$__DM_g_iMenuTextColor = $MenuText
	; redraw menubar background area
	__GUIDarkMenu_MenuBarBKColor($hMenu)
	; redraw menubar and force refresh
	_GUICtrlMenu_DrawMenuBar($hWnd)
	_WinAPI_RedrawWindow($hWnd, 0, 0, BitOR($RDW_INVALIDATE, $RDW_UPDATENOW))
EndFunc   ;==>_GUIDarkMenu_SetColors

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkMenu_WM_WINDOWPOSCHANGED($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam
	If Not _GUICtrlMenu_GetMenu($hWnd) Then Return $GUI_RUNDEFMSG
	__GUIDarkMenu_PaintWhiteLine($hWnd)
	Return $GUI_RUNDEFMSG

	Local Static $iWPrev = 0, $iHPrev = 0
	Local $bPaintLine = False

	Local $tPos = DllStructCreate($tagWINDOWPOS, $lParam)

	Local $iX = DllStructGetData($tPos, "X")
	Local $iW = DllStructGetData($tPos, "CX")
	Local $iH = DllStructGetData($tPos, "CY")

	If $iX < 0 Then $bPaintLine = True
	If $iX + $iW > @DesktopWidth Then $bPaintLine = True

	If $iW <> $iWPrev Then $bPaintLine = True
	If $iH <> $iHPrev Then $bPaintLine = True

	$iWPrev = $iW
	$iHPrev = $iH

	If $bPaintLine And _GUICtrlMenu_GetMenu($hWnd) Then
		__GUIDarkMenu_PaintWhiteLine($hWnd)
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>__GUIDarkMenu_WM_WINDOWPOSCHANGED

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkMenu_WM_NCACTIVATE($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam
	If Not _GUICtrlMenu_GetMenu($hWnd) Then Return $GUI_RUNDEFMSG
	Local $iRet = _WinAPI_DefWindowProc($hWnd, $iMsg, $wParam, $lParam)
	__GUIDarkMenu_PaintWhiteLine($hWnd)

	Return $iRet
EndFunc   ;==>__GUIDarkMenu_WM_NCACTIVATE

; #FUNCTION# ====================================================================================================================
; Author.........: ahmet
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkMenu_PaintWhiteLine($hWnd)
	Local $tWindowRect = _WinAPI_GetWindowRect($hWnd)
	If @error Then Return

	Local $tClientRect = _WinAPI_GetClientRect($hWnd)
	Local $tPoint = _WinAPI_CreatePoint(0, 0)
	_WinAPI_ClientToScreen($hWnd, $tPoint)

	Local $iClientTopInWindow = DllStructGetData($tPoint, "Y") - DllStructGetData($tWindowRect, "Top")
	Local $iClientLeftInWindow = DllStructGetData($tPoint, "X") - DllStructGetData($tWindowRect, "Left")
	Local $iClientWidth = DllStructGetData($tClientRect, "Right")

	Local $tAnnoyingLine = DllStructCreate($tagRECT)
	DllStructSetData($tAnnoyingLine, "Left", $iClientLeftInWindow)
	DllStructSetData($tAnnoyingLine, "Right", $iClientLeftInWindow + $iClientWidth)
	DllStructSetData($tAnnoyingLine, "Top", $iClientTopInWindow - 1) ; 1px above client area
	DllStructSetData($tAnnoyingLine, "Bottom", $iClientTopInWindow)

	Local $hDC = _WinAPI_GetWindowDC($hWnd)

	_WinAPI_FillRect($hDC, $tAnnoyingLine, $__DM_g_hBrushGui)

	_WinAPI_ReleaseDC($hWnd, $hDC)
EndFunc   ;==>__GUIDarkMenu_PaintWhiteLine

; #FUNCTION# ====================================================================================================================
; Author.........: ProgAndy
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkMenu_MenuBarBKColor($hMenu)
	Local $tInfo = DllStructCreate("int Size;int Mask;int Style;int YMax;handle hBack;int ContextHelpID;ptr MenuData")
	DllStructSetData($tInfo, "Mask", 2)
	DllStructSetData($tInfo, "hBack", $__DM_g_hBrushMenuBk)
	DllStructSetData($tInfo, "Size", DllStructGetSize($tInfo))
	DllCall('user32.dll', "int", "SetMenuInfo", "hwnd", $hMenu, "ptr", DllStructGetPtr($tInfo))
EndFunc   ;==>__GUIDarkMenu_MenuBarBKColor

; #FUNCTION# ====================================================================================================================
; Author.........: ???
; ===============================================================================================================================
Func __GUIDarkMenu_CreateFont($sFontName, $nHeight = 9, $nWidth = 400)
	Local $stFontName = DllStructCreate("char[260]")
	DllStructSetData($stFontName, 1, $sFontName)
	Local $hDC = _WinAPI_GetDC(0)        ; Get the Desktops DC
	Local $nPixel = _WinAPI_GetDeviceCaps($hDC, 90)
	$nHeight = 0 - _WinAPI_MulDiv($nHeight, $nPixel, 72)
	_WinAPI_ReleaseDC(0, $hDC)
	Local $hFont = _WinAPI_CreateFont($nHeight, 0, 0, 0, $nWidth, False, False, False, _
			$DEFAULT_CHARSET, $OUT_DEFAULT_PRECIS, $CLIP_DEFAULT_PRECIS, $PROOF_QUALITY, $DEFAULT_PITCH, $sFontName)
	Return $hFont
EndFunc   ;==>__GUIDarkMenu_CreateFont

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign, MattyD
; ===============================================================================================================================
Func __DM_DialogProc($hWnd, $iMsg, $wParam, $lParam, $iSubClsID, $pData)
	#forceref $pData, $iSubClsID
	Local Const $DWMWA_USE_IMMERSIVE_DARK_MODE = 20
	Local Static $hBkColorBrush, $hFooterBrush
	Local Static $hFontCombo = 0, $hPreview = 0, $hStyle = 0, $hSize = 0, $hColor = 0, $hSample = 0, $hFontType = 0
	Local Static $hStrikeout = 0, $hUnderline = 0
	Local $hCtrl, $sClass, $hDC, $hOldFont, $tFont, $sFontName, $tRect, $iSize, $iWeight, $bItalic, $sText, $iColor, $iCharset
	Local $sType, $sFont, $iQuality, $bColor = False, $bBold = False, $bFontCombo = False
	Local Static $iFontIdxCur = 0, $bColorDlg = False, $bFontDlg = False, $bMsgBoxDlg = False, $iAlignDPI = 0

	Switch $iMsg
		Case $WM_SHOWWINDOW
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			Local $hParent = _WinAPI_GetParent($hWnd)
			Local $aChildPos = WinGetPos($hWnd)

			If IsHWnd($hParent) And BitAND(WinGetState($hParent), 2) Then
				Local $aParentPos = WinGetPos($hParent)

				; (Parent Start X) + (Half of Parent Width) - (Half of Dialog Width)
				Local $iNewX = $aParentPos[0] + ($aParentPos[2] / 2) - ($aChildPos[2] / 2)
				Local $iNewY = $aParentPos[1] + ($aParentPos[3] / 2) - ($aChildPos[3] / 2)
				WinMove($hWnd, "", $iNewX, $iNewY)
			Else
				; center on desktop since desktop is the parent
				WinMove($hWnd, "", (@DesktopWidth / 2 - ($aChildPos[2] / 2)), (@DesktopHeight / 2 - ($aChildPos[3] / 2)))
			EndIf

			If $bFontDlg And $__DM_g_bUseDarkMode Then
				Local $sFontOrig
				Local $aList = _GUICtrlComboBox_GetListArray($hFontCombo)
				_ArrayDelete($aList, 0)
				Dim $__DM_g_aFontList[UBound($aList)][5]
				For $i = UBound($__DM_g_aFontList) - 1 To 0 Step -1
					;For $i = 0 to UBound($__DM_g_aFontList) - 1
					$sFontOrig = $aList[$i]
					$__DM_g_aFontList[$i][0] = $sFontOrig
					;$__DM_g_aFontList[$i][2] = _GetFontCharSet($sFontOrig)
					If $sFontOrig = "Sitka" Then
						$__DM_g_aFontList[$i][1] = "Sitka Text"
						$sFontOrig = "Sitka Text"
					ElseIf $sFontOrig = "Segoe UI Variable" Then
						$__DM_g_aFontList[$i][1] = "Segoe UI Variable Text"
						$sFontOrig = "Segoe UI Variable Text"
					ElseIf $sFontOrig = "Franklin Gothic" Then
						$__DM_g_aFontList[$i][1] = "Franklin Gothic Medium"
						$sFontOrig = "Franklin Gothic Medium"
					ElseIf $sFontOrig = "Symbol" Then
						$__DM_g_aFontList[$i][1] = "Segoe UI"
						;$sFontOrig = "Segoe UI"
					ElseIf StringInStr($sFontOrig, "Icons") Or StringInStr($sFontOrig, "Assets") Then
						$__DM_g_aFontList[$i][1] = "Segoe UI"
						;$sFontOrig = "Segoe UI"
					Else
						$__DM_g_aFontList[$i][1] = $sFontOrig
					EndIf
					$__DM_g_aFontList[$i][2] = _GetFontCharSet($sFontOrig)
					$__DM_g_aFontList[$i][3] = _GetFontType($sFontOrig)
					If StringLeft($sFontOrig, 1) = "@" Then
						_GUICtrlComboBox_DeleteString($hFontCombo, $i)
						_ArrayDelete($__DM_g_aFontList, $i)
					EndIf
				Next
				If $hFontCombo Then $iFontIdxCur = _SendMessage($hFontCombo, $CB_GETCURSEL)
				_GUICtrlComboBox_SetCurSel($hFontCombo, _GUICtrlComboBox_GetCurSel($hFontCombo))
				;_ArrayDisplay($__DM_g_aFontList)
			EndIf

		Case $WM_DRAWITEM
			If Not $__DM_g_bUseDarkMode And Not $bFontDlg Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			Local Const $tagDRAWITEMSTRUCT = "uint CtlType;uint CtlID;uint itemID;uint itemAction;uint itemState;hwnd hwndItem;hwnd hDC;int rcItem[4];ulong_ptr itemData"
			Local $tDRAWITEM = DllStructCreate($tagDRAWITEMSTRUCT, $lParam)
			If Not IsDllStruct($tDRAWITEM) Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			$hDC = DllStructGetData($tDRAWITEM, "hDC")
			Local $iID = DllStructGetData($tDRAWITEM, "itemID")
			Local $iState = DllStructGetData($tDRAWITEM, "itemState")
			Local $hwndItem = DllStructGetData($tDRAWITEM, "hwndItem")
			Local $CtlID = DllStructGetData($tDRAWITEM, "CtlID")

			If $iID = -1 Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

			$sText = ""
			_GUICtrlComboBox_GetLBText($hwndItem, $iID, $sText)

			$sFont = $sText
			Local $hFont = 0
			$iSize = -(9 * _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY) / 72)
			;$iSize = -Round((9.5 * _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY) / 72))
			$iWeight = 400
			$bItalic = 0
			$iCharset = 0
			$iQuality = 0

			Switch $CtlID
				Case 1136    ; Font
					If $hFontCombo = 0 Then $hFontCombo = $hwndItem
					$bFontCombo = True
					$iCharset = $__DM_g_aFontList[$iID][2]
					;$sFont = $sText
					$sFont = $__DM_g_aFontList[$iID][1]
					$sText = $__DM_g_aFontList[$iID][0]
					$sType = $__DM_g_aFontList[$iID][3]
					If $iCharset = $SYMBOL_CHARSET Then
						$sFont = "Segoe UI"
					EndIf
					If $__DM_g_aFontList[$iID][4] Then
						$hFont = $__DM_g_aFontList[$iID][4]
					Else
						$tFont = DllStructCreate($tagLOGFONT)
						$tFont.FaceName = $sFont
						$tFont.Height = $iSize
						$tFont.CharSet = $DEFAULT_CHARSET
						$tFont.Quality = $iQuality
						$tFont.Italic = $bItalic
						$tFont.Underline = 0
						$tFont.Weight = 400
						$hFont = _WinAPI_CreateFontIndirect($tFont)
						$__DM_g_aFontList[$iID][4] = $hFont
					EndIf

					$hOldFont = _WinAPI_SelectObject($hDC, $hFont)
				Case 1137    ; Style
					If $hStyle = 0 Then $hStyle = $hwndItem
					Local $sFontCombo = $__DM_g_aFontList[$iFontIdxCur][0]
					$sFont = $sFontCombo
					$iCharset = $__DM_g_aFontList[$iFontIdxCur][2]
					$sFont = $sFontCombo & " " & $sText
					If StringInStr($sFont, "Oblique") Then
						$sFont = StringReplace($sFont, " Oblique", "")
						$bItalic = 1
					EndIf
					If $iCharset = $SYMBOL_CHARSET Then
						$sFont = "Segoe UI"
						$iCharset = $DEFAULT_CHARSET
						If StringInStr($sText, "Bold") Then $sFont = "Segoe UI Bold"
					Else
						$iCharset = $DEFAULT_CHARSET
					EndIf
					If StringInStr($sFont, "Icons") Or StringInStr($sFont, "Assets") Or StringInStr($sFont, "dings") Then
						$sFont = "Segoe UI"
						$iCharset = $DEFAULT_CHARSET
						If StringInStr($sText, "Bold") Then $sFont = "Segoe UI Bold"
					EndIf
					$sType = $__DM_g_aFontList[$iFontIdxCur][3]
					If $sType = $RASTER_FONTTYPE Then
						$sFont = $sFontCombo
					EndIf
					If StringInStr($sText, "Bold") Then
						$bBold = True
					EndIf
					$tFont = DllStructCreate($tagLOGFONT)
					$tFont.FaceName = $sFont
					$tFont.Height = $iSize
					$tFont.CharSet = $iCharset
					$tFont.Quality = $iQuality
					$tFont.Italic = $bItalic
					$tFont.Underline = 0
					$tFont.Weight = $bBold ? 700 : 400
					$hFont = _WinAPI_CreateFontIndirect($tFont)
					; Verify that correct font loaded, otherwise modify font
					$hOldFont = _WinAPI_SelectObject($hDC, $hFont)
					$sFontName = _WinAPI_GetTextFace($hDC)
					If $sFontName <> $sFont Then
						;ConsoleWrite("Getting: " & $sFontName & " - Should be: " & $sFont & @CRLF)
						_WinAPI_SelectObject($hDC, $hOldFont)
						_WinAPI_DeleteObject($hFont)
						$sFont = _WinAPI_GetWindowText($hFontCombo)
						$tFont = DllStructCreate($tagLOGFONT)
						$tFont.FaceName = $sFont
						$tFont.Height = $iSize
						$tFont.CharSet = $iCharset
						$tFont.Quality = $iQuality
						$tFont.Italic = $bItalic
						$tFont.Underline = 0
						$tFont.Weight = $bBold ? 700 : 400
						$hFont = _WinAPI_CreateFontIndirect($tFont)
						$hOldFont = _WinAPI_SelectObject($hDC, $hFont)
					EndIf
				Case 1138    ; Size
					If $hSize = 0 Then $hSize = $hwndItem
				Case 1139    ; Color
					If $hColor = 0 Then $hColor = $hwndItem
					$bColor = True
				Case 1140    ; Script
					Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndSwitch

			Local $hBrush
			If BitAND($iState, $ODS_SELECTED) Then
				$hBrush = $__DM_g_hBrushAccent
			Else
				$hBrush = $__DM_g_hBrushCtrl
			EndIf

			$tRect = DllStructCreate("int Left;int Top;int Right;int Bottom", DllStructGetPtr($tDRAWITEM, "rcItem"))
			_WinAPI_FillRect($hDC, DllStructGetPtr($tDRAWITEM, "rcItem"), $hBrush)

			Local $iLeft = DllStructGetData($tRect, "Left")
			Local $iTop = DllStructGetData($tRect, "Top")
			Local $iBottom = DllStructGetData($tRect, "Bottom")

			$iColor = $CLR_BLACK
			If $bColor Then
				Local $tColor = _WinAPI_CreateRectEx($iLeft + 2, $iTop + 2, Round(30 * $__DM_g_iDpiRatio), $iBottom - $iTop - 4)
				Local $hPen = $__DM_g_hPenLight
				_WinAPI_SelectObject($hDC, $hPen)
				Select
					Case $sText = 'Black'
						$iColor = $CLR_BLACK
					Case $sText = 'Maroon'
						$iColor = $CLR_MAROON
					Case $sText = 'Green'
						$iColor = $CLR_GREEN
					Case $sText = 'Olive'
						$iColor = $CLR_OLIVE
					Case $sText = 'Navy'
						$iColor = $CLR_NAVY
					Case $sText = 'Purple'
						$iColor = $CLR_PURPLE
					Case $sText = 'Teal'
						$iColor = $CLR_TEAL
					Case $sText = 'Gray'
						$iColor = $CLR_GRAY
					Case $sText = 'Silver'
						$iColor = $CLR_SILVER
					Case $sText = 'Red'
						$iColor = $CLR_RED
					Case $sText = 'Lime'
						$iColor = $CLR_LIME
					Case $sText = 'Yellow'
						$iColor = $CLR_YELLOW
					Case $sText = 'Blue'
						$iColor = $CLR_BLUE
					Case $sText = 'Fuchsia'
						$iColor = $CLR_FUCHSIA
					Case $sText = 'Aqua'
						$iColor = $CLR_AQUA
					Case $sText = 'White'
						$iColor = $CLR_WHITE
				EndSelect

				Local $hBrushColor = _WinAPI_CreateSolidBrush($iColor)
				_WinAPI_SelectObject($hDC, $hBrushColor)
				_WinAPI_RoundRect($hDC, $tColor, 4, 4)
				_WinAPI_DeleteObject($hBrushColor)
			EndIf

			_WinAPI_SetBkMode($hDC, $TRANSPARENT)
			_WinAPI_SetTextColor($hDC, 0xFFFFFF)

			; Get height of rectangle to help determine vertical centering for _WinAPI_ExtTextOut
			;Local $tSIZE = _WinAPI_GetTextExtentPoint32($hDC, "This is just a TEST!")
			;Local $iTextHeight = $tSIZE.Y

			Local $tRectText = DllStructCreate("int Left;int Top;int Right;int Bottom", DllStructGetPtr($tDRAWITEM, "rcItem"))
			DllStructSetData($tRectText, "Left", DllStructGetData($tRectText, "Left") + 2 + ($bColor ? Round(35 * $__DM_g_iDpiRatio) : 0))
			DllStructSetData($tRectText, "Top", DllStructGetData($tRectText, "Top"))
			Local $iRectHeight = DllStructGetData($tRectText, "Bottom") - DllStructGetData($tRectText, "Top")

			Local $iDPI = 5 + $iAlignDPI

			_WinAPI_SetTextAlign($hDC, BitOR($TA_BASELINE, $TA_LEFT, $TA_NOUPDATECP))
			Local $iOptions = $ETO_CLIPPED
			Local $iLeftTextOut = DllStructGetData($tRectText, "Left")
			Local $iTopTextOut = DllStructGetData($tRectText, "Top")
			_WinAPI_ExtTextOut($hDC, $iLeftTextOut, $iTopTextOut + ($iRectHeight / 2) + $iDPI, $iOptions, $sText, DllStructGetPtr($tRectText))

			_WinAPI_SelectObject($hDC, $hOldFont)
			If Not $bFontCombo Then _WinAPI_DeleteObject($hFont)

			Return 1 ; this prevents system from handling the ownerdraw

		Case $WM_NCCREATE
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			_WinAPI_DwmSetWindowAttribute($hWnd, $DWMWA_USE_IMMERSIVE_DARK_MODE, True)

		Case $WM_INITDIALOG
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			$hBkColorBrush = $__DM_g_hBrushMsgBoxTop
			$hFooterBrush = $__DM_g_hBrushMsgBoxBottom

			; Update DPI ratio
			$__DM_g_iDpiRatio = Round(__DM_WinAPI_GetDPIForWindow($hWnd) / 96, 2)
			If @error Then $__DM_g_iDpiRatio = 1

			; DPI adjustment for combo item vertical alignment in WM_DRAWITEM
			Switch ($__DM_g_iDpiRatio * 100)
				Case 100
					$iAlignDPI = 0
				Case 125
					$iAlignDPI = 0
				Case 150
					$iAlignDPI = 2
				Case 175
					$iAlignDPI = 3
				Case 200
					$iAlignDPI = 4
				Case 225
					$iAlignDPI = 5
				Case 250
					$iAlignDPI = 6
				Case 275
					$iAlignDPI = 7
				Case 300
					$iAlignDPI = 8
				Case Else
					$iAlignDPI = 1
			EndSwitch

			; Find all controls on Dialog box to apply dark theme
			Local $aCtrls = _WinAPI_EnumChildWindows($hWnd, False)
			If @error = 0 Then
				For $i = 1 To $aCtrls[0][0]
					$hCtrl = $aCtrls[$i][0]
					$sClass = $aCtrls[$i][1]
					;ConsoleWrite("class: " & $aCtrls[$i][1] & @CRLF)
					Switch _WinAPI_GetDlgCtrlID($hCtrl)
						Case 710    ; Color Dialog Color Mixer
							If _WinAPI_GetClassName($hCtrl) = 'Static' Then $bColorDlg = True
						Case 1136    ; Font
							If $hFontCombo = 0 Then $hFontCombo = $hCtrl
						Case 1137   ; Style
							If $hStyle = 0 Then $hStyle = $hCtrl
						Case 1138   ; Size
							If $hSize = 0 Then $hSize = $hCtrl
						Case 1139   ; Color
							If $hColor = 0 Then $hColor = $hCtrl
						Case 1140   ; Script
						Case 1073   ; Sample group box
							If $hSample = 0 Then $hSample = $hCtrl
							If _WinAPI_GetClassName($hCtrl) = 'Button' Then $bFontDlg = True
						Case 1093   ; Font Type
							If $hFontType = 0 Then $hFontType = $hCtrl
						Case 1040   ; Strikeout
							If $hStrikeout = 0 Then $hStrikeout = $hCtrl
						Case 1041   ; Underline
							If $hUnderline = 0 Then $hUnderline = $hCtrl
						Case 65535    ; MsgBox Static control
							If _WinAPI_GetClassName($hCtrl) = 'Static' Then $bMsgBoxDlg = True
					EndSwitch
				Next

				; Windows 11 (Build 22000) öncesinde MsgBox'a müdahale etme
If Not $darkmode Then
If $bMsgBoxDlg And @OSBuild < $osbuild Then
    ; Başlık çubuğundaki koyu modu geri al
    _WinAPI_DwmSetWindowAttribute($hWnd, $DWMWA_USE_IMMERSIVE_DARK_MODE, False)

    $bMsgBoxDlg = False
    Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndIf
EndIf

				; Remove subclass if this is not a Font, Color or MsgBox dialog
				If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
					;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
					Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
				EndIf

				For $i = 1 To $aCtrls[0][0]
					$hCtrl = $aCtrls[$i][0]
					$sClass = $aCtrls[$i][1]
					If $sClass = "Button" Then
						Local $sStyles = __GUIDarkTheme_hWnd2Styles($hCtrl)
						Select
							Case StringInStr($sStyles, "BS_GROUPBOX")
								If $__DM_g_b24H2Plus Then
									_WinAPI_SetWindowTheme($hCtrl, "DarkMode_DarkTheme")
									_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
								Else
									If Not $__DM_g_hGroupProc Then
										$__DM_g_hGroupProc = DllCallbackRegister(__GUIDarkTheme_GroupProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
										$__DM_g_pGroupProc = DllCallbackGetPtr($__DM_g_hGroupProc)
									EndIf
									_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer", "Button")
									_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
									_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pGroupProc, $hCtrl, $__DM_g_hGroupProc)
								EndIf
							Case StringInStr($sStyles, "CHECKBOX")
								If $__DM_g_b24H2Plus Then
									_WinAPI_SetWindowTheme($hCtrl, "DarkMode_DarkTheme")
									_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
								Else
									If Not $__DM_g_hButtonProc Then
										$__DM_g_hButtonProc = DllCallbackRegister(__GUIDarkTheme_ButtonProc, "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
										$__DM_g_pButtonProc = DllCallbackGetPtr($__DM_g_hButtonProc)
									EndIf
									_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer", "Button")
									_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
									_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pButtonProc, $hCtrl, $__DM_g_hButtonProc)
								EndIf
							Case Else
								_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer")
								_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
						EndSelect
					ElseIf $sClass = "Edit" Then
						_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer")
						_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
						_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
						If $bColorDlg Then
							_WinAPI_SetWindowSubclass($hCtrl, $__DM_g_pSubclassProc, $hCtrl, $__DM_g_hSubclassProc)
						EndIf
						_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
					ElseIf $sClass = "ComboBox" Then
						_WinAPI_SetWindowTheme($hCtrl, $__DM_g_b24H2Plus ? "DarkMode_DarkTheme" : "DarkMode_CFD")
						_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
					ElseIf $sClass = "ComboLBox" Then
						_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer")
						_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
						_WinAPI_SetWindowLong($hCtrl, $GWL_EXSTYLE, BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_EXSTYLE), BitNOT($WS_EX_CLIENTEDGE)))
						_WinAPI_SetWindowLong($hCtrl, $GWL_STYLE, BitOR(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $WS_BORDER))
						_WinAPI_SetWindowPos($hCtrl, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
					ElseIf $sClass = "SysLink" Then
						_GUICtrlSysLink_AllowColoring($hCtrl)
					ElseIf $sClass = "Static" Then
						If _WinAPI_GetDlgCtrlID($hCtrl) = 1092 Then $hPreview = $hCtrl
					Else
						_WinAPI_SetWindowTheme($hCtrl, "DarkMode_Explorer")
						_SendMessage($hCtrl, $WM_THEMECHANGED, 0, 0)
					EndIf
				Next
			EndIf

			If $bFontDlg Or $bColorDlg Then
				$hBkColorBrush = $__DM_g_hBrushGui
			EndIf

		Case $WM_NOTIFY
			If Not $bFontDlg Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
			Local $hFrom = $tNMHDR.hWndFrom
			Local $iCode = $tNMHDR.Code

			If _WinAPI_GetClassName($hFrom) = "SysLink" Then
				If $iCode = $NM_CLICK Then _WinAPI_SetFocus(_WinAPI_GetParent($hFrom))
			EndIf

			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_CTLCOLORSTATIC
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			$hCtrl = HWnd($lParam)
			If _WinAPI_GetClassName($hCtrl) = "SysLink" Then
				_WinAPI_SetTextColor($wParam, _WinAPI_SwitchColor(0x60cdff))
			Else
				_WinAPI_SetTextColor($wParam, $__DM_g_iMsgBoxTextColor)
			EndIf
			_WinAPI_SetBkMode($wParam, $TRANSPARENT)
			Return $hBkColorBrush

		Case $WM_CTLCOLORDLG
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			_WinAPI_SetBkMode($wParam, $TRANSPARENT)
			_WinAPI_SetTextColor($wParam, $__DM_g_iMsgBoxTextColor)
			Return $hBkColorBrush

		Case $WM_CTLCOLORLISTBOX, $WM_CTLCOLOREDIT
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			_WinAPI_SetBkMode($wParam, $TRANSPARENT)
			_WinAPI_SetTextColor($wParam, $__DM_g_iMsgBoxTextColor)
			Return $__DM_g_hBrushCtrl

		Case $WM_CTLCOLORBTN
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			; SetTextColor is used for focus rectangle in WM_CTLCOLORBTN
			_WinAPI_SetTextColor($wParam, 0x000000)
			If $bFontDlg Or $bColorDlg Then
				Return $hBkColorBrush
			Else
				Return $hFooterBrush
			EndIf

		Case $WM_PAINT
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			If $bFontDlg Then
				Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
				$hDC = _WinAPI_BeginPaint($hWnd, $tPaint)
				Local $tFontRect = _WinAPI_GetWindowRect($hPreview)
				Local $iLeft2 = DllStructGetData($tFontRect, "Left")
				Local $iRight2 = DllStructGetData($tFontRect, "Right")
				Local $iTop2 = DllStructGetData($tFontRect, "Top")
				Local $iBottom2 = DllStructGetData($tFontRect, "Bottom")
				Local $bUnderline = 0, $bStrikeout = 0
				Local $iUnderline = _GUICtrlButton_GetState($hUnderline)
				If BitAND($iUnderline, $BST_CHECKED) Then $bUnderline = 1
				Local $iStrikeout = _GUICtrlButton_GetState($hStrikeout)
				If BitAND($iStrikeout, $BST_CHECKED) Then $bStrikeout = 1
				$sFontName = _WinAPI_GetWindowText($hFontCombo)
				Local $sTypeText = _GetFontTypeText($sFontName)
				_WinAPI_SetWindowText($hFontType, $sTypeText)
				Local $tPR = _WinAPI_GetWindowRect($hWnd)
				;Local $tCR = _WinAPI_GetWindowRect($hPreview)
				Local $tCR = _WinAPI_GetWindowRect($hSample)
				Local $iLeft1 = $tCR.left - $tPR.left
				;Local $top = $tCR.top - $tPR.top
				Local $iTop1 = $tCR.top - $tPR.top
				;Local $right = $tCR.right - $tPR.left
				;Local $bottom = $tCR.bottom - $tPR.top
				$tRect = _WinAPI_CreateRectEx($iLeft1 + 1, $iTop1 - 10, ($iRight2 - $iLeft2), $iBottom2 - $iTop2)
				_WinAPI_FillRect($hDC, $tRect, $__DM_g_hBrushGui)
				$iSize = _WinAPI_GetWindowText($hSize)
				$iWeight = 400
				$bItalic = 0
				$sText = _WinAPI_GetWindowText($hColor)
				Select
					Case $sText = 'Black'
						$iColor = $CLR_BLACK
					Case $sText = 'Maroon'
						$iColor = $CLR_MAROON
					Case $sText = 'Green'
						$iColor = $CLR_GREEN
					Case $sText = 'Olive'
						$iColor = $CLR_OLIVE
					Case $sText = 'Navy'
						$iColor = $CLR_NAVY
					Case $sText = 'Purple'
						$iColor = $CLR_PURPLE
					Case $sText = 'Teal'
						$iColor = $CLR_TEAL
					Case $sText = 'Gray'
						$iColor = $CLR_GRAY
					Case $sText = 'Silver'
						$iColor = $CLR_SILVER
					Case $sText = 'Red'
						$iColor = $CLR_RED
					Case $sText = 'Lime'
						$iColor = $CLR_LIME
					Case $sText = 'Yellow'
						$iColor = $CLR_YELLOW
					Case $sText = 'Blue'
						$iColor = $CLR_BLUE
					Case $sText = 'Fuchsia'
						$iColor = $CLR_FUCHSIA
					Case $sText = 'Aqua'
						$iColor = $CLR_AQUA
					Case $sText = 'White'
						$iColor = $CLR_WHITE
				EndSelect
				$iCharset = $DEFAULT_CHARSET
				$iQuality = 0
				;$sFont = _WinAPI_GetWindowText($hFontCombo) & " " & _WinAPI_GetWindowText($hStyle)
				$sFont = $__DM_g_aFontList[$iFontIdxCur][0] & " " & _WinAPI_GetWindowText($hStyle)
				If StringInStr($sFont, "Oblique") Then
					$sFont = StringReplace($sFont, " Oblique", "")
					$bItalic = 1
				EndIf
				If StringInStr(_WinAPI_GetWindowText($hStyle), "Bold") Then
					$bBold = True
				EndIf
				$tFont = DllStructCreate($tagLOGFONT)
				$sType = $__DM_g_aFontList[$iFontIdxCur][3]
				If $sType = $RASTER_FONTTYPE Then
					;$sFont = _WinAPI_GetWindowText($hFontCombo)
					$sFont = $__DM_g_aFontList[$iFontIdxCur][0]
					$iWeight = $bBold ? 700 : 400
					;$tFont.Height = $iSize
					;$tFont.Height = _GUICtrlComboBox_GetEditText($hSize)
					;$iQuality = $PROOF_QUALITY
				Else
					;$tFont.Height = -($iSize * _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY) / 72)
				EndIf
				;If $sType <> $RASTER_FONTTYPE Then $tFont.Height = -($iSize * _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY) / 72)
				$tFont.FaceName = $sFont
				$tFont.Height = -($iSize * _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY) / 72)
				$tFont.CharSet = $iCharset
				$tFont.Quality = $iQuality
				$tFont.Italic = $bItalic
				$tFont.Underline = $bUnderline
				$tFont.StrikeOut = $bStrikeout
				$tFont.Weight = $iWeight
				$hFont = _WinAPI_CreateFontIndirect($tFont)
				$hOldFont = _WinAPI_SelectObject($hDC, $hFont)
				; Verify that correct font loaded, otherwise modify font
				$sFontName = _WinAPI_GetTextFace($hDC)
				If $sFontName <> $sFont Then
					_WinAPI_SelectObject($hDC, $hOldFont)
					_WinAPI_DeleteObject($hFont)
					$sFont = _WinAPI_GetWindowText($hFontCombo)
					$tFont = DllStructCreate($tagLOGFONT)
					$tFont.FaceName = $sFont
					If $sType = $RASTER_FONTTYPE Then
						;$tFont.Height = _GUICtrlComboBox_GetEditText($hSize)
						;$iQuality = $PROOF_QUALITY
					EndIf
					;If $sType <> $RASTER_FONTTYPE Then $tFont.Height = -($iSize * _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY) / 72)
					$tFont.Height = -($iSize * _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY) / 72)
					$tFont.CharSet = $iCharset
					$tFont.Quality = $iQuality
					$tFont.Italic = $bItalic
					$tFont.Underline = $bUnderline
					$tFont.StrikeOut = $bStrikeout
					$tFont.Weight = $iWeight
					$hFont = _WinAPI_CreateFontIndirect($tFont)
					$hOldFont = _WinAPI_SelectObject($hDC, $hFont)
				EndIf

				_WinAPI_SetBkMode($hDC, $TRANSPARENT)
				_WinAPI_SetTextColor($hDC, $iColor)

				DllStructSetData($tRect, "Top", DllStructGetData($tRect, "Top") - 10)
				_WinAPI_DrawText($hDC, "AaBbYyZz", DllStructGetPtr($tRect), BitOR($DT_CENTER, $DT_VCENTER, $DT_SINGLELINE, $DT_NOCLIP))
				_WinAPI_SelectObject($hDC, $hOldFont)
				_WinAPI_DeleteObject($hFont)
				_WinAPI_EndPaint($hWnd, $tPaint)
				Return 0
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			If $bColorDlg Or $bFontDlg Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			; Painting below is for dark MsgBox
			Local $tPS = DllStructCreate($tagPAINTSTRUCT)
			$hDC = _WinAPI_BeginPaint($hWnd, $tPS)
			Local $tPaintRect = DllStructCreate($tagRECT, DllStructGetPtr($tPS, "rPaint"))
			$tPaintRect.Top = ($tPaintRect.Bottom - (48 * $__DM_g_iDpiRatio)) ; this depends on DPI scale
			_WinAPI_FillRect($hDC, $tPaintRect, $hFooterBrush)
			_WinAPI_EndPaint($hWnd, $tPS)
			Return True

		Case $WM_COMMAND
			If Not $__DM_g_bUseDarkMode And Not $bFontDlg Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If Not $bColorDlg And Not $bFontDlg And Not $bMsgBoxDlg Then
				;_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf
			Local $iNotifCode = _WinAPI_HiWord($wParam)
			Local $iItemID = _WinAPI_LoWord($wParam)
			Local $hWndFrom = $lParam
			If $hWndFrom = $hFontCombo Then
				If $iNotifCode = $CBN_SELCHANGE Then
					$iFontIdxCur = _SendMessage($hFontCombo, $CB_GETCURSEL)
					$sType = $__DM_g_aFontList[$iFontIdxCur][3]
					If $sType = $RASTER_FONTTYPE Then
						$sFont = $__DM_g_aFontList[$iFontIdxCur][0]
						_GetFontSizes($sFont)
						;_ArrayDisplay($__DM_g_aFontSizes)
						AdlibRegister("_UpdateFontSizes", 50)
					EndIf
				EndIf
			EndIf
			If (Not $lParam) Or ($iNotifCode = $BN_CLICKED) Then
				If Not $bColorDlg And Not $bFontDlg Then
					;_WinAPI_PostMessage($hWnd, $IDABORT, $wParam, $lParam)
					Return _WinAPI_EndDialog($hWnd, $iItemID)
				EndIf
			EndIf

		Case $WM_DESTROY
			$hFontCombo = 0
			$hPreview = 0
			$hStyle = 0
			$hSize = 0
			$hColor = 0
			$hSample = 0
			$hFontType = 0
			$hStrikeout = 0
			$hUnderline = 0
			$bColorDlg = False
			$bFontDlg = False
			$bMsgBoxDlg = False
			For $i = 0 To UBound($__DM_g_aFontList) - 1
				If $__DM_g_aFontList[$i][4] Then _WinAPI_DeleteObject($__DM_g_aFontList[$i][4])
			Next
			$__DM_g_aFontList = 0
			_WinAPI_SetActiveWindow(_WinAPI_GetParent($hWnd))
			_WinAPI_RemoveWindowSubclass($hWnd, $__DM_g_pDialogProc, $iSubClsID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
	EndSwitch
	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__DM_DialogProc

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign, MattyD
; ===============================================================================================================================
Func __DM_CBTHookProc($nCode, $wParam, $lParam)
	Local Const $hWnd = HWnd($wParam)
	If $nCode < 0 Then Return _WinAPI_CallNextHookEx($__DM_g_hThreadID_WH_CBT, $nCode, $wParam, $lParam)
	Switch $nCode
		Case $HCBT_CREATEWND
			Switch _WinAPI_GetClassName($hWnd)
				Case "#32770"
					; Subclass Dialog window
					_WinAPI_SetWindowSubclass($hWnd, $__DM_g_pDialogProc, 1000)
			EndSwitch
	EndSwitch
	Return _WinAPI_CallNextHookEx($__DM_g_hThreadID_WH_CBT, $nCode, $wParam, $lParam)
EndFunc   ;==>__DM_CBTHookProc

; #FUNCTION# ====================================================================================================================
; Author.........: MattyD
; ===============================================================================================================================
Func _WinAPI_EndDialog($hWnd, $iReturn)
	Local $aCall = DllCall('user32.dll', "bool", "EndDialog", "hwnd", $hWnd, "int_ptr", $iReturn)
	If @error Then Return SetError(@error, @extended, False)
	Return $aCall[0]
EndFunc   ;==>_WinAPI_EndDialog

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_SubclassCleanup()
	If $__DM_g_hDateProc Then DllCallbackFree($__DM_g_hDateProc)
	$__DM_g_hDateProc = 0
	$__DM_g_pDateProc = 0
	If $__DM_g_hScrollbarProc Then DllCallbackFree($__DM_g_hScrollbarProc)
	$__DM_g_hScrollbarProc = 0
	$__DM_g_pScrollbarProc = 0
	If $__DM_g_hWndProc Then DllCallbackFree($__DM_g_hWndProc)
	$__DM_g_hWndProc = 0
	$__DM_g_pWndProc = 0
	If $__DM_g_hSysLinkProc Then DllCallbackFree($__DM_g_hSysLinkProc)
	$__DM_g_hSysLinkProc = 0
	$__DM_g_pSysLinkProc = 0
	If $__DM_g_hStatusProc Then DllCallbackFree($__DM_g_hStatusProc)
	$__DM_g_hStatusProc = 0
	$__DM_g_pStatusProc = 0
	If $__DM_g_hIpAddrProc Then DllCallbackFree($__DM_g_hIpAddrProc)
	$__DM_g_hIpAddrProc = 0
	$__DM_g_pIpAddrProc = 0
	If $__DM_g_hHotkeyProc Then DllCallbackFree($__DM_g_hHotkeyProc)
	$__DM_g_hHotkeyProc = 0
	$__DM_g_pHotkeyProc = 0
	If $__DM_g_hTrackbarProc Then DllCallbackFree($__DM_g_hTrackbarProc)
	$__DM_g_hTrackbarProc = 0
	$__DM_g_pTrackbarProc = 0
	If $__DM_g_hGroupProc Then DllCallbackFree($__DM_g_hGroupProc)
	$__DM_g_hGroupProc = 0
	$__DM_g_pGroupProc = 0
	If $__DM_g_hButtonProc Then DllCallbackFree($__DM_g_hButtonProc)
	$__DM_g_hButtonProc = 0
	$__DM_g_pButtonProc = 0
	If $__DM_g_hUpDownProc Then DllCallbackFree($__DM_g_hUpDownProc)
	$__DM_g_hUpDownProc = 0
	$__DM_g_pUpDownProc = 0
	If $__DM_g_hSubclassProc Then DllCallbackFree($__DM_g_hSubclassProc)
	$__DM_g_hSubclassProc = 0
	$__DM_g_pSubclassProc = 0
	If $__DM_g_hTabProc Then DllCallbackFree($__DM_g_hTabProc)
	$__DM_g_hTabProc = 0
	$__DM_g_pTabProc = 0
EndFunc   ;==>__GUIDarkTheme_SubclassCleanup

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_IPAddrProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Local $hDC, $hBrush
	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_ERASEBKGND
			If _WinAPI_GetClassName($hWnd) <> 'SysIPAddress32' Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			_WinAPI_FillRect($wParam, _WinAPI_GetClientRect($hWnd), $__DM_g_hBrushCtrl)
			Return 1 ; Prevent background erasing to avoid flickering

		Case $WM_CTLCOLOREDIT
			If _WinAPI_GetClassName($hWnd) <> 'SysIPAddress32' Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			$hDC = $wParam
			_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
			_WinAPI_SetBkMode($hDC, $TRANSPARENT)
			$hBrush = $__DM_g_hBrushCtrl
			Return $hBrush

		Case $WM_NCHITTEST
			Local $aRet = DllCall("user32.dll", "lresult", "DefWindowProcW", _
					"hwnd", $hWnd, _
					"uint", $iMsg, _
					"wparam", $wParam, _
					"lparam", $lParam)

			If @error Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

			Local $iHitTest = $aRet[0]
			If $iHitTest = $HTNOWHERE Then Return $HTCLIENT

			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_NCCALCSIZE
			Local $tRect
			If _WinAPI_GetClassName($hWnd) <> 'Edit' Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			If $wParam Then
				Local $iRet = __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
				$tRect = DllStructCreate($tagRECT, $lParam)
				$tRect.left += 2
				$tRect.top += 3
				$tRect.right -= 1
				$tRect.bottom -= 3

				Return $iRet
			EndIf

		Case $WM_PAINT
			If _WinAPI_GetClassName($hWnd) <> 'SysIPAddress32' Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
			$hDC = _WinAPI_BeginPaint($hWnd, $tPaint)

			Local $tClient = _WinAPI_GetClientRect($hWnd)
			Local $iWidth = $tClient.Right
			Local $iHeight = $tClient.Bottom

			; Prepare Double Buffering
			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			; exclude child edit boxes
			Local $hEdit[4], $iLefts[4], $iRights[4]
			Local $hChild = _WinAPI_GetWindow($hWnd, $GW_CHILD)
			Local $tCR, $tPR = _WinAPI_GetWindowRect($hWnd)
			Local $iLeft, $iTop, $iRight, $iBottom
			Local $iCount = 0

			While $hChild And $iCount < 4
				; Collect measurements for painting dots
				$hEdit[$iCount] = $hChild
				Local $tBoxRect = DllStructCreate("int;int;int;int")
				DllCall("user32.dll", "bool", "GetWindowRect", "hwnd", $hChild, "ptr", DllStructGetPtr($tBoxRect))

				Local $tPointL = DllStructCreate("int;int")
				DllStructSetData($tPointL, 1, DllStructGetData($tBoxRect, 1))
				DllCall("user32.dll", "bool", "ScreenToClient", "hwnd", $hWnd, "ptr", DllStructGetPtr($tPointL))
				$iLefts[$iCount] = DllStructGetData($tPointL, 1)

				Local $tPointR = DllStructCreate("int;int")
				DllStructSetData($tPointR, 1, DllStructGetData($tBoxRect, 3))
				DllCall("user32.dll", "bool", "ScreenToClient", "hwnd", $hWnd, "ptr", DllStructGetPtr($tPointR))
				$iRights[$iCount] = DllStructGetData($tPointR, 1)

				; Exclude child Edit boxes from painting
				$tCR = _WinAPI_GetWindowRect($hChild)

				$iLeft = ($tCR.left > $tPR.left ? $tCR.left : $tPR.left) - $tPR.left
				$iTop = ($tCR.top > $tPR.top ? $tCR.top : $tPR.top) - $tPR.top
				$iRight = ($tCR.right < $tPR.right ? $tCR.right : $tPR.right) - $tPR.left
				$iBottom = ($tCR.bottom < $tPR.bottom ? $tCR.bottom : $tPR.bottom) - $tPR.top

				DllCall("gdi32.dll", "int", "ExcludeClipRect", "handle", $hMemDC, "int", $iLeft, "int", $iTop, "int", $iRight, "int", $iBottom)
				DllCall("gdi32.dll", "int", "ExcludeClipRect", "handle", $hDC, "int", $iLeft, "int", $iTop, "int", $iRight, "int", $iBottom)

				$hChild = _WinAPI_GetWindow($hChild, $GW_HWNDNEXT)
				$iCount += 1
			WEnd

			; Sort array left-to-right
			For $i = 0 To $iCount - 1
				For $j = $i + 1 To $iCount - 1
					If $iLefts[$i] > $iLefts[$j] Then
						Local $vTmp = $iLefts[$i]
						$iLefts[$i] = $iLefts[$j]
						$iLefts[$j] = $vTmp
						$vTmp = $iRights[$i]
						$iRights[$i] = $iRights[$j]
						$iRights[$j] = $vTmp
						$vTmp = $hEdit[$i]
						$hEdit[$i] = $hEdit[$j]
						$hEdit[$j] = $vTmp
					EndIf
				Next
			Next

			; Fill background
			$hBrush = $__DM_g_hBrushCtrl
			_WinAPI_FillRect($hMemDC, $tClient, $hBrush)

			; Copy memory DC to screen DC (BitBlt)
			_WinAPI_BitBlt($hDC, 0, 0, $iWidth, $iHeight, $hMemDC, 0, 0, $SRCCOPY)

			; GDI+
			Local $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hWnd)
			_GDIPlus_GraphicsSetSmoothingMode($hGraphics, 2)
			Local $hBrushDot = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
			Local $hPenBorder = _GDIPlus_PenCreate(0xFF7A7A7A, 1)  ; Flat grey border line

			; Render clean anti-aliased dots exactly in the center of the dark channels
			Local $iDotRadius = Int($iHeight * 0.05)
			If $iDotRadius < 2 Then $iDotRadius = 2
			$iDotRadius = 1

			For $i = 0 To 2
				If $i < $iCount - 1 Then
					Local $iRightA = $iRights[$i]
					Local $iLeftB = $iLefts[$i + 1]
					Local $iDotCenterX = $iRightA + (($iLeftB - $iRightA) / 2)
					Local $iDotCenterY = $iHeight - ($iHeight / 3)
					_GDIPlus_GraphicsFillEllipse($hGraphics, $iDotCenterX - $iDotRadius, $iDotCenterY - $iDotRadius, $iDotRadius * 2, $iDotRadius * 2, $hBrushDot)
				EndIf
			Next

			; Apply clean, custom single-pixel border around the newly flattened control edge
			_GDIPlus_GraphicsDrawRect($hGraphics, 0, 0, $iWidth - 1, $iHeight - 1, $hPenBorder)

			; Cleanup GDI+
			_GDIPlus_PenDispose($hPenBorder)
			_GDIPlus_BrushDispose($hBrushDot)
			_GDIPlus_GraphicsDispose($hGraphics)

			; Cleanup
			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)

			_WinAPI_EndPaint($hWnd, $tPaint)
			Return 0
	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_IPAddrProc

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_TrackbarProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	Switch $iMsg
		Case $WM_ERASEBKGND
			; Return 1 to prevent Windows from filling the slider background with white
			Return 1

		Case $WM_THEMECHANGED, $WM_DPICHANGED_AFTERPARENT
			; Theme handles become invalid after theme changes or DPI changes
			If $__DM_g_hThemeTrackbar Then
				_WinAPI_CloseThemeData($__DM_g_hThemeTrackbar)
				$__DM_g_hThemeTrackbar = 0
			EndIf

			Return 0

		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			If $__DM_g_hThemeTrackbar Then
				_WinAPI_CloseThemeData($__DM_g_hThemeTrackbar)
				$__DM_g_hThemeTrackbar = 0
			EndIf
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
	EndSwitch
	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_TrackbarProc

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_HotkeyProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_ERASEBKGND
			Return 1 ; Prevent background erasing to avoid flickering

		Case $WM_PAINT
			Local $tPaint = DllStructCreate($tagPAINTSTRUCT)
			Local $hDC = _WinAPI_BeginPaint($hWnd, $tPaint)

			Local $tClient = _WinAPI_GetClientRect($hWnd)
			Local $iWidth = $tClient.Right
			Local $iHeight = $tClient.Bottom

			; Prepare Double Buffering
			Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
			Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
			Local $hOldBmp = _WinAPI_SelectObject($hMemDC, $hBitmap)

			_WinAPI_FillRect($hMemDC, $tClient, $__DM_g_hBrushCtrl)

			; Get text
			Local $sHotkeyText = _Hotkey_GetText($hWnd)

			; Setup font
			Local $hFont = _SendMessage($hWnd, $WM_GETFONT, 0, 0)
			If Not $hFont Then $hFont = _WinAPI_GetStockObject($DEFAULT_GUI_FONT)
			Local $hOldFont = _WinAPI_SelectObject($hMemDC, $hFont)

			Local $tTextRect = DllStructCreate($tagRECT)
			With $tTextRect
				.Left = $tClient.Left + 6
				.Top = $tClient.Top + 5
				.Right = $tClient.Right - 6
				.Bottom = $tClient.Bottom - 3
			EndWith

			_WinAPI_SetBkMode($hMemDC, $TRANSPARENT)
			_WinAPI_SetTextColor($hMemDC, $__DM_g_iTextColor)

			Local $iTextFlags = BitOR($DT_SINGLELINE, $DT_LEFT, $DT_NOCLIP, $DT_VCENTER)
			_WinAPI_DrawText($hMemDC, $sHotkeyText, $tTextRect, $iTextFlags)

			; Track Caret position precisely at the end of the calculated text layout width
			Local $tSIZE = _WinAPI_GetTextExtentPoint32($hMemDC, $sHotkeyText)

			; Set Caret position when control has focus
			If _WinAPI_GetFocus() = $hWnd Then
				Local $iCaretX = DllStructGetData($tSIZE, 1) + 8
				Local $iCaretY = Int(($iHeight - DllStructGetData($tSIZE, 2)) / 2)
				_WinAPI_SetCaretPos($iCaretX, $iCaretY)
			EndIf

			; Outer border design framing line
			Local $hGraphics = _GDIPlus_GraphicsCreateFromHDC($hMemDC)
			Local $hPenBorder = _GDIPlus_PenCreate(0xFF7A7A7A, 1)
			_GDIPlus_GraphicsDrawRect($hGraphics, 0, 0, $iWidth - 1, $iHeight - 1, $hPenBorder)
			_GDIPlus_PenDispose($hPenBorder)
			_GDIPlus_GraphicsDispose($hGraphics)

			; Copy memory DC to screen DC (BitBlt)
			_WinAPI_BitBlt($hDC, 0, 0, $iWidth, $iHeight, $hMemDC, 0, 0, $SRCCOPY)

			; Cleanup
			_WinAPI_SelectObject($hMemDC, $hOldBmp)
			_WinAPI_SelectObject($hDC, $hOldFont)
			_WinAPI_DeleteObject($hBitmap)
			_WinAPI_DeleteDC($hMemDC)

			_WinAPI_EndPaint($hWnd, $tPaint)
			Return 0

		Case Else
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

EndFunc   ;==>__GUIDarkTheme_HotkeyProc

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func _Hotkey_GetText($hWnd)
	Local $iHotkey = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", $HKM_GETHOTKEY, "wparam", 0, "lparam", 0)[0]
	If $iHotkey = 0 Then Return "None"

	Local $iKey = BitAND($iHotkey, 0xFF)
	Local $iMod = BitShift($iHotkey, 8)

	Local $sText = ""
	If BitAND($iMod, 0x02) Then $sText &= "Ctrl + "
	If BitAND($iMod, 0x04) Then $sText &= "Alt + "
	If BitAND($iMod, 0x01) Then $sText &= "Shift + "

	Local $iScanCode = DllCall("user32.dll", "uint", "MapVirtualKeyW", "uint", $iKey, "uint", 0)[0]
	Local $iLongParam = BitOR($iScanCode * 0x10000, 0x02000000)
	If BitAND($iMod, 0x08) Then $iLongParam = BitOR($iLongParam, 0x01000000)

	Local $tBuffer = DllStructCreate("wchar[64]")
	DllCall("user32.dll", "int", "GetKeyNameTextW", "long", $iLongParam, "ptr", DllStructGetPtr($tBuffer), "int", 64)
	Local $sKeyName = DllStructGetData($tBuffer, 1)

	If StringLen($sKeyName) = 1 Then $sKeyName = StringUpper($sKeyName)

	Return $sText & $sKeyName
EndFunc   ;==>_Hotkey_GetText

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_SubclassProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Local $hDC, $sClass, $iRet, $tRect, $hBrush, $hFont, $hOldPen, $hSelectObject, $tTextSize, $iTextHeight, $iCenterV, $iH, $iW
	Local $hCtrl = HWnd($lParam)
	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_CTLCOLORLISTBOX
			$hDC = $wParam
			_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
			$hBrush = $__DM_g_hBrushCtrl
			_WinAPI_SetBkColor($hDC, _WinAPI_SwitchColor($__DM_g_iCtrlBkColor))
			_WinAPI_SetBkMode($hDC, $TRANSPARENT)
			Return $hBrush

		Case $WM_CTLCOLOREDIT
			$hDC = $wParam
			_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
			_WinAPI_SetBkMode($hDC, $TRANSPARENT)
			$hBrush = $__DM_g_hBrushCtrl
			Return $hBrush

		Case $WM_CTLCOLORSTATIC
			$hDC = $wParam
			If _WinAPI_GetClassName($hCtrl) = "Edit" Then
				_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
				_WinAPI_SetBkMode($hDC, $TRANSPARENT)
				Return $__DM_g_hBrushCtrl
			EndIf

			Return $GUI_RUNDEFMSG

		Case $WM_NOTIFY
			If Not $__DM_g_bUseDarkMode Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
			Local $hFrom = $tNMHDR.hWndFrom
			Local $iCode = $tNMHDR.Code
			If $iCode = $NM_CUSTOMDRAW Then
				Local $tNMCD = DllStructCreate($__DM_tagNMCUSTOMDRAW, $lParam)
				Local $dwStage = $tNMCD.dwDrawStage
				$hDC = $tNMCD.hdc
				Switch _WinAPI_GetClassName($hFrom)
					Case "sysheader32"
						Switch $dwStage
							Case $CDDS_PREPAINT
								Return $CDRF_NOTIFYITEMDRAW
							Case $CDDS_ITEMPREPAINT
								_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
								_WinAPI_SetBkColor($hDC, _WinAPI_SwitchColor(0x000000))
								Return BitOR($CDRF_NEWFONT, $CDRF_NOTIFYPOSTPAINT)
						EndSwitch
				EndSwitch
			EndIf

		Case $WM_NCHITTEST
			Local $aRet = DllCall("user32.dll", "lresult", "DefWindowProcW", _
					"hwnd", $hWnd, _
					"uint", $iMsg, _
					"wparam", $wParam, _
					"lparam", $lParam)

			If @error Then Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

			Local $iHitTest = $aRet[0]
			If $iHitTest = $HTNOWHERE Then Return $HTCLIENT

			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_PAINT
			$sClass = _WinAPI_GetClassName($hWnd)
			If $sClass = "syslistview32" Or $sClass = "systreeview32" Or $sClass = "edit" Then
				$iRet = __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
				Local $iWinStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
				If BitAND($iWinStyle, $WS_HSCROLL) And BitAND($iWinStyle, $WS_VSCROLL) Then
					$hDC = _WinAPI_GetWindowDC($hWnd)
					__GUIDarkTheme_PaintSizeBox($hWnd, $hDC)
					_WinAPI_ReleaseDC($hWnd, $hDC)
				EndIf
				Return $iRet
			Else
				Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
			EndIf

		Case $WM_NCPAINT
			; WS_EX_CLIENTEDGE border is drawn in WM_NCPAINT (non-client area), not WM_CTLCOLOR.
			; We let Windows draw the default frame first, then overdraw it with our dark border.
			Local $hPen
			Local $bHasFocus = False
			$sClass = _WinAPI_GetClassName($hWnd)
			If _IsBorderedControl($sClass) Then
				$iRet = __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
				$hDC = _WinAPI_GetWindowDC($hWnd)
				$tRect = _WinAPI_GetWindowRect($hWnd)
				$iW = $tRect.Right - $tRect.Left
				$iH = $tRect.Bottom - $tRect.Top
				If _WinAPI_GetClassName($hWnd) = "Edit" Then
					Local $iClientH = _WinAPI_GetClientHeight($hWnd)
					;$hFont = _SendMessage($hWnd, $WM_GETFONT)
					;$hSelectObject = _WinAPI_SelectObject($hDC, $hFont)
					;$tTextSize = _WinAPI_GetTextExtentPoint32($hDC, "Test")
					;$iTextHeight = $tTextSize.Y
					;$iCenterV = ($iH - $iTextHeight) / 2
					;_WinAPI_SelectObject($hDC, $hSelectObject)

					If Not BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $ES_MULTILINE) Then
						Local $RectToFill = _WinAPI_CreateRectEx(0, 0, $iW, $iH - $iClientH)
						_WinAPI_FillRect($hDC, $RectToFill, $__DM_g_hBrushCtrl)
						$hOldPen = _WinAPI_SelectObject($hDC, $__DM_g_hPen2Ctrl)
						_WinAPI_DrawLine($hDC, 2, 2, 2, $iH - 2)
						_WinAPI_SelectObject($hDC, $hOldPen)
					EndIf
				EndIf
				$hPen = $__DM_g_bShowCtrlBorder ? $__DM_g_hPenBorder : $__DM_g_hPenGui
				$hOldPen = _WinAPI_SelectObject($hDC, $hPen)
				Local $hNull = _WinAPI_GetStockObject(5)
				Local $hOldBr = _WinAPI_SelectObject($hDC, $hNull)
				DllCall('gdi32.dll', "bool", "Rectangle", "handle", $hDC, "int", 0, "int", 0, "int", $iW, "int", $iH)
				_WinAPI_SelectObject($hDC, $hOldPen)
				_WinAPI_SelectObject($hDC, $hOldBr)
				If _WinAPI_GetClassName($hWnd) = "Edit" And $__DM_g_bShowEditActive Then
					$bHasFocus = _WinAPI_GetFocus() = $hWnd
					$hOldPen = _WinAPI_SelectObject($hDC, $bHasFocus ? $__DM_g_hPenAccent : $__DM_g_hPenGui)
					_WinAPI_DrawLine($hDC, 0, $iH - 1, $tRect.Right, $iH - 1)
					_WinAPI_SelectObject($hDC, $hOldPen)

					$hOldPen = _WinAPI_SelectObject($hDC, $bHasFocus ? $__DM_g_hPenAccent : $__DM_g_hPenBorder)
					_WinAPI_DrawLine($hDC, 0, $iH - 2, $tRect.Right, $iH - 2)
					_WinAPI_SelectObject($hDC, $hOldPen)
				EndIf

				__GUIDarkTheme_PaintSizeBox($hWnd, $hDC)
				_WinAPI_ReleaseDC($hWnd, $hDC)
				Return $iRet
			EndIf

		Case $WM_NCMOUSEMOVE
			; Scrollbar hot-tracking animates via WM_TIMER and paints the sizebox directly,
			; bypassing both WM_PAINT and WM_NCPAINT.  Re-stamp the corner on every NC mouse
			; move so the dark fill is never lost while the cursor is over the control.
			$sClass = _WinAPI_GetClassName($hWnd)
			If $sClass = "edit" Or $sClass = "listbox" Or $sClass = "syslistview32" Or $sClass = "systreeview32" Then
				$iRet = __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
				$hDC = _WinAPI_GetWindowDC($hWnd)
				__GUIDarkTheme_PaintSizeBox($hWnd, $hDC)
				_WinAPI_ReleaseDC($hWnd, $hDC)
				Return $iRet
			EndIf

		Case $WM_NCCALCSIZE ;generate non-client area to ensure borders are not overpainted because no WS_EX_CLIENTEDGE
			$sClass = _WinAPI_GetClassName($hWnd)
			If _IsBorderedControl($sClass) And $wParam Then
				$iRet = __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
				$tRect = DllStructCreate($tagRECT, $lParam)
				If $sClass = "ListBox" Then Return $iRet
				$tRect.left += 1
				$tRect.top += 1
				$tRect.right -= 1
				If $sClass = "Edit" Then
					Local $tRectW = _WinAPI_GetWindowRect($hWnd)
					$iH = $tRectW.Bottom - $tRectW.Top
					$hDC = _WinAPI_GetDC($hWnd)
					$hFont = _SendMessage($hWnd, $WM_GETFONT)
					$hSelectObject = _WinAPI_SelectObject($hDC, $hFont)
					$tTextSize = _WinAPI_GetTextExtentPoint32($hDC, "Test")
					$iTextHeight = $tTextSize.Y
					$iCenterV = ($iH - $iTextHeight) / 2
					_WinAPI_SelectObject($hDC, $hSelectObject)
					_WinAPI_ReleaseDC($hWnd, $hDC)
					$tRect.top += BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $ES_MULTILINE) ? 0 : $iCenterV - 3
					$tRect.left += BitAND(_WinAPI_GetWindowLong($hWnd, $GWL_STYLE), $ES_MULTILINE) ? 0 : 2
					$tRect.bottom -= $__DM_g_bShowEditActive ? 2 : 1
				Else
					$tRect.bottom -= 1
				EndIf

				Return $iRet
			EndIf
	EndSwitch
	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_SubclassProc

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _IsBorderedControl($sClass)
	Return ($sClass = "edit" Or $sClass = "listbox" Or $sClass = "syslistview32" Or $sClass = "systreeview32" Or $sClass = "combolbox")
EndFunc   ;==>_IsBorderedControl

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_PaintSizeBox($hWnd, $hDC)
	Local $iWinStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)

	; Only proceed if both horizontal and vertical scrollbars are active
	If Not (BitAND($iWinStyle, $WS_HSCROLL) And BitAND($iWinStyle, $WS_VSCROLL)) Then Return False

	; 1. Retrieve exact Window and Client dimensions
	Local $tRW = _WinAPI_GetWindowRect($hWnd)
	Local $tRC = _WinAPI_GetClientRect($hWnd)

	; 2. Map Client coordinates to Window-DC space
	Local $tPoint = DllStructCreate($tagPOINT)
	$tPoint.X = 0
	$tPoint.Y = 0
	_WinAPI_ClientToScreen($hWnd, $tPoint)

	; Calculate border offsets
	Local $iOffL = $tPoint.X - $tRW.Left
	Local $iOffT = $tPoint.Y - $tRW.Top

	; Calculate total window dimensions
	Local $iWinW = $tRW.Right - $tRW.Left
	Local $iWinH = $tRW.Bottom - $tRW.Top

	; 3. Define the SizeBox Rect
	Local $tCorner = DllStructCreate($tagRECT)

	; LEFT/TOP: Start exactly where the client area ends (scrollbar junction)
	$tCorner.Left = $iOffL + $tRC.Right
	$tCorner.Top = $iOffT + $tRC.Bottom

	; RIGHT/BOTTOM: Align with the inner edge of the window border.
	$tCorner.Right = $iWinW - $iOffL
	$tCorner.Bottom = $iWinH - $iOffT

	; Adjust for Edit the size of the box
	If _WinAPI_GetClassName($hWnd) = "Edit" Then
		$tCorner.Bottom -= $__DM_g_bShowEditActive ? 1 : 0
	EndIf

	; 4. Paint the box using the dark theme color
	_WinAPI_FillRect($hDC, $tCorner, $__DM_g_hBrushSizebox)

	Return True
EndFunc   ;==>__GUIDarkTheme_PaintSizeBox

; #FUNCTION# ====================================================================================================================
; Author.........: ioa747
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_GUI_IsResizable($hWnd)
	Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
	; Check if the WS_SIZEBOX (0x00040000) bit is set
	; $WS_SIZEBOX and $WS_THICKFRAME are the same constant
	If BitAND($iStyle, $WS_SIZEBOX) Then
		Return True
	Else
		Return False
	EndIf
EndFunc   ;==>__GUIDarkTheme_GUI_IsResizable

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_SwitchTheme($hWnd)
	$__DM_g_bUseDarkMode = _WinAPI_ShouldAppsUseDarkMode()
	;__DM_ThemeCleanupHelper($hWnd, 1)
	Switch $__DM_g_bDarkModeLast
		Case True
			_GUIDarkTheme_ApplyLight($hWnd)
		Case False
			_GUIDarkTheme_ApplyDark($hWnd)
	EndSwitch
	;__DM_ThemeCleanupHelper($hWnd, 2)
EndFunc   ;==>_GUIDarkTheme_SwitchTheme

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __DM_ThemeCleanupHelper($hWnd, $iStage)
	Switch $iStage
		Case 1
			;_WinAPI_LockWindowUpdate($hWnd)
			_SendMessage($hWnd, $WM_SETREDRAW, False)
			; Send __DM_WM_CHANGETHEME to GUI and all child control windows to prepare subclasses for theme switch
			_SendMessage($hWnd, $__DM_WM_CHANGETHEME, 0, 0)
			Local $aCtrls = _WinAPI_EnumChildWindows($hWnd, False)
			If @error = 0 Then
				For $i = 1 To $aCtrls[0][0]
					_SendMessage($aCtrls[$i][0], $__DM_WM_CHANGETHEME, 0, 0)
				Next
			EndIf

			; Clear subclasses, brushes and pens
			__GUIDarkTheme_SubclassCleanup()
			__GUIDarkTheme_BrushCleanup()
			__GUIDarkTheme_PenCleanup()
		Case 2
			; redraw window and menubar if needed
			_WinAPI_RedrawWindow($hWnd, 0, 0, BitOR($RDW_INVALIDATE, $RDW_UPDATENOW, $RDW_ALLCHILDREN))
			Local $hMenu = _GUICtrlMenu_GetMenu($hWnd)
			If $hMenu Then _GUICtrlMenu_DrawMenuBar($hWnd)
			;_WinAPI_LockWindowUpdate(0)
			_SendMessage($hWnd, $WM_SETREDRAW, True)
			_WinAPI_RedrawWindow($hWnd)
			_WinAPI_SetWindowPos($hWnd, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
			If _GUICtrlMenu_GetMenu($hWnd) Then __GUIDarkMenu_PaintWhiteLine($hWnd)
	EndSwitch
EndFunc   ;==>__DM_ThemeCleanupHelper

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func _GUIDarkTheme_Version()
	Return $__DM_g_Version
EndFunc   ;==>_GUIDarkTheme_Version

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_SetCornerPref($hWnd, $iCornerPref)
	; Requires Windows 11 Build 22000 or higher
	; Options $DWMWCP_DEFAULT, $DWMWCP_DONOTROUND, $DWMWCP_ROUND, $DWMWCP_ROUNDSMALL
	Local Const $DWMWA_WINDOW_CORNER_PREFERENCE = 33
	If @OSBuild >= 22000 Then
		_WinAPI_DwmSetWindowAttribute($hWnd, $DWMWA_WINDOW_CORNER_PREFERENCE, $iCornerPref)
	EndIf
EndFunc   ;==>_GUIDarkTheme_SetCornerPref

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_CtrlBorderSet
; Description ...: Sets whether or not border is shown around controls or if Edit controls have active color on bottom.
; Syntax ........: _GUIDarkTheme_CtrlBorderSet($bShowCtrlBorder = Default, $bShowEditActive = Default)
; Parameters ....: $bShowCtrlBorder		- Boolean. True to show borders around controls, False to now show. Default is True.
;				   $bShowEditActive		- Boolean. True to show active color on Edit control, False not. Default is True.
; Return values .: None
; Author ........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_CtrlBorderSet($bShowCtrlBorder = Default, $bShowEditActive = Default)
	If $bShowCtrlBorder = Default Then $__DM_g_bShowCtrlBorder = True
	If $bShowCtrlBorder <> Default Then $__DM_g_bShowCtrlBorder = $bShowCtrlBorder
	If $bShowEditActive = Default Then $__DM_g_bShowEditActive = True
	If $bShowEditActive <> Default Then $__DM_g_bShowEditActive = $bShowEditActive
EndFunc   ;==>_GUIDarkTheme_CtrlBorderSet

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_CreatePens()
	If Not $__DM_g_hPenBlack Then $__DM_g_hPenBlack = _WinAPI_CreatePen($PS_SOLID, 1, 0x000000)
	If Not $__DM_g_hPenLight Then $__DM_g_hPenLight = _WinAPI_CreatePen($PS_SOLID, 1, 0xA0A0A0)
	If Not $__DM_g_hPenBtnBor Then $__DM_g_hPenBtnBor = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iBtnBorderDef))
	If Not $__DM_g_hPenGui Then $__DM_g_hPenGui = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iGuiBkColor))
	If Not $__DM_g_hPenBorder Then $__DM_g_hPenBorder = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iBorderColor))
	If Not $__DM_g_hPenAccent Then $__DM_g_hPenAccent = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iAccentColor))
	If Not $__DM_g_hPen2Accent Then $__DM_g_hPen2Accent = _WinAPI_CreatePen($PS_SOLID, 2, _WinAPI_SwitchColor($__DM_g_iAccentColor))
	If Not $__DM_g_hPen2Border Then $__DM_g_hPen2Border = _WinAPI_CreatePen($PS_SOLID, 2, _WinAPI_SwitchColor($__DM_g_iBorderColor))
	If Not $__DM_g_hPen2Ctrl Then $__DM_g_hPen2Ctrl = _WinAPI_CreatePen($PS_SOLID, 2, _WinAPI_SwitchColor($__DM_g_iCtrlBkColor))
	If Not $__DM_g_hPenBtnDef Then $__DM_g_hPenBtnDef = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iBtnBorderDef))
	If Not $__DM_g_hPenBtnHov Then $__DM_g_hPenBtnHov = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iBtnBorderHov))
	If Not $__DM_g_hPenBtnSel Then $__DM_g_hPenBtnSel = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iBtnBorderSel))
	If Not $__DM_g_hPenBtnFoc Then $__DM_g_hPenBtnFoc = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iBtnBorderFoc))
	If Not $__DM_g_hPenBtnDis Then $__DM_g_hPenBtnDis = _WinAPI_CreatePen($PS_SOLID, 1, _WinAPI_SwitchColor($__DM_g_iBtnBorderDis))
EndFunc   ;==>__GUIDarkTheme_CreatePens

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_PenCleanup()
	If $__DM_g_hPenLight Then
		_WinAPI_DeleteObject($__DM_g_hPenLight)
		$__DM_g_hPenLight = 0
	EndIf
	If $__DM_g_hPenBtnDef Then
		_WinAPI_DeleteObject($__DM_g_hPenBtnDef)
		$__DM_g_hPenBtnDef = 0
	EndIf
	If $__DM_g_hPenBtnHov Then
		_WinAPI_DeleteObject($__DM_g_hPenBtnHov)
		$__DM_g_hPenBtnHov = 0
	EndIf
	If $__DM_g_hPenBtnSel Then
		_WinAPI_DeleteObject($__DM_g_hPenBtnSel)
		$__DM_g_hPenBtnSel = 0
	EndIf
	If $__DM_g_hPenBtnFoc Then
		_WinAPI_DeleteObject($__DM_g_hPenBtnFoc)
		$__DM_g_hPenBtnFoc = 0
	EndIf
	If $__DM_g_hPenBtnDis Then
		_WinAPI_DeleteObject($__DM_g_hPenBtnDis)
		$__DM_g_hPenBtnDis = 0
	EndIf
	If $__DM_g_hPen2Ctrl Then
		_WinAPI_DeleteObject($__DM_g_hPen2Ctrl)
		$__DM_g_hPen2Ctrl = 0
	EndIf
	If $__DM_g_hPenBlack Then
		_WinAPI_DeleteObject($__DM_g_hPenBlack)
		$__DM_g_hPenBlack = 0
	EndIf
	If $__DM_g_hPen2Accent Then
		_WinAPI_DeleteObject($__DM_g_hPen2Accent)
		$__DM_g_hPen2Accent = 0
	EndIf
	If $__DM_g_hPen2Border Then
		_WinAPI_DeleteObject($__DM_g_hPen2Border)
		$__DM_g_hPen2Border = 0
	EndIf
	If $__DM_g_hPenAccent Then
		_WinAPI_DeleteObject($__DM_g_hPenAccent)
		$__DM_g_hPenAccent = 0
	EndIf
	If $__DM_g_hPenBorder Then
		_WinAPI_DeleteObject($__DM_g_hPenBorder)
		$__DM_g_hPenBorder = 0
	EndIf
	If $__DM_g_hPenGui Then
		_WinAPI_DeleteObject($__DM_g_hPenGui)
		$__DM_g_hPenGui = 0
	EndIf
	If $__DM_g_hPenBtnBor Then
		_WinAPI_DeleteObject($__DM_g_hPenBtnBor)
		$__DM_g_hPenBtnBor = 0
	EndIf
EndFunc   ;==>__GUIDarkTheme_PenCleanup

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_AutoTheme($bFollowSystemTheme = True)
	If $bFollowSystemTheme Then
		GUIRegisterMsg($WM_SETTINGCHANGE, "__GUIDarkTheme_WM_SETTINGCHANGE")
	Else
		GUIRegisterMsg($WM_SETTINGCHANGE, "")
	EndIf
EndFunc   ;==>_GUIDarkTheme_AutoTheme

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_WM_SETTINGCHANGE($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam
	If Not $lParam Then Return $GUI_RUNDEFMSG

	Local $tString = DllStructCreate("wchar[256]", $lParam)
	Local $sParam = DllStructGetData($tString, 1)

	If Not ($sParam == "ImmersiveColorSet") Then Return $GUI_RUNDEFMSG

	; Save the window handle for the deferred callback
	$g_hThemeWnd = $hWnd

	; Trailing-edge debounce: Reset the timer on every incoming message.
	; This cancels any pending execution and waits 100ms of "silence" before firing.
	AdlibUnRegister("__DM_DeferApplyColor")
	AdlibRegister("__DM_DeferApplyColor", 50)

	Return $GUI_RUNDEFMSG
EndFunc   ;==>__GUIDarkTheme_WM_SETTINGCHANGE

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __DM_DeferApplyColor()
	; Unregister immediately so this only runs once per burst
	AdlibUnRegister("__DM_DeferApplyColor")

	Local Static $bIsDarkLast = Null

	Local $iIsDark = RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	Local $bIsDark = ($iIsDark = 0)

	If $bIsDarkLast <> $bIsDark Then
		$bIsDarkLast = $bIsDark
		Switch $bIsDark
			Case True
				If Not $__DM_g_bDarkModeLast Then _GUIDarkTheme_ApplyDark($g_hThemeWnd)
			Case False
				If $__DM_g_bDarkModeLast Then _GUIDarkTheme_ApplyLight($g_hThemeWnd)
		EndSwitch

		; Use custom window message to send secondary signal
		_WinAPI_PostMessage($g_hThemeWnd, $__DM_WM_COLORMODECHANGED, 0, 0)
	EndIf
EndFunc   ;==>__DM_DeferApplyColor

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_CreateBrushes()
	If Not $__DM_g_hBrushGui Then $__DM_g_hBrushGui = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iGuiBkColor))
	If Not $__DM_g_hBrushCtrl Then $__DM_g_hBrushCtrl = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iCtrlBkColor))
	If Not $__DM_g_hBrushBtnDef Then $__DM_g_hBrushBtnDef = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iBtnBkColorDef))
	If Not $__DM_g_hBrushBtnHov Then $__DM_g_hBrushBtnHov = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iBtnBkColorHov))
	If Not $__DM_g_hBrushBtnSel Then $__DM_g_hBrushBtnSel = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iBtnBkColorSel))
	If Not $__DM_g_hBrushBtnFoc Then $__DM_g_hBrushBtnFoc = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iBtnBkColorFoc))
	If Not $__DM_g_hBrushBtnDis Then $__DM_g_hBrushBtnDis = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iBtnBkColorDis))
	If Not $__DM_g_hBrushMenuBk Then $__DM_g_hBrushMenuBk = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iMenuBkColor))
	If Not $__DM_g_hBrushMenuSel Then $__DM_g_hBrushMenuSel = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iMenuSelColor))
	If Not $__DM_g_hBrushMenuHot Then $__DM_g_hBrushMenuHot = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iMenuHotColor))
	If Not $__DM_g_hBrushAccent Then $__DM_g_hBrushAccent = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor(0x0078D4))
	If Not $__DM_g_hBrushAccentHot Then $__DM_g_hBrushAccentHot = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor(0x2FA7FF))
	If Not $__DM_g_hBrushTab Then $__DM_g_hBrushTab = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iTabColor))
	If Not $__DM_g_hBrushSizebox Then $__DM_g_hBrushSizebox = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iSizeboxPaint))
	If Not $__DM_g_hBrushGray Then $__DM_g_hBrushGray = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iExtraGray))
	If Not $__DM_g_hBrushMsgBoxTop Then $__DM_g_hBrushMsgBoxTop = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iMsgBoxTopColor))
	If Not $__DM_g_hBrushMsgBoxBottom Then $__DM_g_hBrushMsgBoxBottom = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iMsgBoxBottomColor))
	If Not $__DM_g_hBrushBorder Then $__DM_g_hBrushBorder = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iBorderColor))
	If Not $__DM_g_hBrushStatus Then $__DM_g_hBrushStatus = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor($__DM_g_iStatusBkColor))
	If Not $__DM_g_hBrushGlyph Then $__DM_g_hBrushGlyph = _WinAPI_CreateSolidBrush(_WinAPI_SwitchColor(0xA0A0A0))
	;$__DM_g_hBrushGlyph
EndFunc   ;==>__GUIDarkTheme_CreateBrushes

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_BrushCleanup()
	If $__DM_g_hBrushGlyph Then
		_WinAPI_DeleteObject($__DM_g_hBrushGlyph)
		$__DM_g_hBrushGlyph = 0
	EndIf
	If $__DM_g_hBrushStatus Then
		_WinAPI_DeleteObject($__DM_g_hBrushStatus)
		$__DM_g_hBrushStatus = 0
	EndIf
	If $__DM_g_hBrushBorder Then
		_WinAPI_DeleteObject($__DM_g_hBrushBorder)
		$__DM_g_hBrushBorder = 0
	EndIf
	If $__DM_g_hBrushHdr Then
		_WinAPI_DeleteObject($__DM_g_hBrushHdr)
		$__DM_g_hBrushHdr = 0
	EndIf
	If $__DM_g_hBrushHdrHot Then
		_WinAPI_DeleteObject($__DM_g_hBrushHdrHot)
		$__DM_g_hBrushHdrHot = 0
	EndIf
	If $__DM_g_hBrushHdrSel Then
		_WinAPI_DeleteObject($__DM_g_hBrushHdrSel)
		$__DM_g_hBrushHdrSel = 0
	EndIf
	If $__DM_g_hBrushMsgBoxBottom Then
		_WinAPI_DeleteObject($__DM_g_hBrushMsgBoxBottom)
		$__DM_g_hBrushMsgBoxBottom = 0
	EndIf
	If $__DM_g_hBrushMsgBoxTop Then
		_WinAPI_DeleteObject($__DM_g_hBrushMsgBoxTop)
		$__DM_g_hBrushMsgBoxTop = 0
	EndIf
	If $__DM_g_hBrushGray Then
		_WinAPI_DeleteObject($__DM_g_hBrushGray)
		$__DM_g_hBrushGray = 0
	EndIf
	If $__DM_g_hBrushTab Then
		_WinAPI_DeleteObject($__DM_g_hBrushTab)
		$__DM_g_hBrushTab = 0
	EndIf
	If $__DM_g_hBrushAccentHot Then
		_WinAPI_DeleteObject($__DM_g_hBrushAccentHot)
		$__DM_g_hBrushAccentHot = 0
	EndIf
	If $__DM_g_hBrushAccent Then
		_WinAPI_DeleteObject($__DM_g_hBrushAccent)
		$__DM_g_hBrushAccent = 0
	EndIf
	If $__DM_g_hBrushMenuBk Then
		_WinAPI_DeleteObject($__DM_g_hBrushMenuBk)
		$__DM_g_hBrushMenuBk = 0
	EndIf
	If $__DM_g_hBrushMenuSel Then
		_WinAPI_DeleteObject($__DM_g_hBrushMenuSel)
		$__DM_g_hBrushMenuSel = 0
	EndIf
	If $__DM_g_hBrushMenuHot Then
		_WinAPI_DeleteObject($__DM_g_hBrushMenuHot)
		$__DM_g_hBrushMenuHot = 0
	EndIf
	If $__DM_g_hBrushSizebox Then
		_WinAPI_DeleteObject($__DM_g_hBrushSizebox)
		$__DM_g_hBrushSizebox = 0
	EndIf
	If $__DM_g_hBrushGui Then
		_WinAPI_DeleteObject($__DM_g_hBrushGui)
		$__DM_g_hBrushGui = 0
	EndIf
	If $__DM_g_hBrushBtnDis Then
		_WinAPI_DeleteObject($__DM_g_hBrushBtnDis)
		$__DM_g_hBrushBtnDis = 0
	EndIf
	If $__DM_g_hBrushBtnFoc Then
		_WinAPI_DeleteObject($__DM_g_hBrushBtnFoc)
		$__DM_g_hBrushBtnFoc = 0
	EndIf
	If $__DM_g_hBrushBtnSel Then
		_WinAPI_DeleteObject($__DM_g_hBrushBtnSel)
		$__DM_g_hBrushBtnSel = 0
	EndIf
	If $__DM_g_hBrushBtnHov Then
		_WinAPI_DeleteObject($__DM_g_hBrushBtnHov)
		$__DM_g_hBrushBtnHov = 0
	EndIf
	If $__DM_g_hBrushBtnDef Then
		_WinAPI_DeleteObject($__DM_g_hBrushBtnDef)
		$__DM_g_hBrushBtnDef = 0
	EndIf
	If $__DM_g_hBrushCtrl Then
		_WinAPI_DeleteObject($__DM_g_hBrushCtrl)
		$__DM_g_hBrushCtrl = 0
	EndIf
EndFunc   ;==>__GUIDarkTheme_BrushCleanup

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_WM_CTLCOLOR($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd
	Local $hDC = $wParam
	Local $hCtrl = $lParam

	Switch $iMsg
		Case $WM_CTLCOLORLISTBOX
			$hDC = $wParam
			_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
			_WinAPI_SetBkMode($hDC, $TRANSPARENT)
			Return $__DM_g_hBrushCtrl

		Case $WM_CTLCOLOREDIT
			; Skip multi-line Edit (ES_MULTILINE) since it causes some visual glitches
			If BitAND(_WinAPI_GetWindowLong($hCtrl, $GWL_STYLE), $ES_MULTILINE) Then Return $GUI_RUNDEFMSG
			_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
			_WinAPI_SetBkMode($hDC, $TRANSPARENT)
			Return $__DM_g_hBrushCtrl

		Case $WM_CTLCOLORSTATIC
			If _WinAPI_GetClassName($hCtrl) = "Edit" Then
				_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
				_WinAPI_SetBkMode($hDC, $TRANSPARENT)
				Return $__DM_g_hBrushCtrl
			EndIf

			If _WinAPI_GetClassName($hCtrl) = "SysLink" Then
				Local $sText = _WinAPI_GetWindowText($hCtrl)
				If StringLeft($sText, 2) = "<a" And StringRight($sText, 2) = "a>" Then
					_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_bUseDarkMode ? 0x60cdff : 0x005fb8))
				Else
					_WinAPI_SetTextColor($hDC, _WinAPI_SwitchColor($__DM_g_iTextColor))
				EndIf
				_WinAPI_SetBkColor($hDC, _WinAPI_SwitchColor($__DM_g_iCtrlBkColor))
				_WinAPI_SetBkMode($hDC, $TRANSPARENT)
				Return $__DM_g_hBrushGui
			EndIf

			Return $GUI_RUNDEFMSG

	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>__GUIDarkTheme_WM_CTLCOLOR

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_GetCtrlColors($hWnd, ByRef $iTextColor, ByRef $iBkColor, ByRef $iBkMode)
	Local $hDC = _WinAPI_GetDC($hWnd)
	Local $hBrushTemp = _SendMessage(_WinAPI_GetParent($hWnd), $WM_CTLCOLORSTATIC, $hDC, $hWnd)
	Local $hOriginal = _WinAPI_SelectObject($hDC, $hBrushTemp)
	$iTextColor = "0x" & Hex(_WinAPI_GetTextColor($hDC), 6)
	$iBkColor = "0x" & Hex(_WinAPI_GetBkColor($hDC), 6)
	$iBkMode = _WinAPI_GetBkMode($hDC)
	_WinAPI_SelectObject($hDC, $hOriginal)
	_WinAPI_ReleaseDC($hWnd, $hDC)
EndFunc   ;==>__GUIDarkTheme_GetCtrlColors

; #FUNCTION# ====================================================================================================================
; Author.........: ioa747
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __GUIDarkTheme_IsCtrlInRebar($hRebar, $hCtrl)
	; Get the bounding rectangles of the Rebar and the Control
	Local $tRectRebar = _WinAPI_GetWindowRect($hRebar)
	Local $tRectCtrl = _WinAPI_GetWindowRect($hCtrl)

	; Get the intersection of the two rectangles
	Local $tIntersect = _WinAPI_IntersectRect($tRectRebar, $tRectCtrl)

	; Check if the intersection rectangle is NOT empty
	If DllStructGetData($tIntersect, "Left") <> 0 Or DllStructGetData($tIntersect, "Right") <> 0 Then
		; If it intersects, return the current selected Tab Index (0, 1, etc.) in @extended
		Return SetError(0, $hRebar, True)
	EndIf

	Return SetError(0, 0, False) ; Not within the Rebar area
EndFunc   ;==>__GUIDarkTheme_IsCtrlInRebar

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __DM_DarkThemeAvailability()
	Local $iRet = __DM_QueryDarkMode()
	Switch $iRet
		Case 2
			; DarkMode_DarkTheme is available
			Return True
		Case 1
			; DarkMode_Explorer is available, used only when DarkMode_DarkTheme is not available
			Return False
		Case Else
			; Fallback, OS may not support dark mode or detection failed
			Return False
	EndSwitch
EndFunc   ;==>__DM_DarkThemeAvailability

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __DM_QueryDarkMode()
	Local $iColor
	If Not _WinAPI_IsThemeActive() Then Return SetError(0, 1, False)
	Local $hWnd = GUICreate("GUIDarkTheme")
	Local $iCOLOR_WINDOW = _WinAPI_SwitchColor(_WinAPI_GetSysColor($COLOR_WINDOW))  ; because of alt. themes
	$iColor = __DM_QueryThemeColors("DarkMode_DarkTheme::Edit", $hWnd)
	If Not @error And Hex($iColor, 6) <> Hex($iCOLOR_WINDOW, 6) Then
		GUIDelete($hWnd)
		Return 2 ; DarkMode_DarkTheme is available
	EndIf
	$iColor = __DM_QueryThemeColors("DarkMode_Explorer::Edit", $hWnd)
	If Not @error And Hex($iColor, 6) <> Hex($iCOLOR_WINDOW, 6) Then
		GUIDelete($hWnd)
		Return 1 ; DarkMode_Explorer is available, used only when DarkMode_DarkTheme is not available
	EndIf
	GUIDelete($hWnd)
	Return 0
EndFunc   ;==>__DM_QueryDarkMode

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; Modified.......: WildByDesign
; ===============================================================================================================================
Func __DM_QueryThemeColors($sClass, $hWnd = Default)
	Local Const $TMT_FILLCOLOR = 3802
	Local Const $EP_BACKGROUND = 3
	Local Const $EBS_NORMAL = 1
	Local $hWndWas = $hWnd
	If IsKeyword($hWnd) Then $hWnd = GUICreate("Simple_GetThemeColor")
	Local $hTheme = _WinAPI_OpenThemeData($hWnd, $sClass)
	If @error Then
		If IsKeyword($hWndWas) Then GUIDelete($hWnd)
		Return SetError(1, 0, False)
	EndIf
	Local $iColor = _WinAPI_GetThemeColor($hTheme, $EP_BACKGROUND, $EBS_NORMAL, $TMT_FILLCOLOR)
	If @error Then
		If IsKeyword($hWndWas) Then GUIDelete($hWnd)
		Return SetError(2, 0, False)
	EndIf
	_WinAPI_CloseThemeData($hTheme)
	Return $iColor
EndFunc   ;==>__DM_QueryThemeColors

; #FUNCTION# ====================================================================================================================
; Name ..........: _GUIDarkTheme_AccentColorSet
; Description ...: Sets the accent color used by certain controls
; Syntax ........: _GUIDarkTheme_AccentColorSet($iColor = Default)
; Parameters ....: $hGui is GUI handle.
;                ; $iColor	- 0xRRGGBB, Default is 0x0078D4.
; Return values .: None
; Author ........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_AccentColorSet($hGui, $iColor = Default)
	If $iColor = Default Then $__DM_g_iAccentColor = 0x0078D4
	If Not $iColor Then $__DM_g_iAccentColor = 0x0078D4
	If $iColor <> Default Then $__DM_g_iAccentColor = $iColor
	__GUIDarkTheme_PenCleanup()
	$__DM_g_iAccentColor = $iColor
	__GUIDarkTheme_CreatePens()
	; redraw GUI
	_WinAPI_RedrawWindow($hGui, 0, 0, BitOR($RDW_INVALIDATE, $RDW_UPDATENOW, $RDW_ALLCHILDREN))
EndFunc   ;==>_GUIDarkTheme_AccentColorSet

; #FUNCTION# ====================================================================================================================
; Author.........: MattyD
; ===============================================================================================================================
Func _GUICtrlTreeView_SetExtendedStyle($hTreeView, $iExStyle)
	Local Const $TVM_SETEXTENDEDSTYLE = 0x112C
	Local $iResult = _SendMessage($hTreeView, $TVM_SETEXTENDEDSTYLE, 0x07FD, $iExStyle)
	Return SetError(@error, @extended, $iResult)
EndFunc   ;==>_GUICtrlTreeView_SetExtendedStyle

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func __DM_WinAPI_GetDPI($hWnd = 0)
	Local Const $LOGPIXELSX = 88
	$hWnd = Not $hWnd ? _WinAPI_GetDesktopWindow() : $hWnd
	Local Const $hDC = _WinAPI_GetDC($hWnd)
	If @error Then Return SetError(1, 0, 0)
	Local Const $iDPI = _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSX)
	If @error Or Not $iDPI Then
		_WinAPI_ReleaseDC($hWnd, $hDC)
		Return SetError(2, 0, 0)
	EndIf
	_WinAPI_ReleaseDC($hWnd, $hDC)
	Return $iDPI
EndFunc   ;==>__DM_WinAPI_GetDPI

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_Base64Decode($sB64String)
	Local $aCrypt = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryA", "str", $sB64String, "dword", 0, "dword", 1, "ptr", 0, "dword*", 0, "ptr", 0, "ptr", 0)
	If @error Or Not $aCrypt[0] Then Return SetError(1, 0, "")
	Local $bBuffer = DllStructCreate("byte[" & $aCrypt[5] & "]")
	$aCrypt = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryA", "str", $sB64String, "dword", 0, "dword", 1, "struct*", $bBuffer, "dword*", $aCrypt[5], "ptr", 0, "ptr", 0)
	If @error Or Not $aCrypt[0] Then Return SetError(2, 0, "")
	Return DllStructGetData($bBuffer, 1)
EndFunc   ;==>_WinAPI_Base64Decode

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func _WinAPI_FindChildByClass($hParent, $sClass, $sTitle = "", $hAfter = 0)
	Local $ret = DllCall('user32.dll', "hwnd", "FindWindowExW", "hwnd", $hParent, "hwnd", $hAfter, "wstr", $sClass, "wstr", $sTitle)
	If @error Or Not IsArray($ret) Then Return 0
	Return $ret[0]
EndFunc   ;==>_WinAPI_FindChildByClass

; #FUNCTION# ====================================================================================================================
; Author.........: UEZ
; ===============================================================================================================================
Func __DM_WinAPI_GetDPIForWindow($hWnd)
	Local $aResult = DllCall('user32.dll', "uint", "GetDpiForWindow", "hwnd", $hWnd) ;requires Win10 v1607+ / no server support
	If Not IsArray($aResult) Or @error Then Return SetError(1, @extended, 0)
	If Not $aResult[0] Then Return SetError(2, @extended, 0)
	Return $aResult[0]
EndFunc   ;==>__DM_WinAPI_GetDPIForWindow

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GUIDarkTheme_ToolbarSetTrans($hToolbar, $bTransparency = Default)
	If $bTransparency = Default Then $bTransparency = True
	If $bTransparency <> Default Then $bTransparency = $bTransparency

	_GUICtrlToolbar_SetStyleTransparent($hToolbar, $bTransparency)

	; fix top line above toolbar
	If _GUICtrlToolbar_GetStyleTransparent($hToolbar) Then
		_GUICtrlToolbar_SetColorScheme($hToolbar, $__DM_g_iGuiBkColor, $__DM_g_iGuiBkColor)
	Else
		_GUICtrlToolbar_SetColorScheme($hToolbar, $__DM_g_iCtrlBkColor, $__DM_g_iCtrlBkColor)
	EndIf

	; trigger refresh of toolbar
	_WinAPI_SetWindowPos($hToolbar, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
EndFunc   ;==>_GUIDarkTheme_ToolbarSetTrans

; #FUNCTION# ====================================================================================================================
; Author.........: Nine
; ===============================================================================================================================
Func __GUIDarkTheme_SetBandColor($hWnd, $iIndex, $nClrBack, $nClrFore)
	Local $tInfo = DllStructCreate($tagREBARBANDINFO)

	$tInfo.cbSize = DllStructGetSize($tInfo)
	$tInfo.fMask = $RBBIM_COLORS
	$tInfo.clrBack = $nClrBack
	$tInfo.clrFore = $nClrFore

	_SendMessage($hWnd, $RB_SETBANDINFOA, $iIndex, $tInfo, 0, "wparam", "struct*")
EndFunc   ;==>__GUIDarkTheme_SetBandColor

; #FUNCTION# ====================================================================================================================
; Author.........: jugador
; Notes..........: This fixed version of the _WinAPI_DefSubclassProc function prevents some subclassing crashes
; ===============================================================================================================================
Func __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
	Return DllCall('comctl32.dll', 'lresult', 'DefSubclassProc', 'hwnd', $hWnd, 'uint', $iMsg, 'wparam', $wParam, _
			'lparam', $lParam)[0]
EndFunc   ;==>__DM_WinAPI_DefSubclassProc

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; Modified.......: argumentum
; ===============================================================================================================================
Func __DM_GetThemeDetails($sSep = @TAB, $sLastCRLF = @CRLF)
	Local $iRevision = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "UBR")
	Local $iOSBuild = @OSBuild & "." & $iRevision
	Local $sRet = " OSBuild.rev:" & $sSep & $iOSBuild & @CRLF
	Local $sUxThemeDll = @SystemDir & "\uxtheme.dll"
	Local $iUxThemeVer = StringReplace(FileGetVersion($sUxThemeDll), "10.0.", "")
	$sRet &= "     UxTheme:" & $sSep & $iUxThemeVer & @CRLF
	Local $sAeroMsStyles = @WindowsDir & "\Resources\Themes\aero\aero.msstyles"
	Local $iAeroVer = StringReplace(FileGetVersion($sAeroMsStyles), "10.0.", "")
	Local $iStylesAvail = __DM_QueryDarkMode()
	If $iStylesAvail = 2 And Not $__DM_g_b24H2Plus Then $iStylesAvail = "2 (DEBUG)"
	$sRet &= "  Aero Theme:" & $sSep & $iAeroVer & @CRLF
	$sRet &= " Theme Style: " & $iStylesAvail & $sLastCRLF
	Return $sRet
EndFunc   ;==>__DM_GetThemeDetails


Func _GUICtrlSysLink_AllowColoring($hWnd)
	Local Static $iLink = 0, $hWndPrior = 0

	If $hWndPrior <> $hWnd Then
		$hWndPrior = $hWnd ; in case there is another control in the GUI
		$iLink = 0
	EndIf

	Local $iRet = _GUICtrlSysLink_SetValue($hWnd, $iLink)
	While $iRet = True
		$iLink += 1
		$iRet = _GUICtrlSysLink_SetValue($hWnd, $iLink)
	WEnd
EndFunc   ;==>_GUICtrlSysLink_AllowColoring

Func _GUICtrlSysLink_SetValue($hWnd, $iLink)
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_STATE))
	DllStructSetData($tLITEM, "Link", $iLink)
	DllStructSetData($tLITEM, "State", $LIS_DEFAULTCOLORS) ; $LIS_DEFAULTCOLORS or 0
	DllStructSetData($tLITEM, "StateMask", $LIS_DEFAULTCOLORS)
	Local $pItem = DllStructGetPtr($tLITEM)
	Local $iRet = _SendMessage($hWnd, $LM_SETITEM, 0, $pItem, 0, "wparam", "ptr")
	;Local $iRet = __GUICtrlSysLink_SetItem($hWnd, $tLITEM)
	Return $iRet
EndFunc   ;==>_GUICtrlSysLink_SetValue

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func _GUICtrlSysLink_HitTest($hWnd, $iX, $iY)
	Local $tHit = DllStructCreate($tagLHITTESTINFO)
	DllStructSetData($tHit, "X", $iX)
	DllStructSetData($tHit, "Y", $iY)
	Local $aRet = _SendMessage($hWnd, $LM_HITTEST, 0, DllStructGetPtr($tHit), 0, "wparam", "ptr")
	Return $aRet ? DllStructGetData($tHit, "Link") : -1
EndFunc   ;==>_GUICtrlSysLink_HitTest

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func __GUIDarkTheme_SysLinkProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Local $X, $Y, $iLinkIndex
	Local Static $iClickMsg = _WinAPI_GetSystemMetrics(23) ? $WM_RBUTTONUP : $WM_LBUTTONUP

	Switch $iMsg
		Case $WM_DESTROY, $__DM_WM_CHANGETHEME
			_WinAPI_RemoveWindowSubclass($hWnd, DllCallbackGetPtr($pData), $iID)
			Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)

		Case $WM_GETDLGCODE
			; We claim chars and arrows, letting SysLink handle internal link focus navigation.
			Return $WM_NCHITTEST

		Case $WM_SETFOCUS
			; Intercept the focus message and return 0 immediately.
			; This tricks the control into never starting its "Draw Dotted Box" routine.
			Return 0

		Case $WM_MOUSEMOVE
			$X = BitAND($lParam, 0xFFFF)
			$Y = BitShift($lParam, 16)
			$iLinkIndex = _GUICtrlSysLink_HitTest($hWnd, $X, $Y)

			If $iLinkIndex > -1 And $__DM_g_GUICtrlSysLink_Data[0] <> $iLinkIndex Then
				$__DM_g_GUICtrlSysLink_Data[0] = $iLinkIndex
				$__DM_g_GUICtrlSysLink_Data[1] = _GUICtrlSysLink_GetItemUrl($hWnd, $iLinkIndex)
				$__DM_g_GUICtrlSysLink_Data[2] = "HOVER"
				$__DM_g_GUICtrlSysLink_Data[3] = $hWnd
				AdlibRegister(__DM_SysLink_WndProc_Adlib, 10)
			EndIf

			Local $tTRACKMOUSEEVENT = DllStructCreate("dword cbSize; dword dwFlags; hwnd hwndTrack; dword dwHoverTime")
			DllStructSetData($tTRACKMOUSEEVENT, "cbSize", DllStructGetSize($tTRACKMOUSEEVENT))
			DllStructSetData($tTRACKMOUSEEVENT, "dwFlags", 2) ; TME_LEAVE
			DllStructSetData($tTRACKMOUSEEVENT, "hwndTrack", $hWnd)
			DllCall("user32.dll", "bool", "TrackMouseEvent", "struct*", $tTRACKMOUSEEVENT)

		Case $WM_MOUSELEAVE
			$__DM_g_GUICtrlSysLink_Data[0] = -1
			$__DM_g_GUICtrlSysLink_Data[1] = ""
			$__DM_g_GUICtrlSysLink_Data[2] = "LEAVE"
			$__DM_g_GUICtrlSysLink_Data[3] = $hWnd
			AdlibRegister(__DM_SysLink_WndProc_Adlib, 10)

		Case $iClickMsg
			$X = BitAND($lParam, 0xFFFF)
			$Y = BitShift($lParam, 16)
			$iLinkIndex = _GUICtrlSysLink_HitTest($hWnd, $X, $Y)

			If $iLinkIndex > -1 Then
				$__DM_g_GUICtrlSysLink_Data[0] = $iLinkIndex
				$__DM_g_GUICtrlSysLink_Data[1] = _GUICtrlSysLink_GetItemUrl($hWnd, $iLinkIndex)
				$__DM_g_GUICtrlSysLink_Data[2] = "CLICK"
				$__DM_g_GUICtrlSysLink_Data[3] = $hWnd
				;_GUICtrlSysLink_GetStateInfo($hWnd, False, True)
				AdlibRegister(__DM_SysLink_WndProc_Adlib, 10)
			EndIf

		Case $WM_KEYDOWN
			If $wParam = 0x09 Then ; Tab Key (0x09)
				Local $bShift = BitAND(_WinAPI_GetKeyState(0x10), 0x8000) <> 0 ; Is Shift held?

				; Single-pass executions via our unified state engine
				Local $iCurrentFocusIdx = _GUICtrlSysLink_GetStateInfo($hWnd, False) ; Get Focused
				Local $iTotalLinks = _GUICtrlSysLink_GetStateInfo($hWnd, True)   ; Get Count

				; Get the parent GUI window handle to search within
				Local $hParent = _WinAPI_GetParent($hWnd)

				; Tab Forward Logic
				If Not $bShift And $iCurrentFocusIdx = ($iTotalLinks - 1) Then
					Local $hNext = _WinAPI_GetNextDlgTabItem($hParent, $hWnd, False) ; solution
					If $hNext Then _WinAPI_SetFocus($hNext)
					Return 0
				EndIf

				; Tab Backward Logic
				If $bShift And $iCurrentFocusIdx = 0 Then
					Local $hPrev = _WinAPI_GetNextDlgTabItem($hParent, $hWnd, True) ; solution
					If $hPrev Then _WinAPI_SetFocus($hPrev)
					Return 0
				EndIf
			EndIf

			; Handle Action Activation (Enter = 0x0D | Space = 0x20)
			If $wParam = 0x0D Or $wParam = 0x20 Then
				Local $iActiveIdx = _GUICtrlSysLink_GetStateInfo($hWnd, False)
				If $iActiveIdx > -1 Then
					$__DM_g_GUICtrlSysLink_Data[0] = $iLinkIndex
					$__DM_g_GUICtrlSysLink_Data[1] = _GUICtrlSysLink_GetItemUrl($hWnd, $iLinkIndex)
					$__DM_g_GUICtrlSysLink_Data[2] = "CLICK"
					$__DM_g_GUICtrlSysLink_Data[3] = $hWnd
					AdlibRegister(__DM_SysLink_WndProc_Adlib, 10)
					_WinAPI_SetFocus(_WinAPI_GetParent($hWnd))

					Return 0
				EndIf
			EndIf

	EndSwitch

	Return __DM_WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>__GUIDarkTheme_SysLinkProc

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func _GUICtrlSysLink_GetItemUrl($hWnd, $iLinkIndex = 0)
	; Check process boundary to prevent memory access violations
	Local $iPID
	_WinAPI_GetWindowThreadProcessId($hWnd, $iPID)
	If $iPID <> @AutoItPID Then Return SetError(1, 0, "")

	Local Const $tagLITEM_STRICT = "struct;uint Mask;int Link;uint State;uint StateMask;wchar ID[48];wchar Url[2084];endstruct"
	Local $tLITEM = DllStructCreate($tagLITEM_STRICT)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_URL))
	DllStructSetData($tLITEM, "Link", $iLinkIndex)

	Local $aRet = _SendMessage($hWnd, $LM_GETITEM, 0, DllStructGetPtr($tLITEM), 0, "wparam", "ptr")
	Return $aRet ? DllStructGetData($tLITEM, "Url") : ""
EndFunc   ;==>_GUICtrlSysLink_GetItemUrl

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUICtrlSysLink_GetItem
; Description....: Retrieves some or all of a item's attributes
; Syntax.........: __GUICtrlSysLink_GetItem ( $hWnd, ByRef $tItem )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $tItem  - $tagLITEM structure used to request/receive item attributes
; Return values..: Success - True
;                  Failure - False
; Author.........: Paul Campbell (PaulIA)
; Modified.......: Yashied, WildByDesign
; Remarks........: This function is used internally and should not normally be called by the end user
; Related........: __GUICtrlSysLink_SetItem
; Link...........:
; Example........:
; ===============================================================================================================================
Func __GUICtrlSysLink_GetItem($hWnd, ByRef $tItem)
	Local $pItem = DllStructGetPtr($tItem)
	Local $iRet = _SendMessage($hWnd, $LM_GETITEM, 0, $pItem, 0, "wparam", "ptr")
	Return $iRet <> 0
EndFunc   ;==>__GUICtrlSysLink_GetItem

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_CallbackFunc
; Description ...: Registers or retrieves a user-defined callback function to handle SysLink interactions (Hover, Leave, Click).
; Syntax.........: _GUICtrlSysLink_CallbackFunc([$function = Default])
; Parameters ....: $function - [Optional] A valid user function pointer (using the FuncName reference), or "" to disable.
; Return values .: Success    - Returns the currently assigned function pointer.
;                  Failure    - Returns the previous pointer and sets @error to 1 if an invalid reference is provided.
; Author ........: argumentum
; Modified ......:
; Remarks .......: The registered callback function must accept exactly three arguments:
;                  $iIndex - The 0-based integer index of the specific link element, or -1 if no link is active/mouse left.
;                  $sUrl   - The string URL payload extracted from the link tag, or "" if no link is active/mouse left.
;                  $sAction- The state transition identifier ("HOVER", "LEAVE", "CLICK").
; Example .......: _GUICtrlSysLink_CallbackFunc(MyCustomDoerFunction)
; ===============================================================================================================================
Func _GUICtrlSysLink_CallbackFunc($function = Default)
	If $function <> Default Then
		If IsFunc($function) = 1 Then
			$__DM_g_GUICtrlSysLink_Callback = $function
		ElseIf $function = "" Then
			$__DM_g_GUICtrlSysLink_Callback = ""
		Else
			Return SetError(1, 0, $__DM_g_GUICtrlSysLink_Callback)
		EndIf
	EndIf
	Return $__DM_g_GUICtrlSysLink_Callback
EndFunc   ;==>_GUICtrlSysLink_CallbackFunc

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __DM_SysLink_WndProc_Adlib
; Description ...: Asynchronously dispatches cached SysLink event data to the user callback out of the window message context.
; Syntax.........: __DM_SysLink_WndProc_Adlib()
; Remarks .......: This function serves as a release valve. By deferring execution via Adlib, the window procedure can return
;                  control to Windows immediately. This prevents the GUI thread from blocking or crashing, if the user's
;                  callback executes blocking code (like MsgBox or long loops).
; Related .......: _GUICtrlSysLink_CallbackFunc, _SysLink_WndProc_in_the_UDF
; ===============================================================================================================================
Func __DM_SysLink_WndProc_Adlib()
	AdlibUnRegister(__DM_SysLink_WndProc_Adlib)
	If $__DM_g_GUICtrlSysLink_Callback <> "" And IsFunc($__DM_g_GUICtrlSysLink_Callback) Then
		$__DM_g_GUICtrlSysLink_Callback($__DM_g_GUICtrlSysLink_Data[0], $__DM_g_GUICtrlSysLink_Data[1], $__DM_g_GUICtrlSysLink_Data[2], $__DM_g_GUICtrlSysLink_Data[3])
	EndIf
EndFunc   ;==>__DM_SysLink_WndProc_Adlib

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_GetStateInfo
; Description ...: Scans the SysLink control to return total link count, the currently focused index, or selectively strip focus.
; Syntax.........: _GUICtrlSysLink_GetStateInfo($hWnd[, $bGetCount = False[, $bClearFocus = False]])
; Parameters ....: $hWnd        - Handle to the SysLink control.
;                  $bGetCount   - [Optional] True to return total link count. False to return focused link index. Default is False.
;                  $bClearFocus - [Optional] True to strip the LIS_FOCUSED state flag from items, removing the dotted focus box.
; Return values .: Success      - Integer representing either the total link count or the 0-based index of the focused link.
;                  Failure      - Returns -1 if hunting for focus and no link elements hold focus.
; Author ........: argumentum
; Modified ......:
; ===============================================================================================================================
Func _GUICtrlSysLink_GetStateInfo($hWnd, $bGetCount = False, $bClearFocus = False)
	Local Const $tagLITEM_STRICT = "struct;uint Mask;int Link;uint State;uint StateMask;wchar ID[48];wchar Url[2084];endstruct"
	Local $tLITEM = DllStructCreate($tagLITEM_STRICT)
	Local $iIdx = 0
	Local $iFocusedIdx = -1

	While 1
		DllStructSetData($tLITEM, "Mask", 0x03)       ; 0x03 = LIF_ITEMINDEX | LIF_STATE
		DllStructSetData($tLITEM, "Link", $iIdx)
		DllStructSetData($tLITEM, "stateMask", 0x01)  ; 0x01 = LIS_FOCUSED
		DllStructSetData($tLITEM, "State", 0)

		; remove dotted lines
		If $bClearFocus Then _SendMessage($hWnd, $LM_SETITEM, 0, DllStructGetPtr($tLITEM), 0, "wparam", "ptr") ; FIX

		; If the API call fails, we have successfully counted past the final link element
		If Not _SendMessage($hWnd, $LM_GETITEM, 0, DllStructGetPtr($tLITEM), 0, "wparam", "ptr") Then ExitLoop

		; If we are hunting for the focused item and find it, record the index position
		If Not $bGetCount And BitAND(DllStructGetData($tLITEM, "State"), 0x01) Then
			$iFocusedIdx = $iIdx
			ExitLoop ; Found what we came for.
		EndIf

		$iIdx += 1
		If $iIdx > 1000 Then ExitLoop ; something is very wrong
	WEnd

	If $bGetCount Then
		Return $iIdx
	EndIf

	Return $iFocusedIdx
EndFunc   ;==>_GUICtrlSysLink_GetStateInfo

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlSysLink_SetItemState
; Description....: Sets the state of the specified link of the SysLink control
; Syntax.........: _GUICtrlSysLink_SetItemState ( $hWnd, $iLink, $iState [, $fSet = True] )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $iLink  - The zero based link index
;                  $iState - The new link state, can be one or more of the following values:
;                  |$LIS_ENABLED       - The link can respond to user input
;                  |$LIS_FOCUSED       - The link has the keyboard focus
;                  |$LIS_VISITED       - The link has been visited by the user
;                  |$LIS_HOTTRACK      - Indicates that the syslink control will highlight in a different color (COLOR_HIGHLIGHT) when the mouse hovers over the control
;                  |$LIS_DEFAULTCOLORS - Enable custom text colors to be used
;                  $fSet   - Specifies whether the link state is to be set or remove, valid values:
;                  |TRUE   - Set link state (Default)
;                  |FALSE  - Remove link state
; Return values..: Success - True
;                  Failure - False
; Author.........: Yashied
; Modified.......:
; Remarks........: State values can BitOR'ed together as for example BitOR($LIS_ENABLED, $LIS_FOCUSED)
; Related........: _GUICtrlSysLink_GetItemState
; Link...........:
; Example........: Yes
; ===============================================================================================================================
Func _GUICtrlSysLink_SetItemState($hWnd, $iLink, $iState, $fSet = True)
	Local $tLITEM = DllStructCreate($tagLITEM)
	DllStructSetData($tLITEM, "Mask", BitOR($LIF_ITEMINDEX, $LIF_STATE))
	DllStructSetData($tLITEM, "Link", $iLink)
	If $fSet Then
		DllStructSetData($tLITEM, "State", $iState)
	Else
		DllStructSetData($tLITEM, "State", 0)
	EndIf
	DllStructSetData($tLITEM, "StateMask", $iState)
	Return __GUICtrlSysLink_SetItem($hWnd, $tLITEM)
EndFunc   ;==>_GUICtrlSysLink_SetItemState

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUICtrlSysLink_SetItem
; Description....: Sets some or all of a item's attributes
; Syntax.........: __GUICtrlSysLink_SetItem ( $hWnd, ByRef $tItem )
; Parameters.....: $hWnd   - Handle to the SysLink control
;                  $tItem  - $tagLITEM structure that contains the new item attributes
; Return values..: Success - True
;                  Failure - False
; Author.........: Paul Campbell (PaulIA)
; Modified.......: Yashied
; Remarks........: This function is used internally and should not normally be called by the end user
; Related........: __GUICtrlSysLink_GetItem
; Link...........:
; Example........:
; ===============================================================================================================================
Func __GUICtrlSysLink_SetItem($hWnd, ByRef $tItem)
	Local $pItem = DllStructGetPtr($tItem)
	Local $iRet = _SendMessage($hWnd, $LM_SETITEM, 0, $pItem, 0, "wparam", "ptr")
	Return $iRet <> 0
EndFunc   ;==>__GUICtrlSysLink_SetItem

; #FUNCTION# ====================================================================================================================
; Name...........: _WinAPI_GetNextDlgTabItem
; Description ...: Retrieves a handle to the first control with the WS_TABSTOP style that precedes (or follows) the specified control.
; Syntax.........: _WinAPI_GetNextDlgTabItem($hDlg, $hCtrl[, $bPrevious = False])
; Parameters ....: $hDlg      - Handle to the dialog box (parent GUI) being searched.
;                  $hCtrl     - Handle to the control used as the starting point for the search.
;                               If 0, the function uses the last (or first) control.
;                  $bPrevious - [Optional] True to search for the previous control.
;                               False (default) to search for the next control.
; Return values .: Success    - Handle to the previous (or next) control that has the WS_TABSTOP style.
;                  Failure    - 0, and sets @error to non-zero if the DLL call fails.
; Author ........: argumentum
; Remarks .......: This searches the Z-Order of controls in the specified GUI, ignoring controls that are hidden,
;                  disabled, or lack the $WS_TABSTOP style. It will wrap around the start/end of the Z-Order.
; Link ..........: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getnextdlgtabitem
; ===============================================================================================================================
Func _WinAPI_GetNextDlgTabItem($hDlg, $hCtrl, $bPrevious = False)
	Local $aRet = DllCall("user32.dll", "hwnd", "GetNextDlgTabItem", "hwnd", $hDlg, "hwnd", $hCtrl, "bool", $bPrevious)
	If @error Or Not IsArray($aRet) Then Return SetError(10 + @error, @extended, 0)
	Return $aRet[0]
EndFunc   ;==>_WinAPI_GetNextDlgTabItem

; #FUNCTION# ====================================================================================================================
; Author.........: MattyD
; ===============================================================================================================================
Func __GUIDarkTheme_WM_SETCURSOR($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam

	If _WinAPI_LoWord($lParam) <> $HTCLIENT Then
		Return _WinAPI_DefWindowProcW($hWnd, $iMsg, $wParam, $lParam)
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>__GUIDarkTheme_WM_SETCURSOR

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _WinAPI_ExtTextOut($hDC, $iX, $iY, $iOptions, $sText, $tRect = 0)
	Local $iLength = StringLen($sText)

	; Pointer to the RECT structure, or NULL if no RECT is passed
	Local $pRECT = 0
	If IsDllStruct($tRect) Then $pRECT = DllStructGetPtr($tRect)

	Local $aResult = DllCall("gdi32.dll", "bool", "ExtTextOutW", _
			"handle", $hDC, _
			"int", $iX, _
			"int", $iY, _
			"uint", $iOptions, _
			"ptr", $pRECT, _
			"wstr", $sText, _
			"uint", $iLength, _
			"ptr", 0) ; lpDx array is omitted (NULL)

	If @error Or Not $aResult[0] Then Return SetError(1, 0, False)

	Return True
EndFunc   ;==>_WinAPI_ExtTextOut

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GetFontTypeText($sFontName)
	Local $iTypeTT = 1101
	Local $iTypeOT = 1136
	Local $iTypeSF = 1103
	Local $iFlags, $iType, $sTypeTT, $sTypeOT, $sTypeSF
	Local $sDll = @SystemDir & "\comdlg32.dll"
	Local $hInstance = _WinAPI_LoadLibraryEx($sDll, $LOAD_LIBRARY_AS_DATAFILE)

	Local $aData = _WinAPI_EnumFontFamilies(0, '', $DEFAULT_CHARSET)
	If Not @error Then
		For $i = 1 To $aData[0][0]
			If Not StringInStr($aData[$i][0], $sFontName) Then ContinueLoop
			$iType = $aData[$i][4]
			$iFlags = $aData[$i][7]
			If BitAND($iType, $TRUETYPE_FONTTYPE) Then
				$iFlags = $aData[$i][7]
				If BitAND($iFlags, $NTM_TT_OPENTYPE) Then
					$sTypeOT = _WinAPI_LoadString($hInstance, $iTypeOT)
					_WinAPI_FreeLibrary($hInstance)
					Return $sTypeOT
				Else
					$sTypeTT = _WinAPI_LoadString($hInstance, $iTypeTT)
					_WinAPI_FreeLibrary($hInstance)
					Return $sTypeTT
				EndIf
			Else
				$sTypeSF = _WinAPI_LoadString($hInstance, $iTypeSF)
				_WinAPI_FreeLibrary($hInstance)
				Return $sTypeSF
			EndIf
		Next
	EndIf
	_WinAPI_FreeLibrary($hInstance)
	Return ""
EndFunc   ;==>_GetFontTypeText

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GetFontCharSet($sFontName)
	Local $iCharset

	;Local $aData = _WinAPI_EnumFontFamilies(0, $sFontName, $DEFAULT_CHARSET)
	;Local Static $aData = _WinAPI_EnumFontFamilies(0, '', $DEFAULT_CHARSET)
	Local Static $aData = _WinAPI_EnumFontFamilies()
	If Not @error Then
		For $i = 1 To $aData[0][0]
			;If Not StringInStr($aData[$i][0], $sFontName) Then ContinueLoop
			If $aData[$i][0] <> $sFontName Then ContinueLoop
			$iCharset = $aData[$i][6]
			Return $iCharset
			;If BitAND($iCharset, $SYMBOL_CHARSET) Then Return $SYMBOL_CHARSET
		Next
	EndIf
	Return ""
EndFunc   ;==>_GetFontCharSet

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _GetFontType($sFontName)
	Local $iType

	;Local $aData = _WinAPI_EnumFontFamilies(0, $sFontName, $DEFAULT_CHARSET)
	;Local Static $aData = _WinAPI_EnumFontFamilies(0, '', $DEFAULT_CHARSET)
	Local Static $aData = _WinAPI_EnumFontFamilies()
	If Not @error Then
		For $i = 1 To $aData[0][0]
			;If Not StringInStr($aData[$i][0], $sFontName) Then ContinueLoop
			If $aData[$i][0] <> $sFontName Then ContinueLoop
			$iType = $aData[$i][4]
			Return $iType
			;If BitAND($iCharset, $SYMBOL_CHARSET) Then Return $SYMBOL_CHARSET
		Next
	EndIf
	Return ""
EndFunc   ;==>_GetFontType

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func _GetFontSizes($sFont)
	Local $hDC = _WinAPI_GetDC(0)
	Local $hCallback = DllCallbackRegister("_EnumFontFamExProc", "int", "ptr;ptr;dword;lparam")

	Local $sTagLOGFONT = "long Height;long Width;long Escapement;long Orientation;long Weight;byte Italic;byte Underline;byte StrikeOut;byte CharSet;byte OutPrecision;byte ClipPrecision;byte Quality;byte PitchAndFamily;wchar FaceName[32]"
	Local $tLOGFONT = DllStructCreate($sTagLOGFONT)
	DllStructSetData($tLOGFONT, "CharSet", 1) ; DEFAULT_CHARSET (1) tells Windows to find all sizes across all charsets
	DllStructSetData($tLOGFONT, "FaceName", $sFont)
	Global $__DM_g_aFontSizes[0]

	DllCall("gdi32.dll", "int", "EnumFontFamiliesExW", _
			"handle", $hDC, _
			"ptr", DllStructGetPtr($tLOGFONT), _
			"ptr", DllCallbackGetPtr($hCallback), _
			"lparam", 0, _
			"dword", 0)

	_ArraySort($__DM_g_aFontSizes)

	DllCallbackFree($hCallback)
	_WinAPI_ReleaseDC(0, $hDC)
EndFunc   ;==>_GetFontSizes

; #FUNCTION# ====================================================================================================================
; Author.........: argumentum
; ===============================================================================================================================
Func _EnumFontFamExProc($pLogFont, $pTextMetric, $iFontType, $lParam)
	#forceref $pLogFont, $lParam, $iFontType

	Local $sTagTEXTMETRIC = "long tmHeight;long tmAscent;long tmDescent;long tmInternalLeading;long tmExternalLeading;long tmAveCharWidth;long tmMaxCharWidth;long tmWeight;long tmOverhang;long tmDigitizedAspectX;long tmDigitizedAspectY;wchar tmFirstChar;wchar tmLastChar;wchar tmDefaultChar;wchar tmBreakChar;byte tmItalic;byte tmUnderlined;byte tmStruckOut;byte tmPitchAndFamily;byte tmCharSet"
	Local $tTM = DllStructCreate($sTagTEXTMETRIC, $pTextMetric)
	Local $iHeight = DllStructGetData($tTM, "tmHeight")

	; Deduplicate
	For $i = 0 To UBound($__DM_g_aFontSizes) - 1
		If $__DM_g_aFontSizes[$i] = $iHeight Then Return 1
	Next

	_ArrayAdd($__DM_g_aFontSizes, Number($iHeight))

	Return 1
EndFunc   ;==>_EnumFontFamExProc

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func _UpdateFontSizes()
	Local $hWnd = WinGetHandle("Font")
	Local $hSize = ControlGetHandle($hWnd, "", 1138)
	Local $sEdit = _GUICtrlComboBox_GetEditText($hSize)

	_GUICtrlComboBox_ResetContent($hSize)
	_GUICtrlComboBox_SetEditText($hSize, $sEdit)
	_GUICtrlComboBox_BeginUpdate($hSize)
	For $i = UBound($__DM_g_aFontSizes) - 1 To 0 Step -1
		_GUICtrlComboBox_InsertString($hSize, $__DM_g_aFontSizes[$i], 0)
	Next
	_GUICtrlComboBox_EndUpdate($hSize)
	AdlibUnRegister("_UpdateFontSizes")
EndFunc   ;==>_UpdateFontSizes

Func _RichEdit_SetDefaultTextColor($hWnd, $iColor = Default)
	Local $sClass = _WinAPI_GetClassName($hWnd)
	If Not StringInStr($sClass, "RichEdit") Then Return SetError(101, 0, False)

	Local $tCharFormat = DllStructCreate($tagCHARFORMAT)
	DllStructSetData($tCharFormat, 1, DllStructGetSize($tCharFormat))
	If $iColor = Default Then
		DllStructSetData($tCharFormat, 3, $CFE_AUTOCOLOR)
		$iColor = 0
	Else
		If BitAND($iColor, 0xff000000) Then Return SetError(1022, 0, False)
	EndIf

	DllStructSetData($tCharFormat, 2, $CFM_COLOR)
	DllStructSetData($tCharFormat, 6, $iColor)
	Return _SendMessage($hWnd, $EM_SETCHARFORMAT, $SCF_DEFAULT, $tCharFormat, 0, "wparam", "struct*") <> 0
EndFunc   ;==>_RichEdit_SetDefaultTextColor

; #FUNCTION# ====================================================================================================================
; Author.........: Yashied
; Modified.......: jpm, WildByDesign
; ===============================================================================================================================
Func __DM_WinAPI_DwmSetWindowAttribute($hWnd, $iAttribute, $iData)
	Switch $iAttribute
		Case 2, 3, 4, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, $DWMWA_USE_IMMERSIVE_DARK_MODE, 33, 34, 35, 36, 37, 38

		Case Else
			Return SetError(1, 0, 0)
	EndSwitch

	Local $aCall = DllCall('dwmapi.dll', 'long', 'DwmSetWindowAttribute', 'hwnd', $hWnd, 'dword', $iAttribute, _
			'dword*', $iData, 'dword', 4)
	If @error Then Return SetError(@error + 10, @extended, 0)
	If $aCall[0] Then Return SetError(10, $aCall[0], 0)

	Return 1
EndFunc   ;==>__DM_WinAPI_DwmSetWindowAttribute

; #FUNCTION# ====================================================================================================================
; Name...........: _AddFontIconToImageList
; Description....: Adds an icon from font file directly to ImageList
; Syntax.........: _AddFontIconToImageList($hImageList, $sFont, $iCodePoint, $iIconSize, $iFontSize, $iTextColor, $bDarkMode)
; Parameters.....: $hImageList    - Handle to ImageList.
;                  $sFont         - Font name. Eg. Segoe MDL2 Assets
;                  $iCodePoint    - Unicode code point for character. Eg. 0xE72B
;                  $iIconSize     - Size used for ImageList icon size.
;                  $iFontSize     - Size used for character height of font glyph.
;                  $iTextColor    - Color used for font glyph. Eg. 0xRRGGBB
;                  $bDarkMode     - If True, applies gamma curve to improve light on dark
; Return values..: ImageList index
; Author.........: WildByDesign
; ===============================================================================================================================
Func _AddFontIconToImageList($hImageList, $sFont, $iCodePoint, $iIconSize = 32, $iFontSize = 24, $iTextColor = 0x000000, $bDarkMode = False)
	Local $hScreenDC = _WinAPI_GetDC(0)
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hScreenDC)
	Local $hFont = _WinAPI_CreateFont(-($iFontSize), 0, 0, 0, 400, False, False, False, 1, 0, 0, 0, 0, $sFont)
	Local $hOldFont = _WinAPI_SelectObject($hMemDC, $hFont)

	Local $tGM = DllStructCreate("uint bmBlackBoxX;uint bmBlackBoxY;long gmptGlyphOriginX;long gmptGlyphOriginY;short gmCellIncX;short gmCellIncY")
	Local $tMat2 = DllStructCreate("int eM11;int eM12;int eM21;int eM22")
	DllStructSetData($tMat2, "eM11", 0x00010000)
	DllStructSetData($tMat2, "eM22", 0x00010000)

	; Obtain glyph outline
	Local $iRet = DllCall("gdi32.dll", "uint", "GetGlyphOutlineW", "handle", $hMemDC, "uint", AscW(ChrW($iCodePoint)), "uint", 6, "struct*", $tGM, "dword", 0, "ptr", 0, "struct*", $tMat2)

	If $iRet[0] > 0 Then
		Local $iBufSize = $iRet[0]
		Local $tBuffer = DllStructCreate("byte[" & $iBufSize & "]")
		DllCall("gdi32.dll", "uint", "GetGlyphOutlineW", "handle", $hMemDC, "uint", AscW(ChrW($iCodePoint)), "uint", 6, "struct*", $tGM, "dword", $iBufSize, "struct*", $tBuffer, "struct*", $tMat2)

		; Determine offsets to center font glyph
		Local $iBoxX = DllStructGetData($tGM, "bmBlackBoxX")
		Local $iBoxY = DllStructGetData($tGM, "bmBlackBoxY")
		Local $iStride = Int(($iBoxX + 3) / 4) * 4
		Local $iOffsetX = Int(($iIconSize - $iBoxX) / 2)
		Local $iOffsetY = Int(($iIconSize - $iBoxY) / 2)

		Local $iHexColor = $iTextColor
		Local $bBaseR = BitAND(BitShift($iHexColor, 16), 0xFF)
		Local $bBaseG = BitAND(BitShift($iHexColor, 8), 0xFF)
		Local $bBaseB = BitAND($iHexColor, 0xFF)

		; Create DIB Section
		Local $tBMI = DllStructCreate("dword biSize;long biWidth;long biHeight;ushort biPlanes;ushort biBitCount;dword biCompression;dword biSizeImage;long biXPelsPerMeter;long biYPelsPerMeter;dword biClrUsed;dword biClrImportant")
		DllStructSetData($tBMI, "biSize", 40)
		DllStructSetData($tBMI, "biWidth", $iIconSize)
		DllStructSetData($tBMI, "biHeight", -$iIconSize)
		DllStructSetData($tBMI, "biPlanes", 1)
		DllStructSetData($tBMI, "biBitCount", 32)

		Local $aDIB = DllCall("gdi32.dll", "handle", "CreateDIBSection", "handle", $hMemDC, "struct*", $tBMI, "uint", 0, "ptr*", 0, "handle", 0, "dword", 0)
		Local $hBitmap = $aDIB[0]
		Local $pBits = $aDIB[4]

		If $pBits Then
			For $Y = 0 To $iBoxY - 1
				Local $targetY = $Y + $iOffsetY
				If $targetY < 0 Or $targetY >= $iIconSize Then ContinueLoop

				For $X = 0 To $iBoxX - 1
					Local $targetX = $X + $iOffsetX
					If $targetX < 0 Or $targetX >= $iIconSize Then ContinueLoop

					Local $iSrcIndex = ($Y * $iStride) + $X
					Local $iGrayVal = DllStructGetData($tBuffer, 1, $iSrcIndex + 1)

					If $iGrayVal > 0 Then
						Local $iAlpha = Int(($iGrayVal * 255) / 64)

						; Improve quality for dark mode (light text on dark background)
						If $bDarkMode Then
							; Apply a power curve (gamma adjustment) to lift shadows/edges
							Local $fNormalized = $iAlpha / 255.0
							If $iFontSize <= 20 Then
								$iAlpha = Int((($fNormalized ^ 0.5) * 255.0))
							Else
								$iAlpha = Int((($fNormalized ^ 0.8) * 255.0))
							EndIf
							If $iAlpha > 255 Then $iAlpha = 255
						EndIf

						Local $bB = Int(($bBaseB * $iAlpha) / 255)
						Local $bG = Int(($bBaseG * $iAlpha) / 255)
						Local $bR = Int(($bBaseR * $iAlpha) / 255)

						Local $pPixel = $pBits + (($targetY * $iIconSize + $targetX) * 4)
						DllStructSetData(DllStructCreate("byte b;byte g;byte r;byte a", $pPixel), "b", $bB)
						DllStructSetData(DllStructCreate("byte b;byte g;byte r;byte a", $pPixel), "g", $bG)
						DllStructSetData(DllStructCreate("byte b;byte g;byte r;byte a", $pPixel), "r", $bR)
						DllStructSetData(DllStructCreate("byte b;byte g;byte r;byte a", $pPixel), "a", $iAlpha)
					EndIf
				Next
			Next
		EndIf

		Local $iIndex = _GUIImageList_Add($hImageList, $hBitmap)
		_WinAPI_DeleteObject($hBitmap)
	EndIf

	_WinAPI_SelectObject($hMemDC, $hOldFont)
	_WinAPI_ReleaseDC(0, $hScreenDC)
	_WinAPI_DeleteObject($hFont)
	_WinAPI_DeleteDC($hMemDC)

	Return $iIndex
EndFunc   ;==>_AddFontIconToImageList

; #FUNCTION# ====================================================================================================================
; Author.........: WildByDesign
; ===============================================================================================================================
Func __DM_ScaleCheckBoxes($hWnd, $iDPI)
	; Enumerate child windows
	Local $aCtrls = _WinAPI_EnumChildWindows($hWnd, False)
	Local $hCtrl, $sClass
	Local $iSize, $hChecked, $hUnchecked
	Local $iSizeTV = 16
	Switch $iDPI
		Case 96
			$iSizeTV = 13
		Case 120
			$iSizeTV = 16
		Case 144 To 168
			$iSizeTV = 20
		Case 192 To 216
			$iSizeTV = 26
		Case 240 To 264
			$iSizeTV = 32
		Case 288 To 360
			$iSizeTV = 40
		Case 384
			$iSizeTV = 52
	EndSwitch

	If IsArray($aCtrls) Then
		For $i = 1 To $aCtrls[0][0]
			$hCtrl = $aCtrls[$i][0]
			$sClass = $aCtrls[$i][1]
			Switch $sClass
				Case 'SysListView32'
					If (BitAND(_GUICtrlListView_GetExtendedListViewStyle($hCtrl), $LVS_EX_CHECKBOXES) = $LVS_EX_CHECKBOXES) Then
						Local $hImageListLV = _GUICtrlListView_GetImageList($hCtrl, 2)
						$iSize = _GUIImageList_GetIconHeight($hImageListLV)
						;$iSize = $iSizeTV
						_GUIImageList_Remove($hImageListLV)
						If @OSBuild >= 22000 Then
							$hUnchecked = __GUIDarkTheme_GetImages($hWnd, 0, 3, $iSize, $iSize)
							$hChecked = __GUIDarkTheme_GetImages($hWnd, 5, 3, $iSize, $iSize)
							_GUIImageList_Add($hImageListLV, $hUnchecked)
							_GUIImageList_Add($hImageListLV, $hChecked)
							_WinAPI_DeleteObject($hChecked)
							_WinAPI_DeleteObject($hUnchecked)
						Else
							$hChecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_CheckedPNG($iSize), True)
							$hUnchecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_UncheckedPNG($iSize), True)
							_GUIImageList_Add($hImageListLV, $hUnchecked)
							_GUIImageList_Add($hImageListLV, $hChecked)
							_WinAPI_DeleteObject($hChecked)
							_WinAPI_DeleteObject($hUnchecked)
						EndIf
						_WinAPI_RedrawWindow($hCtrl)
					EndIf
				Case 'SysTreeView32'
					Local $sStyles = __GUIDarkTheme_hWnd2Styles($hCtrl)
					If StringInStr($sStyles, "TVS_CHECKBOXES") Then
						Local $hNewImageList = _GUIImageList_Create($iSizeTV, $iSizeTV, 5, 3, 2)
						Local $hImageListTV = _GUICtrlTreeView_GetStateImageList($hCtrl)
						If @OSBuild >= 22000 Then
							$hUnchecked = __GUIDarkTheme_GetImages($hWnd, 0, 3, $iSizeTV, $iSizeTV)
							$hChecked = __GUIDarkTheme_GetImages($hWnd, 5, 3, $iSizeTV, $iSizeTV)
							_GUIImageList_Add($hNewImageList, $hUnchecked)
							_GUIImageList_Add($hNewImageList, $hChecked)
							_WinAPI_DeleteObject($hChecked)
							_WinAPI_DeleteObject($hUnchecked)
						Else
							$hChecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_CheckedPNG($iSizeTV), True)
							$hUnchecked = _GDIPlus_BitmapCreateFromMemory(__GUIDarkTheme_UncheckedPNG($iSizeTV), True)
							_GUIImageList_Add($hNewImageList, $hUnchecked)
							_GUIImageList_Add($hNewImageList, $hChecked)
							_WinAPI_DeleteObject($hChecked)
							_WinAPI_DeleteObject($hUnchecked)
						EndIf
						_GUICtrlTreeView_SetStateImageList($hCtrl, $hNewImageList)
						If $hImageListTV Then
							_GUIImageList_Destroy($hImageListTV)
						EndIf
						;_WinAPI_RedrawWindow($hCtrl)
						_WinAPI_InvalidateRect($hCtrl)
					EndIf
			EndSwitch
		Next
	EndIf
EndFunc   ;==>__DM_ScaleCheckBoxes

Func __DM_EnumChildWindows($hParent)
	; Register the callback once (lazy initialization)
	If Not $__DM_g_hEnumCallback Then
		$__DM_g_hEnumCallback = DllCallbackRegister("__DM_EnumChildProc", "bool", "hwnd;lparam")
		$__DM_g_pEnumCallback = DllCallbackGetPtr($__DM_g_hEnumCallback)
	EndIf

	; Reset count for this run
	$__DM_g_iEnumCount = 0

	; Execute native Win32 EnumChildWindows via DllCall
	DllCall("user32.dll", "bool", "EnumChildWindows", "hwnd", $hParent, "ptr", $__DM_g_pEnumCallback, "lparam", 0)

	; Build the final 1D return array
	Local $aResult[$__DM_g_iEnumCount]
	If $__DM_g_iEnumCount > 0 Then
		For $i = 0 To $__DM_g_iEnumCount - 1
			$aResult[$i] = $__DM_g_aEnumBuffer[$i]
		Next
	EndIf

	Return $aResult
EndFunc   ;==>__DM_EnumChildWindows

Func __DM_EnumChildProc($hWnd, $lParam)
	#forceref $lParam

	; Auto-expand buffer if window tree exceeds initial 256 capacity
	If $__DM_g_iEnumCount >= UBound($__DM_g_aEnumBuffer) Then
		ReDim $__DM_g_aEnumBuffer[UBound($__DM_g_aEnumBuffer) + 256]
	EndIf

	$__DM_g_aEnumBuffer[$__DM_g_iEnumCount] = $hWnd
	$__DM_g_iEnumCount += 1

	Return True
EndFunc   ;==>__DM_EnumChildProc

Func _GetListViewGroupState($hWndListView, $iGroupID)
	Local $tagLVGROUP = "uint cbSize;uint mask;ptr pszHeader;int cchHeader;ptr pszFooter;int cchFooter;int iGroupId;uint stateMask;uint state;uint uAlign;"
	Local $tGroup = DllStructCreate($tagLVGROUP)

	$tGroup.cbSize = DllStructGetSize($tGroup)
	$tGroup.mask = $LVGF_STATE
	$tGroup.iGroupId = $iGroupID
	$tGroup.stateMask = 0xFFFFFFFF ; Request all states

	; Send the message (this populates $tGroup in memory)
	Local $iResult = _SendMessage($hWndListView, $LVM_GETGROUPINFO, $iGroupID, DllStructGetPtr($tGroup))

	If $iResult <> -1 Then
		; Read the state member from the structure, NOT the return of _SendMessage
		Return $tGroup.state
	EndIf

	Return -1
EndFunc   ;==>_GetListViewGroupState
