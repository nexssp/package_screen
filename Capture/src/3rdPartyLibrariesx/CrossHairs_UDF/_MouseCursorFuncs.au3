#include-once
; ===============================================================================================================================
; <_MouseCursorFuncs.au3>
;
; Misc. Mouse Cursor Functions
;
; Functions:
;	_MouseGetCursor()	; Return current system cursor
;	_MouseLoadCursor()	; Load cursor (can be used for standard cursor ID's (see below chart and function header)
;	_MouseLoadCursorX()	; Function that supersedes old LoadCursor function
;	_MouseDestroyCursor()		; destroy loaded mouse cursor
;	_MouseSetCursor()			; sets Mouse Cursor for current window/thread
;	_MouseSetCursorVisibility()	; set Visibility of mouse for current window/thread
;	_MouseReplaceAllCursors()	; Replaces all cursors with a crosshair cursor (with hollowed center)
;	_MouseHideAllCursors()		; Replaces all cursors with an invisible cursor (could be used with CrossHair UDF)
;	_MouseRestoreAllCursors()	; Restores all current default system cursors
;
; See also:
;	<_CrossHairs.au3>	; full-screen cross hairs
;
; Author: Ascend4nt
; ===============================================================================================================================

#cs
; -------------------------------------------------------------------------------------------------------------------
; Standard Cursor IDs
; ---------------------
;	#define IDC_ARROW           MAKEINTRESOURCE(32512)
;	#define IDC_IBEAM           MAKEINTRESOURCE(32513)
;	#define IDC_WAIT            MAKEINTRESOURCE(32514)
;	#define IDC_CROSS           MAKEINTRESOURCE(32515)
;	#define IDC_UPARROW         MAKEINTRESOURCE(32516)
;	#define IDC_SIZE            MAKEINTRESOURCE(32640)  /* OBSOLETE: use IDC_SIZEALL */
;	#define IDC_ICON            MAKEINTRESOURCE(32641)  /* OBSOLETE: use IDC_ARROW */
;	#define IDC_SIZENWSE        MAKEINTRESOURCE(32642)
;	#define IDC_SIZENESW        MAKEINTRESOURCE(32643)
;	#define IDC_SIZEWE          MAKEINTRESOURCE(32644)
;	#define IDC_SIZENS          MAKEINTRESOURCE(32645)
;	#define IDC_SIZEALL         MAKEINTRESOURCE(32646)
;	#define IDC_NO              MAKEINTRESOURCE(32648) /*not in win3.1 */
;	#if(WINVER >= 0x0500)
;	#define IDC_HAND            MAKEINTRESOURCE(32649)
;	#endif /* WINVER >= 0x0500 */
;	#define IDC_APPSTARTING     MAKEINTRESOURCE(32650) /*not in win3.1 */
;	#if(WINVER >= 0x0400)
;	#define IDC_HELP            MAKEINTRESOURCE(32651)
;	#endif /* WINVER >= 0x0400 */
; -------------------------------------------------------------------------------------------------------------------
;	#define OCR_NORMAL          32512
;	#define OCR_IBEAM           32513
;	#define OCR_WAIT            32514
;	#define OCR_CROSS           32515
;	#define OCR_UP              32516
;	#define OCR_SIZE            32640   /* OBSOLETE: use OCR_SIZEALL */
;	#define OCR_ICON            32641   /* OBSOLETE: use OCR_NORMAL */
;	#define OCR_SIZENWSE        32642
;	#define OCR_SIZENESW        32643
;	#define OCR_SIZEWE          32644
;	#define OCR_SIZENS          32645
;	#define OCR_SIZEALL         32646
;	#define OCR_ICOCUR          32647   /* OBSOLETE: use OIC_WINLOGO */
;	#define OCR_NO              32648
;	#if(WINVER >= 0x0500)
;	#define OCR_HAND            32649
;	#endif /* WINVER >= 0x0500 */
;	#if(WINVER >= 0x0400)
;	#define OCR_APPSTARTING     32650
;	#endif /* WINVER >= 0x0400 */
; -------------------------------------------------------------------------------------------------------------------
#ce

; ===================================================================================================================
; Func _MouseGetCursor()
;
; Returns the current mouse cursor
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseGetCursor()
	Local $aRet=DllCall("user32.dll","ptr","GetCursor")
	If @error Then Return SetError(2,@error,False)
	Return $aRet[0]
EndFunc

; ===================================================================================================================
; Func _MouseLoadCursor($hModule,$sCursorName)
;
; Load a mouse cursor from module. Can also load predefined cursors (use Ptr(0),# as parameters)
;	EXAMPLE: (Load Standard CrossHair cursor):
;	  $hCrossHair=_MouseLoadCursor(Ptr(0),32515)
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseLoadCursor($hModule,$sCursorName)
	If Not IsPtr($hModule) Then Return SetError(1,0,False)
	Local $aRet=DllCall("user32.dll","ptr","LoadCursor","ptr",$hModule,"ulong_ptr",$sCursorName)
	If @error Then Return SetError(2,@error,False)
	Return $aRet[0]
EndFunc


; ===================================================================================================================
; Func _MouseLoadCursorX($hModule,$sCursorName)
;
; Function that 'supersedes' LoadCursor ($sCursorName=filename of cursor):
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseLoadCursorX($hModule,$sCursorName)
	If Not IsPtr($hModule) Then Return SetError(1,0,False)
;	HANDLE LoadImage(HINSTANCE hinst,LPCTSTR lpszName,UINT uType,int cxDesired,int cyDesired,UINT fuLoad);
	; IMAGE_CURSOR = 2; LR_LOADFROMFILE     0x00000010
	Local $aRet=DllCall("user32.dll","ptr","LoadImageW","ptr",$hModule,"wstr",$sCursorName,"dword",2,"int",0,"int",0,"dword",0x10)
	If @error Then Return SetError(2,@error,False)
	Return $aRet[0]
EndFunc

; ===================================================================================================================
; Func _MouseDestroyCursor($hCursor)
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseDestroyCursor($hCursor)
	If Not IsPtr($hCursor) Or $hCursor=0 Then Return SetError(1,0,False)
	Local $aRet=DllCall("user32.dll","int","DestroyCursor","ptr",$hCursor)
	If @error Then SetError(2,@error,False)
	Return $aRet[0]
EndFunc

; ===================================================================================================================
; Func _MouseSetCursor($hCursor)
;
; Sets the mouse cursor, returns the old one (or error code)
;
; Problem: probably only works for current GUI (and current 'thread')
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseSetCursor($hCursor)
	If Not IsPtr($hCursor) Then Return SetError(1,0,False)
	Local $aRet=DllCall("user32.dll","ptr","SetCursor","ptr",$hCursor)
	If @error Then Return SetError(2,@error,False)
	Return $aRet[0]
EndFunc

; ===================================================================================================================
; Func _MouseSetCursorVisibility($bShow)
;
; Sets the mouse cursor to visible or invisible based on parameter.
; Problem: only works for current GUI (and current 'thread')
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseSetCursorVisibility($bShow)
	Local $aRet=DllCall("user32.dll","int","ShowCursor","int",$bShow)
	If @error Then Return SetError(2,@error,False)
	Return $aRet[0]
EndFunc


; ===================================================================================================================
;	GLOBAL Standard Mouse Cursors and Replace/Restore Cursor function Variables
; ===================================================================================================================

; See 'Standard Cursor IDs' above
Global $MCF_aSysCursors[16][2]=[ _
	[32512,0], [32513,0], [32514,0], [32515,0], [32516,0], [32640,0], [32641,0], [32642,0], [32643,0], [32644,0], [32645,0], [32646,0], [32647,0], [32648,0], [32649,0], [32650,0] ]

Global $MCF_bCursorsReplaced=False

; ===================================================================================================================
; Func _MouseReplaceAllCursors()
;
; Replaces all cursors with a crosshair cursor.
;	Probably should add more functionality in the future (we can replace with any cursor, including predefined ones)
;
;
; AND mask	XOR mask	Display
; --------|-----------|---------
;	0		0			Black
;	0		1			White
;	1		0			Screen
;	1		1			Reverse screen
; --------|-----------|---------
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseReplaceAllCursors()
	If $MCF_bCursorsReplaced Then Return True
	Local $i,$iErrCount=0,$hCrossHair,$hTempCopy,$stCursor,$aRet

	; Lets make a 32x32 cursor [1bpp] (32/8=4*32=128)
	$stCursor=DllStructCreate("ubyte[128];ubyte[128]")

	; 32x32 cursor - each bit corresponds to a pixel (4 pixels per hex #)
	DllStructSetData($stCursor,1,"0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF")
	; each bit corresponds to a pixel (4 pixels per hex #) (the rest we'll leave zeroed)
	DllStructSetData($stCursor,2,"0x01000000010000000100000001000000010000000100000001000000FEFE0000010000000100000001000000010000000100000001000000010000000000")

	; Center pixel (7,7 for 15x15 [or 16x16 officially])
	$hCrossHair=DllCall("user32.dll","ptr","CreateCursor","ptr",0,"int",7,"int",7,"int",32,"int",32,"ptr",DllStructGetPtr($stCursor,1),"ptr",DllStructGetPtr($stCursor,2))

	If @error Then Return SetError(2,@error,False)
	$hCrossHair=$hCrossHair[0]
;~ 	ConsoleWrite("cursor:"&$hCrossHair&@CRLF)

	; Make copy, one for each cursor to be replaced [don't ask me why I can't reuse one - it just doesn't work]
	; (REQUIRED for SetSystemCursor calls)	; (*CopyCursor is a macro for CopyIcon)
	For $i=0 to UBound($MCF_aSysCursors)-1
		$hTempCopy=DllCall("user32.dll","ptr","CopyIcon","ptr",$hCrossHair)

		If @error Then
			$iErrCount+=1
			ContinueLoop
		EndIf

		$MCF_aSysCursors[$i][1]=$hTempCopy[0]
		; Replace with copy of crosshair
		$aRet=DllCall("user32.dll","int","SetSystemCursor","ptr",$hTempCopy[0],"dword",$MCF_aSysCursors[$i][0])
		If @error Then
			$iErrCount+=1
;~ 			ConsoleWrite("@error="&@error&" for SetSystemCursor"&@CRLF)
		EndIf
;~ 		ConsoleWrite("Return for #"&$i&":"&$aRet[0]&", ID:"&$MCF_aSysCursors[$i][0]&" Handle:"&$MCF_aSysCursors[$i][1]&" Msg:"&_WinAPI_GetLastErrorMessage())
	Next
	; Destroy cursor created (and copied)
	DllCall("user32.dll","int","DestroyCursor","ptr",$hCrossHair)

	If $iErrCount=16 Then Return SetError(2,-1,False)
;~ 	ConsoleWrite("Total Errors:"&$iErrCount&" for _MouseReplaceAllCursors"&@CRLF)
	$MCF_bCursorsReplaced=True
EndFunc


; ===================================================================================================================
; Func _MouseHideAllCursors()
;
; Hides all cursors.
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseHideAllCursors()
	If $MCF_bCursorsReplaced Then Return True
	Local $i,$iErrCount=0,$hTempCopy,$aRet,$stCursor,$hCursor

	$stCursor=DllStructCreate("ubyte[128];ubyte[128]")

	; Create an invisible cursor ->  32x32  (8x8 works but gives artifacts when manipulating items with mouse)
	DllStructSetData($stCursor,1,"0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF")
	DllStructSetData($stCursor,2,0)

	$hCursor=DllCall("user32.dll","ptr","CreateCursor","ptr",0,"int",0,"int",0,"int",32,"int",32,"ptr",DllStructGetPtr($stCursor,1),"ptr",DllStructGetPtr($stCursor,2))

	If @error Then Return SetError(2,@error,False)
	$hCursor=$hCursor[0]
;~ 	ConsoleWrite("cursor:"&$hCursor&@CRLF)

	; Make copy, one for each icon to be replaced [don't ask me why I can't reuse one - it just doesn't work]
	; (REQUIRED for SetSystemCursor calls)  (*CopyCursor is a macro for CopyIcon)
	For $i=0 to UBound($MCF_aSysCursors)-1
		$hTempCopy=DllCall("user32.dll","ptr","CopyIcon","ptr",$hCursor)

		If @error Then
			$iErrCount+=1
			ContinueLoop
		EndIf

		$MCF_aSysCursors[$i][1]=$hTempCopy[0]
		; Replace with copy of crosshair
		$aRet=DllCall("user32.dll","int","SetSystemCursor","ptr",$hTempCopy[0],"dword",$MCF_aSysCursors[$i][0])
		If @error Then $iErrCount+=1
;~ 		If Not @error Then ConsoleWrite("Return for #"&$i&":"&$aRet[0]&", ID:"&$MCF_aSysCursors[$i][0]&" Handle:"&$MCF_aSysCursors[$i][1]&" Msg:"&_WinAPI_GetLastErrorMessage())
	Next
	; Destroy cursor created (and copied)
	DllCall("user32.dll","int","DestroyCursor","ptr",$hCursor)

	If $iErrCount=16 Then Return SetError(2,-1,False)
;~ 	ConsoleWrite("Total Errors:"&$iErrCount&" for _MouseHideAllCursors"&@CRLF)
	$MCF_bCursorsReplaced=True
EndFunc

; ===================================================================================================================
; Func _MouseRestoreAllCursors()
;
; Restores all the current default system cursors.
;
; Author: Ascend4nt
; ===================================================================================================================

Func _MouseRestoreAllCursors()
	If Not $MCF_bCursorsReplaced Then Return True
	Local $i,$iErrCount=0,$aRet
	;	SPI_SETCURSORS  0x0057		; Restores system default cursors
	$aRet=DllCall("user32.dll","int","SystemParametersInfoW","dword",0x57,"dword",0,"ptr",0,"dword",0)
	For $i=0 to UBound($MCF_aSysCursors)-1
		; Destroy copy
		$aRet=DllCall("user32.dll","int","DestroyCursor","ptr",$MCF_aSysCursors[$i][1])
		If @error Then
			$iErrCount+=1
			ContinueLoop
		EndIf
		$MCF_aSysCursors[$i][1]=0
	Next
	If $iErrCount=16 Then Return SetError(2,-1,False)
;~ 	ConsoleWrite("Total Errors:"&$iErrCount&" for _MouseRestoreAllCursors"&@CRLF)
	$MCF_bCursorsReplaced=False
EndFunc

