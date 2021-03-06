#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#InstallMouseHook
#InstallKeybdHook
#HotkeyModifierTimeout -1
#MaxThreadsPerHotkey 6
#MaxHotkeysPerInterval 10000 ;Stops warning when mouse spins really fast
#SingleInstance Force
#Include %A_ScriptDir%\HoverScroll.ahk

; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
CoordMode, Mouse, Screen
SetMouseDelay, -1
SetKeyDelay, -1
SetBatchLines, -1 ;Run as fast as possible
Process Priority,,R

; General Settings
szIgnoreProcesses:="" ; RegEx Match to ignore windows with these process names
szAllowProcesses:=""
szSettingsPath:="CustomMouseGestures.ini" ; Filename only means WorkingDir is assumed, since we set WorkingDir above its A_ScriptDir

; Settings for Mouse Gestures (todo...)


; Load Ini Settings
LoadSettings()

; Trap Hook
OnExit("Exit_CustomMouseGestures")

; Incode Vars (dont' change)
listSnappedWindows=""
mWheelUsed:=0
bBlockActivation:=0
SetTimer, CheckActiveWindow, 1000
return

CheckActiveWindow:
	WinGet, active_id, ID, A
	if (!IsWindowValid(active_id)){
		Suspend, On
	}
	else {
		Suspend, Off
	}
return


*~LButton::

	MouseGetPos, x, y, hwnd

	SendMessage, 0x84, 0, (x&0xFFFF) | (y&0xFFFF) << 16,, ahk_id %hwnd%

	RegExMatch("ERROR TRANSPARENT NOWHERE CLIENT CAPTION SYSMENU SIZE MENU HSCROLL VSCROLL MINBUTTON MAXBUTTON LEFT RIGHT TOP TOPLEFT TOPRIGHT BOTTOM BOTTOMLEFT BOTTOMRIGHT BORDER OBJECT CLOSE HELP", "(?:\w+\s+){" . ErrorLevel+2&0xFFFFFFFF . "}(?<AREA>\w+\b)", HT)

	if htarea!=CAPTION
	{
		Return
	}

	MouseGetPos,_x,_y

	While GetKeyState("LButton","P") && x=_x && y=_y ;Wait until user begins dragging
	{
		MouseGetPos,_x,_y
	}

	While GetKeyState("LButton","P") ;Show ToolTip while dragging
	{
		;ToolTip Dragging window

	}

	;ToolTip ;hide ToolTip

Return

;#Home::
;	MoveWinTo("top")
;return
;
;#Ins::
;	MoveWinTo("topleft")
;return
;
;#PgUp::
;	MoveWinTo("topright")
;return
;
;#End::
;	MoveWinTo("bottom")
;return
;
;#Del::
;	MoveWinTo("bottomleft")
;return
;
;#PgDn::
;	MoveWinTo("bottomright")
;return
;
;#Up::
;	MoveWinTo("maximize")
;return
;
;#Down::
;	MoveWinTo("restore")
;return
;
;#Left::
;	MoveWinTo("left")
;return
;
;#Right::
;	MoveWinTo("right")
;return

SnapWindow(hWnd){

	global listSnappedWindows

	; Prevent snapped windows from being snapped once more
	Loop, parse, listSnappedWindows, `n
	{
		if (A_LoopField = hWnd){
			
			return
		}
	}

	; Snap Window
	;Send, #{Right}
	listSnappedWindows=%hWnd%`n%listSnappedWindows%
}

UnSnapWindow(hWnd){

	global listSnappedWindows

	newListOfSnappedWindows=""

	Loop, parse, listSnappedWindows, `n
	{
		if (A_LoopField = hWnd){

			;Send, #{Down}
		}
		else {

			newListOfSnappedWindows=%hWnd%`n%newListOfSnappedWindows%
		}
	}

	listSnappedWindows:=newListOfSnappedWindows
}

