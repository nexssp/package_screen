#include-once
#Obfuscator_Ignore_Funcs=_XH_GUIClicked
#include <WinAPI.au3>	; _WinAPI_GetSystemMetrics()
; ===============================================================================================================================
; <_CrossHairs.au3>
;
; Functions for drawing full-screen crosshairs.
;	NOTE: OnEventMode can be forced to On so that _XH_GUIClicked() is called when the GUI is clicked
;	  (mouse moving faster than updating).  This mode is reset to the previous state on a call to _XHairUnInit()
;
; Functions:
;	_XHairInit()
;	_XHairUnInit()
;	_XHairSetDisplayProps()	; alters display properties for crosshair, or resets it in case of a screen resolution change
;	_XHairShow()	; Shows crosshairs at x,y
;	_XHairHide()	; Hides crosshairs (moves off-screen)
;
; INTERNAL Functions (do NOT call directly)
;	_XH_GUIClicked()
;
; See also:
;	<TestCrossHairs.au3>
;	<TestCrossHairMagnify.au3>	; (with magnifying tool)
;	<_MouseCursorFuncs.au3>	; misc. mouse cursor functions - cursor modifcation, hiding & replacing
;	<_GUIBox.au3>	; uses similar technique as here to create a GUI box (that can be used as a rubber-band rectangle)
;
; Author: Ascend4nt
; ===============================================================================================================================

; ===================================================================================================================
;	GLOBAL X-HAIR INDEXES AND VARIABLES [INTERNAL-USE]
; ===================================================================================================================

Global Enum $XH_LEFT_GUI,$XH_RIGHT_GUI,$XH_BOTTOM_GUI,$XH_TOP_GUI
Global Enum $XH_HGUI,$XH_XADJ,$XH_YADJ

Global $XH_aGUIs[$XH_TOP_GUI+1][$XH_YADJ+1]
Global $XH_bInit=False,$XH_bSetOnEvent=False,$XH_iThickness,$XH_iSelectBox,$XH_iXHairColor,$XH_iPrevEventMode,$XH_aLastPos[2]
Global $XH_CtrlClicked=0,$XH_WinClicked=0

; ===================================================================================================================
; Func _XH_GUIClicked()
;
; On-Event Mouse-clicked Function to notify (someone) that the GUI was clicked through a variable
;	Intended use was to send the click to the appropriate window
;	  (using say, _WinAPI_WindowFromPoint and _WinAPI_GetAncestor. Hmm.. problem is, the GUI could still be in the way)
;
; Author: Ascend4nt
; ===================================================================================================================

Func _XH_GUIClicked()
	For $i=0 To $XH_TOP_GUI
		If @GUI_WinHandle=$XH_aGUIs[$i][0] Then
			$XH_WinClicked=$i
			$XH_CtrlClicked=@GUI_CtrlId
			ExitLoop
		EndIf
	Next
	Return 'GUI_RUNDEFMSG'	; From <GUIConstantsEx.au3> Global Const $GUI_RUNDEFMSG = 'GUI_RUNDEFMSG'
EndFunc


; ===================================================================================================================
; Func _XHairInit($iThickness=3,$iSelectBox=7,$iCrossHairColor=0x808080,$iTransparency=150,$bSetOnEvent=False)
;
; Function to initialize CrossHairs GUIs & Variables
;
; $iThickness = Thickness of line
; $iSelectBox = Box centered on cursor to draw crosshairs *around* (crosshairs will not show up in box)
; $iCrossHairColor = Color of CrossHairs (gray variants are good)
; $iTransparency = level of transparency of GUI
; $bSetOnEvent = If True, OnEventMode is set, and the function _XH_GUIClicked() will be called when clicked
;	This may be removed in a future release, as the idea behind it (sending a click to the window below)
;	  might not work properly anyway.
;
; Returns: True
;
; Author: Ascend4nt
; ===================================================================================================================

