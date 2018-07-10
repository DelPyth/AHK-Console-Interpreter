/*
	Name:			AHK Console Interpreter
	AHK Version:	1.1.28.2 [Tested on]
	Author:			Delta
	Description:	This is the interpreter for AHK in a whole new way.

	Limitations:	Can run in U32 as of 7/6/2018.
					Able to run U64 but can have possible memory leaks and/or other issues.

	Changelog:
		v1.0.0 - First initial release.
*/

#NoEnv
#SingleInstance, Force
#KeyHistory, 0
#MaxThreadsPerHotkey, 1
#Persistent
#NoTrayIcon
SendMode, Input
SetBatchLines, -1
SetWinDelay, -1
SetMouseDelay, -1
SetKeyDelay, -1, -1
SetTitleMatchMode, 2
DetectHiddenWindows, On
SetWorkingDir, % A_ScriptDir

/*
	====================================================================
	Base functions for later
	NOTE:
		DO NOT EDIT
	====================================================================
*/
"".Base.TF := Func("TrueFalse")

/*
	====================================================================
	Read for settings or create the settings.
	====================================================================
*/
If (FileExist(A_ScriptDir "\settings.json")) {
	Settings := JSON.LoadFile(A_ScriptDir "\settings.json")
	Settings.ExePath := Settings.ExecPath.TF(Settings.ExecPath, Settings.ExecPath, A_AhkPath) ; If var is not blank, then set it to be the AHKpath.
} Else {
	Settings := {}
	If (A_IsCompiled) {
		If (A_AhkPath != "")
			Settings.ExePath := A_AhkPath "\..\AutoHotkeyU32.exe" ; Use the AHK 32bit path
		Else
			Settings.ExePath := FileSelectFile("AutoHotkey Directives (*.exe)", 3, "Select an AutoHotkey Directive")
	} Else
		Settings.ExePath := A_AhkPath "\..\AutoHotkeyU32.exe" ; Use the AHK 32bit path
	Settings.Ignore := False
	FileOpen(A_ScriptDir "\settings.json", "w").Write(JSON.Dump(Settings,, A_Tab)) ; Write to file.
}

/*
	====================================================================
	If running in a 64 bit environment,
	then ask the user to continue (with caution), cancel (and close the console), or switch to 32 bit environment
	====================================================================
*/
If (A_PtrSize != 4) && (!(Settings.Ignore)) {
	OnMessage(0x44, "OnMsgBox")
	MsgBox, 0x42033, Warning!,
	(Ltrim
		Using this program in 64 bit has been known to have memory leaks and other issues.
		It is recommended that you restart this program using the 32 bit executable.
		Are you sure you'd like to continue using the 64 bit executable?
	)
	OnMessage(0x44, "")

	IfMsgBox, Yes, {
		Settings.Ignore := True
		FileOpen(A_ScriptDir "\settings.json", "w").Write(JSON.Dump(Settings,, A_Tab)) ; Write to file
	} Else IfMsgBox No, {
		ExitApp
	} Else IfMsgBox Cancel, {
		If (FileExist(A_AhkPath "\..\AutoHotkeyU32.exe")) {
			For Each, Item in A_Args
				Items .= A_Args[Each - 1] A_Space
			Run, % """" A_AhkPath "\..\AutoHotkeyU32.exe"" """ A_ScriptFullPath """ " . A_Space . Items
			ExitApp
		}
	}
}

/*
	====================================================================
	Continue on and start the console!
	====================================================================
*/

Con := New Console(, A_ScriptName " - AutoHotkey" (A_PtrSize = 4 ? "32" : "64") ".exe") ; Check bit environment and set settings accordingly.
Con.WriteLine("AutoHotkey [Version: {1}]", A_AhkVersion)
Con.WriteLine("(c) 2003-2014 Chris Mallett, portions (c)AutoIt Team and the AHK community. All rights reserved.")
Con.WriteLine("")
Loop
{
	Con.Write("] ")
	Text := Con.ReadLine()
	If (Text == "") ; If blank, then redo the loop until it's not.
		Continue

	If (Text ~= "i)^Con\.Exit\(\)$") {														; Con.Exit()
		ExitApp
	} Else If (Text ~= "i)^Con\.Set\(") {													; Con.Set()
		Text := RegExReplace(RegExReplace(Text, "i)^Con\.Set\("), "\)$")
		Settings_Arr := StrSplit(Text, ",")
		For Each, Item in Settings_Arr {
			If (Settings_Arr[1] = "ExePath")
				Settings.ExePath := Settings_Arr[2]
			Else If (Settings_Arr[1] = "Ignore")
				Settings.Ignore := Settings_Arr[2]
		}
		FileOpen(A_ScriptDir "\settings.json", "w").Write(JSON.Dump(Settings,, A_Tab))
	} Else If (Text ~= "i)^Con\.Log\(") {													; Con.Log()
		Text := RegExReplace(RegExReplace(Text, "i)^Con\.Log\("), "\)$")
		Con.WriteLine(ExecScript("FileAppend, % (" Text "), *"))
	} Else If (Text ~= "i)^Con\.Clear\(\)$") {												; Con.Clear()
		Con.ClearScreen()
	} Else If (Text ~= "i)^Con\.Help\(\)$") {												; Con.Help()
		DisplayHelp(Con)
	} Else {																				; Exec Script ::
		Out := ExecScript(Text)
		If (Out) ; Output anything to the console that can be returned.
			Con.WriteLine(Out)
	}
}
Return

/*
	====================================================================
	Includes
	====================================================================
*/
#Include, <Console>
#Include, <JSON>
#Include, <Func>