MoveWinTo(quadrant="top") {

	
	global bBlockActivation

	if (bBlockActivation=1){
		return
	}

	WinGet, active_id, ID, A

	if (active_id="") {
		return
	}
	
	bBlockActivation:=1

	WinGetPos, x, y,,, ahk_id %active_id%,,,


	;MsgBox, Going to...`nx%x%x %y%y`nwidth: %width% height:%height%
	;Send, #{Down}
	;WinRestore, ahk_id %active_id%

	if (quadrant="restore") {

		UnSnapWindow(active_id)
	}
	else {

		monitor:=GetMonitorByPos(x+10, y+10)

		result:=GetMonitorQuadrant(monitor, quadrant, x, y, width, height)

		if (result<>1) {

			SnapWindow(active_id)
			WinMove, ahk_id %active_id%,, x, y, width, height
		}
	}

	bBlockActivation:=0
}

HideWindowBorder(hWnd){

	WinSet, Style, -0xC00000, %hWnd% ; hide title bar
	WinSet, Style, -0x800000, %hWnd% ; hide thin-line border
	WinSet, Style, -0x400000, %hWnd% ; hide dialog frame
	WinSet, Style, -0x40000 , %hWnd%; hide thickframe/sizebox
}

ShowWindowBorder(hWnd){

	WinSet, Style, +0xC00000, %hWnd% ; hide title bar
	WinSet, Style, +0x800000, %hWnd% ; hide thin-line border
	WinSet, Style, +0x400000, %hWnd% ; hide dialog frame
	WinSet, Style, +0x40000 , %hWnd%; hide thickframe/sizebox
}