Func _XHairInit($iThickness=3,$iSelectBox=7,$iCrossHairColor=0x808080,$iTransparency=150,$bSetOnEvent=False)
	If $XH_bInit Then Return True

	; Create GUI's
	;	Styles: Regular: WS_POPUP (0x80000000) + WS_CLIPSIBLINGS (0x04000000)
	;	   Extended: WS_EX_NOACTIVATE 0x08000000 $WS_EX_TOOLWINDOW (0x80) + $WS_EX_TOPMOST (0x8)
	For $i=0 To $XH_TOP_GUI
		$XH_aGUIs[$i][0]=GUICreate("",0,0,0,0,0x84000000,0x08000088)
	Next

	; Set properties and size GUI's appropriately. Calling with Transparency=0 (invisible) so to keep it hidden initially
	_XHairSetDisplayProps($iThickness,$iSelectBox,$iCrossHairColor,0,$bSetOnEvent,True)

	; Now we can show the GUI's (quickly, in invisible mode) before hiding them
	For $i=0 to $XH_TOP_GUI
		GUISetState(@SW_SHOWNOACTIVATE,$XH_aGUIs[$i][0])
	Next

	; Must show on-screen first (as above), otherwise some funky side effects (that's why we show it invisible initially)
	_XHairHide()

	; Reset transparency from invisible to passed parameter
	For $i=0 To $XH_TOP_GUI
		WinSetTrans($XH_aGUIs[$i][0],"",$iTransparency)
	Next

	Return True
	; No need to set $XH_aLastPos[0] and [1] - they are set to invalid position already by _XHairHide()
EndFunc

; ===================================================================================================================
; Func _XHairUnInit()
;
; Function to uninitialize CrossHair GUI's (call when done using them)
;
; Author: Ascend4nt
; ===================================================================================================================

Func _XHairUnInit()
	If Not $XH_bInit Then Return
	If $XH_bSetOnEvent Then
		; Restore previous event mode
		AutoItSetOption("GUIOnEventMode",$XH_iPrevEventMode)
		$XH_bSetOnEvent=False
	EndIf
	For $i=0 To $XH_TOP_GUI
		GUIDelete($XH_aGUIs[$i][0])
		$XH_aGUIs[$i][0]=0
	Next
	$XH_bInit=False
EndFunc


; ===================================================================================================================
; Func _XHairSetDisplayProps($iThickness=-1,$iSelectBox=-1,$iCrossHairColor=-1,$iTransparency=150,$bSetOnEvent=False, _
;								$bInitializing=False)
;
; Function to change the properties of the crosshair (or initialize it when called by _XHairInit()).
;	This can be called without parameters after a screen resolution change so that the GUI's are resized appropriately
;
; $iThickness = Thickness of line (-1 = use last thickness)
; $iSelectBox = Box centered on cursor to draw crosshairs *around* (crosshairs will not show up in box) (-1 = use last box size)
; $iCrossHairColor = Color of CrossHairs (gray variants are good) (-1 = use last box size)
; $iTransparency = level of transparency of GUI
; $bSetOnEvent = If True, OnEventMode is set, and the function _XH_GUIClicked() will be called when clicked
;	This may be removed in a future release, as the idea behind it (sending a click to the window below)
;	  might not work properly anyway.
; $bInitializing = DO NOT SET THIS.  This is only to be set by _XHairInit()
;
; Returns:
;	Success: True
;	Failure: False with @error set:
;		@error = 1 = invalid parameter ($bInitializing set to True)
;		@error = 2 = _XHair not initialized
;
; Author: Ascend4nt
; ===================================================================================================================

Func _XHairSetDisplayProps($iThickness=-1,$iSelectBox=-1,$iCrossHairColor=-1,$iTransparency=150,$bSetOnEvent=False,$bInitializing=False)
	If Not $bInitializing And Not $XH_bInit Then Return SetError(2,0,False)

	; Sanity check (last parameter should only be set by _XHairInit())
	If $bInitializing And Not IsHWnd($XH_aGUIs[$XH_TOP_GUI][0]) Then Return SetError(1,0,False)

	Local $iLineOffset,$iBoxOffset,$iVScrWidth,$iVScrHeight,$iX,$iY,$aSizes[$XH_TOP_GUI+1][2]

	; Default/Last thickness?
	If $iThickness<0 Then $iThickness=$XH_iThickness
	; Default/Last box size?
	If $iSelectBox<0 Then $iSelectBox=$XH_iSelectBox
	; Default/Last Color?
	If $iCrossHairColor<0 Then $iCrossHairColor=$XH_iXHairColor

	; This has to be ODD #
	If BitAND($iThickness,1)=0 Then $iThickness+=1

	$iLineOffset=BitShift($iThickness,1)
	; This *should* be odd #, but we only calculate by /2 (cutting off any remainder) anyway
	$iBoxOffset=BitShift($iSelectBox,1)

	;SM_CXVIRTUALSCREEN = 78
	$iVScrWidth=_WinAPI_GetSystemMetrics(78)
	If $iVScrWidth=0 Then $iVScrWidth=@DesktopWidth
	;SM_CYVIRTUALSCREEN = 79
	$iVScrHeight=_WinAPI_GetSystemMetrics(79)
	If $iVScrHeight=0 Then $iVScrHeight=@DesktopHeight

	; Store variables for future alterations with 'default' values set
	$XH_iThickness=$iThickness	; needed additionally for hiding the GUIs
	$XH_iSelectBox=$iSelectBox
	$XH_iXHairColor=$iCrossHairColor

	; Grab current position
	$iX=$XH_aLastPos[0]
	$iY=$XH_aLastPos[1]

	; Set sizes and offset adjustment for GUI's (offsets are to be added to the cursor position)

	; Left ->  |===[ ]
	$XH_aGUIs[$XH_LEFT_GUI][$XH_XADJ]=-($iVScrWidth-1+$iBoxOffset)
	$XH_aGUIs[$XH_LEFT_GUI][$XH_YADJ]=-$iLineOffset
	$aSizes[$XH_LEFT_GUI][0]=$iVScrWidth-1
	$aSizes[$XH_LEFT_GUI][1]=$iThickness
	; Right <-  [ ]===|
	$aSizes[$XH_RIGHT_GUI][0]=$iVScrWidth-1
	$aSizes[$XH_RIGHT_GUI][1]=$iThickness
	$XH_aGUIs[$XH_RIGHT_GUI][$XH_XADJ]=$iBoxOffset+1
	$XH_aGUIs[$XH_RIGHT_GUI][$XH_YADJ]=-$iLineOffset
	; Bottom ^  [|||]
	$aSizes[$XH_BOTTOM_GUI][0]=$iThickness
	$aSizes[$XH_BOTTOM_GUI][1]=$iVScrHeight-1
	$XH_aGUIs[$XH_BOTTOM_GUI][$XH_XADJ]=-$iLineOffset
	$XH_aGUIs[$XH_BOTTOM_GUI][$XH_YADJ]=$iBoxOffset+1
	; Top \v/  [|||]
	$aSizes[$XH_TOP_GUI][0]=$iThickness
	$aSizes[$XH_TOP_GUI][1]=$iVScrHeight-1
	$XH_aGUIs[$XH_TOP_GUI][$XH_XADJ]=-$iLineOffset
	$XH_aGUIs[$XH_TOP_GUI][$XH_YADJ]=-($iVScrHeight-1+$iBoxOffset)

	; Call function when one of the GUI's is clicked?

	If $bSetOnEvent Then
		; Already set? Then ignore
		If $XH_bSetOnEvent Then
			$bSetOnEvent=False
		Else
			$XH_bSetOnEvent=True
			; Set on-event mode so that we're notified if the GUI's are clicked (which we don't want)
			$XH_iPrevEventMode=AutoItSetOption("GUIOnEventMode", 1)
		EndIf
	EndIf

	; Set attributes and reize/move each GUI
	For $i=0 to $XH_TOP_GUI
		If @NumParams>2 Then GUISetBkColor($iCrossHairColor,$XH_aGUIs[$i][0])
		If @NumParams>3 Then WinSetTrans($XH_aGUIs[$i][0],"",0)	; Set as initially invisible (0)
		If $bSetOnEvent Then				; If true, set function to call
			; $GUI_EVENT_PRIMARYDOWN = -7
			GUISetOnEvent(-7,"_XH_GUIClicked",$XH_aGUIs[$i][0])
			; $GUI_EVENT_SECONDARYDOWN = -9
			GUISetOnEvent(-9,"_XH_GUIClicked",$XH_aGUIs[$i][0])
		EndIf
		; Called by Init routine? We set default initial positions
		If $bInitializing Then
			WinMove($XH_aGUIs[$i][0],"",0,0,$aSizes[$i][0],$aSizes[$i][1])
		Else
			WinMove($XH_aGUIs[$i][0],"",$iX+$XH_aGUIs[$i][$XH_XADJ],$iY+$XH_aGUIs[$i][$XH_YADJ],$aSizes[$i][0],$aSizes[$i][1])
		EndIf
	Next
	If $bInitializing Then $XH_bInit=True
	Return True
EndFunc


; ===================================================================================================================
; Func _XHairShow($iXPos,$iYPos)
;
; Function to draw Crosshairs at passed coordinates.
;	Note: If they are the same as the last coordinates, the crosshairs are not redrawn. (should I allow a 'force'?)
;
; $iXPos = X location to center crosshairs on
; $iYPos = Y location to center crosshairs on
;
; Returns:
;	Success: True
;	Failure: False with @error set:
;		@error = 2 = _XHair not initialized
;
; Author: Ascend4nt
; ===================================================================================================================

Func _XHairShow($iXPos,$iYPos)
	If Not $XH_bInit Then Return SetError(2,0,False)
	If $XH_aLastPos[0]=$iXPos And $XH_aLastPos[1]=$iYPos Then Return True

	; New position established
	$XH_aLastPos[0]=$iXPos
	$XH_aLastPos[1]=$iYPos

	; Set new positions by adding the adjustment values to the cursor position
	For $i=0 To $XH_TOP_GUI
		WinMove($XH_aGUIs[$i][0],"",$iXPos+$XH_aGUIs[$i][$XH_XADJ],$iYPos+$XH_aGUIs[$i][$XH_YADJ])
		WinSetOnTop($XH_aGUIs[$i][0],"",1)
	Next
	Return True
#cs
	; DEBUG
	Local $aPos
	ConsoleWrite("X-Hair Center On X:"&$iXPos&" Y:"&$iYPos&" Moved-Window Info: [order of Left,Right,Bottom,Top]:"&@CRLF)
	For $i=0 To $XH_TOP_GUI
		$aPos=WinGetPos($XH_aGUIs[$i][0])
		ConsoleWrite("Moved window #"&$i&" Handle="&$XH_aGUIs[$i][0]&" to X:"&$aPos[0]&" Y:"&$aPos[1])
		ConsoleWrite(" X2:"&$aPos[0]+$aPos[2]-1&" Y2:"&$aPos[1]+$aPos[3]-1&@CRLF)
	Next
	Return True
#ce
EndFunc


; ===================================================================================================================
; Func _XHairHide()
;
; Function to simply hide the crosshairs by putting them off-screen (which clips the entire GUI of each)
;	Much faster than WinSetState(win,"",@SW_HIDE)
;
; Returns:
;	Success: True
;	Failure: False with @error set:
;		@error = 2 = _XHair not initialized
;
; Author: Ascend4nt
; ===================================================================================================================

Func _XHairHide()
	If Not $XH_bInit Then Return SetError(2,0,False)

	WinMove($XH_aGUIs[$XH_LEFT_GUI][0],"",0,-$XH_iThickness)
	WinMove($XH_aGUIs[$XH_RIGHT_GUI][0],"",0,-$XH_iThickness)
	WinMove($XH_aGUIs[$XH_BOTTOM_GUI][0],"",-$XH_iThickness,0)
	WinMove($XH_aGUIs[$XH_TOP_GUI][0],"",-$XH_iThickness,0)

	$XH_aLastPos[0]=-2000
	$XH_aLastPos[1]=-2000
	Return True
EndFunc