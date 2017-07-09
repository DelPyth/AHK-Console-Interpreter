#NoEnv
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
Menu, Tray, Icon, %A_AhkPath%, 2

EM_SETCUEBANNER			:=		0x1501  ; ECM_FIRST + 1
CueBannerTextEdit1		:=		"Enter a command."
ExitCode				:=		54763
User					:=		A_UserName
Pref					:=		"/"
HelpMSG()
StartupMessage			:=
(
"
===================================================================================================================
Discord Console (c) Delta 2017
	Credit for Discord Wrapper that is soon to be added:
		GeekDude
===================================================================================================================
"
)

NewInfo := StartupMessage
Gui, Con:+0x80880000 -MinimizeBox
Gui, Con:Color, 0x000000,  0x000000
Gui, Con:Font, q2, System
Gui, Con:Add, Edit, x0 y0 w950 h505 ReadOnly cFFFFFF vConsoleInfo, %NewInfo%
Gui, Con:Font,, Consolas
Gui, Con:Add, Edit, x10 y515 w860 h25 +Left r1 cFFFFFF hwndEdit1 vUserInput
SendMessage, EM_SETCUEBANNER, ShowWhenFocused := True, &CueBannerTextEdit1,, ahk_id %Edit1%
Gui, Con:Add, Button, x875 y516 w65 h19 gSend, Submit
GuiControl, Con:Focus, UserInput
Gui, Con:Show, w950 h545, AHK Console
Return

ConGuiClose:
GuiClose:
ExitApp

#IfWinActive AHK Console
^BS::Send, ^+{Left}{Del}

Enter::
Send:
Gui, Con:Submit, NoHide
FormatTime, TimeStamp,, hh:mm:ss
If (StrLen(UserInput) > 200) {
	ConsoleInfo .= "`n`nI'm sorry, but anything above 200 characters is not allowed.`nYour amount of characers: " StrLen(UserInput) "`n`n"
	Update(ConsoleInfo, UserInput, TimeStamp)
	Return
}
If (InStr(UserInput, Pref) or InStr(UserInput, "/")) {
	If (InStr(UserInput, Pref "run ")) {
		ConsoleInfo := "Running Command, Please wait...`n"
		Execute(UserInput)
		Update(ConsoleInfo, UserInput, TimeStamp)
		Return
	} Else If (InStr(UserInput, Pref "prefix ")) {
		StringTrimLeft, Pref, UserInput, 8
		LastInput := UserInput
		ConsoleInfo .= "The new command prefix is now: " Pref "`nRemember this or you will regret it."
		Update(ConsoleInfo, UserInput, TimeStamp)
		Return
	} If (UserInput = Pref "help") {
		HelpMSG()
		ConsoleInfo .= HelpMessage
	} Else If (UserInput = Pref "admin") {
		ConsoleInfo .= Open(User, TimeStamp) " " User "Activated Admin Mode!`n"
	} Else If (UserInput = Pref "clear") {
		ConsoleInfo := ""
	} Else If (UserInput = "/remPref") {
		ConsoleInfo .= "The current command prefix is: " Pref "`n"
	} Else If (UserInput = Pref "login") {
		ConsoleInfo .=
		(LTRIM
		"I'm sorry but this is not implimented yet. Nor is the use of discord.
		We're trying out best to work with the Discord Team and others to get this to work.
		Sorry again!
		" A_Tab " - Delta`n"
		)
		; LogIn(ConsoleInfo, UserInput)
		; ChannelMsg(ConsoleInfo, UserInput, TimeStamp)
	} Else If (UserInput = Pref "exit") {
		ConsoleInfo .= "`nPlease specify the exit code...`n"
	} Else If (UserInput = Pref "exit " ExitCode) {
			ConsoleInfo := "Closing Program, Please wait...`n"
			Update(ConsoleInfo, UserInput, TimeStamp)
			Sleep 2500
			ExitApp
	} Else {
		If (InStr(UserInput, "/")) {
			ConsoleInfo .= Open(User, TimeStamp) UserInput
			LastInput := UserInput
			Update(ConsoleInfo, UserInput, TimeStamp)
			Return
		}
		Length := StrLen(Pref)
		StringTrimLeft, Command, UserInput, %Length%
		ConsoleInfo .= "Invalid Command: [ """ Command """ ]`n"
	}
}
ConsoleInfo .= Open(User, TimeStamp) UserInput
LastInput := UserInput
Update(ConsoleInfo, UserInput, TimeStamp)
Return

~Up::
Gui, Con:Submit, NoHide
If (UserInput != "")
	Return
Else {
	GuiControl Con:, UserInput, % LastInput
	SendInput {End}
	Return
}
Return
#IfWinActive