GetMonitorByPos(x, y) {
	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
	    SysGet, Monitor, Monitor, %A_Index%
	    if (MonitorLeft < x AND x < MonitorRight AND MonitorTop < y AND y < MonitorBottom)
	    {
	    	; MsgBox, index: %A_Index% `nLeft: %MonitorLeft% `nTop: %MonitorTop% `nRight: %MonitorRight% `nBottom: %MonitorBottom% `n`nMouseX: %x% `nMouseY: %y%
	    	return, %A_Index%
	    }
	}
}

GetMonitorQuadrant(monitorNumber, quadrantName="top", ByRef x=0, ByRef y=0, ByRef width=0, ByRef height=0) {

	SysGet, MonitorWorkArea, MonitorWorkArea, %monitorNumber%

	width:=MonitorWorkAreaRight-MonitorWorkAreaLeft
	height:=MonitorWorkAreaBottom-MonitorWorkAreaTop

	if (quadrantName="top") {
		
		height:=Round(height/2)

		x:=MonitorWorkAreaLeft
		y:=MonitorWorkAreaTop
	}
	else if (quadrantName="topleft") {

		width:=Round(width/2)
		height:=Round(height/2)

		x:=MonitorWorkAreaLeft
		y:=MonitorWorkAreaTop
	}
	else if (quadrantName="topright") {

		width:=Round(width/2)
		height:=Round(height/2)

		x:=MonitorWorkAreaRight-width
		y:=MonitorWorkAreaTop
	}
	else if (quadrantName="bottom") {

		height:=Round(height/2)

		x:=MonitorWorkAreaLeft
		y:=MonitorWorkAreaBottom-height
	}
	else if (quadrantName="bottomleft") {

		width:=Round(width/2)
		height:=Round(height/2)

		x:=MonitorWorkAreaLeft
		y:=MonitorWorkAreaBottom-height
	}
	else if (quadrantName="bottomright") {

		width:=Round(width/2)
		height:=Round(height/2)

		x:=MonitorWorkAreaRight-width
		y:=MonitorWorkAreaBottom-height
	}
	else if (quadrantName="maximize") {

		width:=width+8
		height:=height+8
		
		x:=MonitorWorkAreaLeft-4
		y:=MonitorWorkAreaTop-4
	}
	else if (quadrantName="left") {

	}
	else if (quadrantName="right") {

	}
	else {
		ToolTipTime("error unknowen quadrant: %quadrantName%")
		return, 1
	}
}

^!F4::
	WinGet, activeID, ID, A
	WinGet, activePID, PID, A

	WinKill, ahk_id %active_id%
	
	WinWaitClose, ahk_id %active_id%,, 1
	if ErrorLevel
	{
		Process, Close, %activePID%
	}

return

^+F1::
	toggleVirtualDesktop()
return

toggleVirtualDesktop(){
	static virtDesktopToggle
	
	if (virtDesktopToggle == true) {
		send, ^!{Left}
		;ToolTip, #1virtDesktopToggle: %virtDesktopToggle%
		virtDesktopToggle := false

	}
	else {
		send, ^!{Right}
		;ToolTip, #2virtDesktopToggle: %virtDesktopToggle%
		virtDesktopToggle := true
	}
}

^F2::
	MouseGetPos,,, hWnd,, 2 ; Get window handle under the mouse position
	WinGet, winProcessName, ProcessName, ahk_id %hWnd% ; Get processname form the window under the mouse

	; add the processname to the ignore list
	szIgnoreProcesses=%winProcessName%|%szIgnoreProcesses%

	; Quick info for the user whats new in the list
	TrayTip, New Application, Process '%winProcessName%' added to the ignore list, 5, 1

	SaveSettings()
return


; Pixel precise scrolling??
; https://msdn.microsoft.com/en-us/library/windows/desktop/bb787593%28v=vs.85%29.aspx

WheelUp::
WheelDown::

	; Settings for Fast Scrolling
	WheelDelta := 120 << 16 ;As defined by Microsoft
	NormalScrollSpeed := 1 * WheelDelta
	FastScrollSpeed := 6 * WheelDelta

	MouseGetPos,,, hWnd,, 2

	WinGetTitle, hWinTitle, ahk_id %hWnd%

	if (hWinTitle == "") {
		if (GetKeyState("Ctrl", P)) {
			ToolTipTime("Window name is empty!")
		}
		Send, {%A_ThisHotkey%}
		return
	}

	IfWinNotActive, ahk_id %hWnd%
	{
		WinActivate, ahk_id %hWnd%
	}

	if (GetKeyState("RButton","P")) {

		; Disable Gestures
		mWheelUsed:=A_ThisHotkey

		if (A_ThisHotkey="WheelUp") {
			;FocuslessScroll(FastScrollSpeed)
			HoverScroll(6)
		}
		else if (A_ThisHotKey="WheelDown") {
			;FocuslessScroll(-FastScrollSpeed)
			HoverScroll(-6)
		}
	}
	else {
		if (A_ThisHotkey="WheelUp") {
			;FocuslessScroll(NormalScrollSpeed)
			HoverScroll(1)
		}
		else if (A_ThisHotKey="WheelDown") {
			;FocuslessScroll(-NormalScrollSpeed)
			HoverScroll(-1)
		}
	}
return


$*MButton::
	;Hotkey, $*MButton Up, MButtonup, off
	
	;MouseGetPos,,, hWnd,, 2
	;WinGet, winProcessName, ProcessName, ahk_id %hWnd%
	;if (winProcessName == "sublime_text.exe" && !GetKeyState("RButton"))
	;{
	;	Send, {MButton down}
	;	;tooltip, down
	;	KeyWait, MButton
	;	Send, {MButton up}
	;	;tooltip, up
	;	return
	;}

	KeyWait, MButton, T0.2
	If ErrorLevel = 1
	{
		Hotkey, $*MButton Up, MButtonup, on
		MouseGetPos, ox, oy
	 	SetTimer, WatchTheMouse, 50
		;SystemCursor("Toggle")
	}
	Else
	{
		Send {MButton}
	}
return

MButtonup:
	Hotkey, $*MButton Up, MButtonup, off
	SetTimer, WatchTheMouse, off
	;SystemCursor("Toggle")
return

; Initial start after MBUTTON has been pressed long enough: Scroll as soon the mouse has moved 4px into one direction
; When scrolling has stopped (ie: mouse is not moving anymore after 150ms), start at the initial point again.
; During mouse movement (unchanged direction), continue to scroll.
; When the delta of the mouse distance is over 5 increase by one more scroll event. (over 10 = two more scroll events)
WatchTheMouse:
    MouseGetPos, nx, ny
    dy := ny-oy
    dx := nx-ox

    ; When moving the mouse up and down  
    If (dy**2 > 3 and dy**2>dx**2)
    {
    	; When the delta of the mouse distance is over 5 increase by one more scroll event. (over 10 = two more scroll events)
        multiplyer := Floor(Abs(dy) / 5)
        
		If (dy > 0)
        {
			;Click Wheelup
            doTheScrollDirection := 1 + multiplyer
        }
		Else
        {
			;Click WheelDown
            doTheScrollDirection := -1 - multiplyer
        }
    }

    if (doTheScrollDirection != 0)
    {
        MouseGetPos,,, hWnd,, 2
        IfWinNotActive, ahk_id %hWnd%
		{
			WinActivate, ahk_id %hWnd%
		}
        LineScroll(hWnd, 0, doTheScrollDirection)
        doTheScrollDirection := 0
    }

    ;tooltip, times: %times%`ndy: %dy% dx: %dx%`nmulti: %multiplyer%
    MouseMove ox, oy
return

LineScroll(hWnd, dx, dy)
{
	;DllCall("ScrollWindowEx" , UInt, hWnd, Int, dx, Int, dy, Int, NULL, Int, NULL, Int, 0, Int, 0, Uint, NULL)
	if (dy < 0)
	{
		direction := 1
	}
	else if dy > 0
	{
		direction := 0
	}

	coordmode, mouse, screen
	mousegetpos mx,my,mouseWindowHandle,mouseControlHandle,2
	setformat,integer,hex
	handle_:= DllCall("WindowFromPoint", Int,x, Int,y)
	;handle_ +=0

	;tooltip mouse=%mouseWindowHandle% + %mouseControlHandle%  foundhandle=%handle_%

	repeat := Abs(dy)
	loop %repeat%
	{
		;tooltip, direction: %direction%`ndy: %dy%
		

		DllCall("PostMessage","PTR",mouseWindowHandle,"UInt",0x115,"PTR",direction,"PTR",1)
	}
}

