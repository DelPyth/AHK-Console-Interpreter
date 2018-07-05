#NoEnv
#SingleInstance, Force
#KeyHistory, 0
#MaxThreadsPerHotkey, 1
#Persistent
#NoTrayIcon
ListLines, Off
SendMode, Input
SetBatchLines, -1
SetWinDelay, -1
SetMouseDelay, -1
SetKeyDelay, -1, -1
SetTitleMatchMode, 2
DetectHiddenWindows, On
SetWorkingDir, % A_ScriptDir


Con := New Console(, A_ScriptName " - AutoHotkey" (A_PtrSize = 4 ? "32" : "64") ".exe")
; Con.SetConsoleIcon(A_AhkPath)
Con.WriteLine("AutoHotkey [Version: {1}]", A_AhkVersion)
Con.WriteLine("(c) 2003-2014 Chris Mallett, portions (c)AutoIt Team and the AHK community. All rights reserved.")
Con.WriteLine("")
Loop
{
	Con.Write("] ")
	Text := Con.ReadLine()

	If (Text ~= "i)Con.Exit\(\)") {
		Break
	} Else If (Text ~= "i)Con.Log\(") {
		Text := RegExReplace(RegExReplace(Text, "i)Con.Log\("), "\)$")
		Con.WriteLine(ExecScript("FileAppend, % (" Text "), *"))
		Continue
	} Else If (Text ~= "i)Con.Clear\(\)") {
		Con.ClearScreen()
		Continue
	} Else If (Text ~= "i)Help\(\)") {
		DisplayHelp(Con)
		Continue
	}
	ExecScript(Text)
}
ExitApp

ExecScript(Script, Wait := True) {
	Static Shell := ComObjCreate("WScript.Shell")
	Exec := Shell.Exec(A_AhkPath " /ErrorStdOut *")
	Exec.StdIn.Write(Script)
	Exec.StdIn.Close()
	If (Wait)
		Return, Exec.StdOut.ReadAll()
}

DisplayHelp(Con) {
	Con.WriteLine()
	Text :=
	(Ltrim
		"`nCon.Exit()
		`tClose the console.
		Con.Log({Text})
		`tPrint some text to the console.
		Con.Clear()
		`tClear the console.
		Help()
		`tDisplay this message."
	)
	Return, Con.Write(Text "`n`n")
}

#Include, <Console>
