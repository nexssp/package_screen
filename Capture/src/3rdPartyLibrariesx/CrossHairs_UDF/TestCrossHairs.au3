#include <_CrossHairs.au3>
#include <_MouseCursorFuncs.au3>
; ===============================================================================================================================
; <TestCrossHairs.au3>
;
; Simple test of _Crosshairs UDF.  Employs the _MouseCursorFuncs UDF as well
;
; Author: Ascend4nt
; ===============================================================================================================================

;#NoTrayIcon
AutoItSetOption("TrayAutoPause",0)

; ===============================================================================================================================
; GLOBAL VARIABLES
; ===============================================================================================================================

Global $bHKPressed=False,$bPropertyHKPressed=False,$iResolutionChangeMsg=0

; ===============================================================================================================================
; HOTKEY FUNCTIONS
; ===============================================================================================================================

; ESC Key Pressed:

Func _HotKeyPressed()
	$bHKPressed=True
EndFunc

; ALT-P Pressed:

Func _ChangeXHairProperties()
	; 'Grow' the crosshairs and set them to Red
	If Not $bPropertyHKPressed Then
		_XHairSetDisplayProps(25,25,0xFF0000)
	Else
		_XHairSetDisplayProps(8,8,0xF0F0F0)
	EndIf
	$bPropertyHKPressed=Not $bPropertyHKPressed
EndFunc


; ===============================================================================================================================
; WINDOWS MESSAGE HANDLER FUNCTIONS
; ===============================================================================================================================


; ===============================================================================================================================
; Func _ResolutionChanged($hWnd,$iMsg,$wParam,$lParam)
;
; Note this registers multiple-monitor settings changes too, but will only report on the primary monitor's resolution
;	This is why we would need to call _WinAPI_GetSystemMetrics() to get the Virtual width/height
; ===============================================================================================================================

Func _ResolutionChanged($hWnd,$iMsg,$wParam,$lParam)
#cs
	; DEBUG
	Local $iWidth,$iHeight,$iVScrWidth,$iVScrHeight
	ConsoleWrite("Resolution changed message received. Info: hWnd="&$hWnd&" Message ID:"&Hex($iMsg)&" wParam:"&$wParam&" lParam:"&$lParam&@CRLF)

	; Note the documentation says lo/hi word for width/height.	Same for x64 code where $lParam is 2x the size?
	$iWidth=BitAND($lParam,0xFFFF)
	$iHeight=BitAND(BitShift($lParam,16),0xFFFF)

	;SM_CXVIRTUALSCREEN = 78
	$iVScrWidth=_WinAPI_GetSystemMetrics(78)
	;SM_CYVIRTUALSCREEN = 79
	$iVScrHeight=_WinAPI_GetSystemMetrics(79)

	ConsoleWrite("  Bit Depth in bits-per-pixel:"&Number($wParam)&" Width:"&$iWidth&" Height:"&$iHeight)
	ConsoleWrite(" Virtual Screen Width:"&$iVScrWidth&" Virtual Screen Height:"&$iVScrHeight&@CRLF)
#ce
	$iResolutionChangeMsg+=1
	Return 'GUI_RUNDEFMSG'		; From <GUIConstantsEx.au3> Global Const $GUI_RUNDEFMSG = 'GUI_RUNDEFMSG'
EndFunc


; ===================================================================================================================
;	START MAIN CODE
; ===================================================================================================================

Dim $aNewMousePos

; Create the crosshairs (but don't make them visible yet)
_XHairInit(11,11)

HotKeySet("{ESC}","_HotKeyPressed")
; Alt-p switches between two alternate CrossHair properties
HotKeySet("!p","_ChangeXHairProperties")

; ----------------------------------------------------------------------------------------------------|
; Register Display-Mode changes to our function.
;	NOTE that a GUI (*any* GUI) MUST be created or else the WM_DISPLAYCHANGE message won't be received
;	  Luckily, we've just created four GUI's using _XHairInit() and don't need to create any further
;	ALSO note that this is called for *every* GUI that is created (for *just* X-Hairs, thats 4 calls)
; ----------------------------------------------------------------------------------------------------|
GUIRegisterMsg(0x007E,"_ResolutionChanged")	;	WM_DISPLAYCHANGE 0x007E

_MouseHideAllCursors()
;~ _MouseReplaceAllCursors()	; Alternatively replace all cursors with custom crosshair

While Not $bHKPressed
	; 4 Messages are sent, 1 for each GUI created
	If $iResolutionChangeMsg>=4 Then
		; Call with no arguments so that it will retain old properties but adjust to new resolution
		_XHairSetDisplayProps()
		$iResolutionChangeMsg=0
	EndIf
	$aNewMousePos=MouseGetPos()
	_XHairShow($aNewMousePos[0],$aNewMousePos[1])
	Sleep(5)
WEnd
; Unregister Display Mode change function
GUIRegisterMsg(0x007E,"")	;	WM_DISPLAYCHANGE 0x007E
; Destroy Crosshairs
_XHairUnInit()
; And restore all system cursors back to normal
_MouseRestoreAllCursors()