FocuslessScroll(ScrollStep)
{
	
	MouseGetPos, m_x, m_y,, Target1, 2
	MouseGetPos, m_x, m_y,, Target2, 3
	
	MouseGetPos,,,MouseWin
	ControlGet, List, List, Selected, Target1
	Loop, Parse, List, `n  ; Rows are delimited by linefeeds (`n).
	{
	    RowNumber := A_Index
	    Loop, Parse, A_LoopField, %A_Tab%  ; Fields (columns) in each row are delimited by tabs (A_Tab).
	        MsgBox Row #%RowNumber% Col #%A_Index% is %A_LoopField%.
	}
	
	;If Target1 != Target1, only one will work, but it is not known which, so using both won't hurt
	If(Target1 != Target2)
	{
		SendMessage, 0x20A, ScrollStep, (m_y << 16) | m_x,, ahk_id %Target1%
		SendMessage, 0x20A, ScrollStep, (m_y << 16) | m_x,, ahk_id %Target2%
	}
	;For all other 'normal' controls either Target1  or Target2 will do the trick. Here we choose Target1 (though Target2 would work just as well), the important thing is to use only one otherwise we'll get double scroll speed.
	Else
	{
		SendMessage, 0x20A, ScrollStep, (m_y << 16) | m_x,, ahk_id %Target1%
	}
}


