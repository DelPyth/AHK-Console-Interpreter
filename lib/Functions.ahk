Update(ConsoleInfo, UserInput, TimeStamp) {
	GuiControl, Con:, ConsoleInfo, % ConsoleInfo "`n"
	GuiControl, Con:, UserInput, % ""
	; Set selection at end
	; EM_SETSEL = 0xB1
	PostMessage 0xB1, -2, -1, Edit1, A
	; Show the caret position
	; EM_SCROLLCARET = 0xB7
	PostMessage 0xB7,,, Edit1, A
	Return
}

LogIn(ConsoleInfo, UserInput) {
	Global
	ConsoleInfo .= "Enter your login information like this:`nEmail`nPassword`n`nDo not worry, AHK Console will block all inputs"
	Update(ConsoleInfo, UserInput, TimeStamp)
	IniLoc					:=		A_Temp "\Console\Settings_Discord.ini"
	EM_SETCUEBANNER			:=		0x1501  ; ECM_FIRST+1
	CueBannerTextEdit1		:=		"Enter Your Email."
	CueBannerTextEdit2		:=		"Enter Your Password."
	If !FileExist(IniLoc) {
		IniWrite, 0, %IniLoc%, Settings, Remember
		IniWrite, % "", %IniLoc%, AutoComp, email
		IniWrite, % "", %IniLoc%, AutoComp, password
	}
	IniRead, UserNAME, %IniLoc%, AutoComp, email
	IniRead, PassWORD, %IniLoc%, AutoComp, password
	IniRead, Checked, %IniLoc%, Settings, Remember
	If (Checked = 1) {
		email := UserNAME
		password := PassWORD
	}Else {
		email		:=		""
		password	:=		""
	}
	Gui, Log:New, -DPIScale -MinimizeBox
	Gui, Log:Font, s7
	Gui, Log:Add, Edit, w205 hwndEdit1 vEmail, % email
	Gui, Log:Add, Edit, w205 hwndEdit2 vPassWord Password, % password
	SendMessage, EM_SETCUEBANNER, ShowWhenFocused := True, &CueBannerTextEdit1,, ahk_id %Edit1%
	SendMessage, EM_SETCUEBANNER, ShowWhenFocused := True, &CueBannerTextEdit2,, ahk_id %Edit2%
	Gui, Log:Add, Checkbox, w200 y+8 vRemember, Remember Me
	Gui, Log:Add, Button, x10 y+10 w75 h23 vButton1 gLogIN, Log In
	Gui, Log:Add, Link, x100 y80 w120 vLink1, Don't have an account? <a href="https://discordapp.com/register">Sign Up!</a>
	Gui, Log:Show, w220, Log In To Discord
	GuiControl, Log:, Remember, %Checked%
	Return

	LogIN:
	Gui, Log:Submit
	If (Remember = 1) {
		IniWrite, 1, %IniLoc%, Settings, Remember
		IniWrite, %Email%, %IniLoc%, AutoComp, email
		IniWrite, %PassWord%, %IniLoc%, AutoComp, password
	} Else {
		IniWrite, 0, %IniLoc%, Settings, Remember
		IniWrite, %Email%, %IniLoc%, AutoComp, email
		IniWrite, %PassWord%, %IniLoc%, AutoComp, password
	}
	/*
	WB := ComObjCreate("InternetExplorer.Application")
	WB.Visible := False
	WB.Navigate("https://discordapp.com/login")
	While WB.readyState != 4 || WB.document.readyState != "complete" || WB.busy
		Sleep, 10
	WB.document.getElementById("register-email").value := Email
	WB.document.getElementById("register-password").value := PassWord
	While (value <> "Login")
		value := WB.document.getElementsByTagName("btn btn-primary")[A_Index - 1].value, index := A_Index
	WB.document.getElementsByClassName("btn btn-primary")[index].click()
	While WB.readyState != 4 || WB.document.readyState != "complete" || WB.busy
		Sleep, 10
	Msgbox, Now logged in and loaded!
	*/
	1GuiEscape:
	1GuiClose:
	Exit:
	Gui, Log:Destroy
	Return
}

ChannelMsg(ConsoleInfo, UserInput, TimeStamp) {
	Global
	ConsoleInfo := "Enter the channel you'd like to go to."
	Update(ConsoleInfo, UserInput, TimeStamp)
}

Execute(UserInput) {
	StringTrimLeft, Command, UserInput, 5
	Return Command
}

HelpMSG() {
	Global
	HelpMessage				:=
	(
	"
	===================================================================================================================
	Need Help?
	Here's a list of commands:
		- " Pref "admin
		- " Pref "clear
		- " Pref "run		[Command]
			+ Use ahk's format of variables.
				= Said Variables are:
					%A_Desktop%		- Defines the Current User's Desktop
					%A_WorkingDir%		- Defines the Current Directory
					%A_Temp%		- Defines the System's Temp folder
					%A_UserName%		- Defines the Current User's Name.
	
		- " Pref "exit		[Exit Code]
		- " Pref "help
		- " Pref "login
		- " Pref "prefix	[Prefix]
			+ The prefix you want to use. This will not be saved for next session.
			+ Do """ Pref "prefix reset"" to reset the prefix back to the default ""/""
		- /remPref
			+ This Tells you the current prefix for commands. 
			+ This command uses the ""/"" key no matter what prefix is set.
	==================================================================================================================="
	)
Return
}

Open(User, TimeStamp) {
	Return "<[" User "] " TimeStamp ":> "
}

Exit() {
	ExitApp
}