rbutton::
	mWheelUsed:=0
	MouseGetPos, iStartPos_X, iStartPos_Y, widStartPos_Window
	gst:=Mouse_Gesture()
	MouseGetPos, iEndPos_X, iEndPos_Y, hEndPos_Window

	WinGet szStartPos_WindowProcessName, ProcessName, ahk_id %widStartPos_Window%
	; tooltip, szStartPos_WindowProcessName: %szStartPos_WindowProcessName%
	WinGetPos, iStartPos_WindowPosX, iStartPos_WindowPosY, iStarPos_WindowWidth, iStarPos_WindowHeight, ahk_id %widStartPos_Window%

	fireFoxAdressBarPosX:=iStartPos_WindowPosX+(iStarPos_WindowWidth/2)
	fireFoxAdressBarPosY:=iStartPos_WindowPosY+53 ; Adressbar is in second row in firefox menus
	;fireFoxAdressBarPosY:=iStartPos_WindowPosY+23 ; Adressbar is in first row in firefox menu

	chromeAdressBarPosX:=iStartPos_WindowPosX+(iStarPos_WindowWidth/2)
	chromeAdressBarPosY:=iStartPos_WindowPosY+55 ; Adressbar is in second row in firefox menus

	if (gst="dr")
	{
		if (szStartPos_WindowProcessName="firefox.exe") 
		{
			MouseClick,, fireFoxAdressBarPosX, fireFoxAdressBarPosY
			Send, ^w
			MouseMove, iEndPos_X, iEndPos_Y
		}
		else if (szStartPos_WindowProcessName="sublime_text.exe") {
			Send, ^w
		}
		else if (szStartPos_WindowProcessName="chrome.exe") 
		{
			MouseClick,, chromeAdressBarPosX, chromeAdressBarPosY
			Send, ^w
			MouseMove, iEndPos_X, iEndPos_Y
		}
		else {
			WinClose, ahk_id %widStartPos_Window%
		}
	}
	else if (gst="dl")
	{
		if (szStartPos_WindowProcessName="firefox.exe") 
		{

			MouseClick,, fireFoxAdressBarPosX, fireFoxAdressBarPosY
			Send, {F6}
			Send, ^+t
			MouseMove, iEndPos_X, iEndPos_Y
		}
		else if (szStartPos_WindowProcessName="chrome.exe") 
		{

			MouseClick,, chromeAdressBarPosX, chromeAdressBarPosY
			Send, {F6}
			Send, ^+t
			MouseMove, iEndPos_X, iEndPos_Y
		}
		else if (szStartPos_WindowProcessName="sublime_text.exe") {
			Send, ^+t
		}
	}
	else if (gst="ur")
	{
		if (szStartPos_WindowProcessName="firefox.exe") 
		{
			MouseClick,, fireFoxAdressBarPosX, fireFoxAdressBarPosY
			Send, {F6}
			Send, ^{TAB}
			MouseMove, iEndPos_X, iEndPos_Y
		}
		else if (szStartPos_WindowProcessName="sublime_text.exe") {
			Send, ^{TAB}
		}
	}
	else if (gst="ul")
	{
		if (szStartPos_WindowProcessName="firefox.exe") 
		{
			MouseClick,, fireFoxAdressBarPosX, fireFoxAdressBarPosY
			Send, {F6}
			Send, ^+{TAB}
			MouseMove, iEndPos_X, iEndPos_Y
		}
		else if (szStartPos_WindowProcessName="sublime_text.exe") {
			Send, ^+{TAB}
		}
	}
	else if (gst="ru")
	{
		if (szStartPos_WindowProcessName="firefox.exe") 
		{
			MouseClick,, fireFoxAdressBarPosX, fireFoxAdressBarPosY
			Send, !{ENTER}
			MouseMove, iEndPos_X, iEndPos_Y
		}
	}
	else if (gst="du")
	{
		if (szStartPos_WindowProcessName="firefox.exe") 
		{
			MouseClick,, fireFoxAdressBarPosX, fireFoxAdressBarPosY
			Send, ^r
			Send, {F6}
			MouseMove, iEndPos_X, iEndPos_Y
		}
	}
	else if (gst)
	{
		traytip,Mouse_Gesture returns:,% gst
	}
return

Mouse_Gesture(Button="",dt=50,dv=0.140,ds=5,TabTime=100,SendButton=1,MinAvgSpeed=23,MinDistance=20)
{
	global mWheelUsed
	static u:=[0,0], tf:={"u":[-1,2,1],"d":[1,2,1],"l":[-1,1,2],"r":[1,1,2]}
	mousegetpos,x0,y0
	; tooltip, mousE: %x0%x %y0%y
	cnt:=0
	gesture:=""
	dx0:=x0
	dy0:=y0
	distance:=0
	MinDistance:=MinDistance*MinDistance
	speed:=0
	MinAvgSpeed:=MinAvgSpeed*MinAvgSpeed
	sl:=ceil(ds/(dv*dt))
	x00:=x0
	y00:=y0
	Button:=Button="" ? regexreplace(a_thishotkey,"\W") : Button
	
	while (GetKeyState(Button,"P"))
	{
		sleep,% dt
		if (mWheelUsed!=0) {
			return, 0
		}
		cnt++
		mousegetpos,x1,y1
		distance:=distance+abs(((x1-x0)**2)-((y1-y0)**2))
		speed:=speed+abs((x1-x0)**2-(y1-y0)**2)
		; tooltip, speed: %speed%
		u.1:=x1-x0, u.2:=y1-y0, x0:=x1, y0:=y1
		if (u.1**2+u.2**2>(dv*dt)**2)
		{
			for sct, p in tf
			{
				if (mWheelUsed!=0) {
					return, 0
				}
				if (p.1*u[p.2]>abs(u[p.3]))
				{
					gesture.=sct
					break
				}
			}
		}
	}

	if (mWheelUsed!=0) {
		return, 0
	}

	if (SendButton && cnt && distance<=MinDistance)
	{
		; tooltip, aborted distance: %distance% MinDistance: %MinDistance%
		;ToolTipTime("Mouse_Gesture: MinDistance not reached,MinDistance")
		send,% "{" Button "}"
		return, 0
	}

	avgSpeed:=speed/cnt
	; ToolTip, avgSpeed: %avgSpeed%
	if (SendButton && cnt && avgSpeed<=MinAvgSpeed)
	{
		; tooltip, aborted speed: %speed% MinAvgSpeed: %MinAvgSpeed%
		; traytip,Mouse_Gesture: MinAvgSpeed not reached,avgSpeed/min: %avgSpeed%/%MinAvgSpeed%
		send,% "{" Button "}"
		return, 0
	}

	
	if (SendButton && cnt && cnt*dt<=TabTime)
	{
		send,% "{" Button "}"
		return, 0
	}
		
	; mousemove,x00,y00,1
	return regexreplace(regexreplace(regexreplace(regexreplace(gesture, "(u{" sl ",}|d{" sl ",}|l{" sl ",}|r{" sl ",})","$T1"),"u|d|l|r"),"i)(u+|d+|l+|r+)","$T1"),"u|d|l|r")
}

IsWindowValid(winID) {
	global szIgnoreProcesses
	global szAllowProcesses

	WinGet, processName, ProcessName, ahk_id %winID%

	; white list
	whiteNeedle:=% "(" szAllowProcesses ")"
	if (RegExMatch(processName, whiteNeedle)>0){
		return true
	}

	; fullscreen check
	if (IsWindowFullScreen(winID)) {
		; ToolTipTime("not valid window (%processName%) (fullscreen)")
		return false
	}

	; black list
	blackNeedle:=% "(" szIgnoreProcesses ")"
	;msgbox, blackNeedle: %blackNeedle%
	if (RegExMatch(processName, blackNeedle)>0){
		; ToolTipTime("not valid window (%processName%) (blacklist)")
		return false
	}
	return true
}

IsWindowFullScreen(winID) {
	;checks if the specified window is full screen

	WinGet style, Style, ahk_id %WinID%
	WinGetPos,,,winW,winH, ahk_id %WinID%
	; 0x800000 is WS_BORDER.
	; 0x20000000 is WS_MINIMIZE.
	; no border and not minimized
	Return ((style & 0x20800000) or winH < A_ScreenHeight or winW < A_ScreenWidth) ? false : true
}

ToolTipTime(Text, Time=2500) {
	MouseGetPos, x, y
	ToolTip, %Text%, x, y-20
	SetTimer, RemoveToolTip, %Time%
}

RemoveToolTip:
	SetTimer, RemoveToolTip, Off
	ToolTip
return


Exit_CustomMouseGestures(ExitReason, ExitCode) {

	SaveSettings()

	return 0 ; OnExit functions must return non-zero to prevent exit. In this case 0 to simly exit.
}

LoadSettings() {

	global szIgnoreProcesses, szAllowProcesses, szSettingsPath

	IniRead, szIgnoreProcesses, %szSettingsPath%, Settings, IgnoreProcesses, KSP.exe|mstsc.exe
	IniRead, szAllowProcesses, %szSettingsPath%, Settings, AllowProcesses, explorer.exe|firefox.exe
}

SaveSettings() {

	global szIgnoreProcesses, szAllowProcesses, szSettingsPath

	IniWrite, %szIgnoreProcesses%, %szSettingsPath%, Settings, IgnoreProcesses
	IniWrite, %szAllowProcesses%, %szSettingsPath%, Settings, AllowProcesses
}