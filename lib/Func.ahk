ExecScript(Script, Wait := True) {
	Global Settings
	Shell := ComObjCreate("WScript.Shell")

	; If "script" is blank ::
	If (!Script)
		Return, False

	; Else ::
	If (!A_IsCompiled)
		Exec := Shell.Exec(A_AhkPath " /ErrorStdOut *")
	Else
		Exec := Shell.Exec(Settings.ExePath " /ErrorStdOut *")

	Exec.StdIn.Write(Script)
	Exec.StdIn.Close()
	If (Wait)
		Return, Exec.StdOut.ReadAll()
}

DisplayHelp(Con) {
	Con.WriteLine("")
	Return, Con.Write(
	(LTrim
		"- Not case sensitive

		<Available commands>
		Con.Exit()
		`tClose the console.
		Con.Set()
		`tChange some settings for this program.
		Con.Log({Expression/Text})
		`tPrint some information to the console.
		Con.Clear()
		`tClear the console.
		Con.Help()
		`tDisplay this message.

		<In Development>
		AHK.Forum({SubForum})
		`tGo to the AHK forums.
		AHK.Help({Type})
		`tOpen the AHK docs online or from the help file. Defaults to the online docs.
		AHK.CheckUpdate()
		`tCheck for an update, and if there is one, ask to install it.`n`n"
	))
}

; Minor but it helps in a lot of cases.
TrueFalse(Var, T, F := "") {
	Return, Var ? T : F
}

SplitPath(File) {
	SplitPath, File, FileName, Dir, Extension, NameNoExt, Drive
	Return, {FileName: FileName, Dir: Dir, Ext: Ext, NameNoExt: NameNoExt, Drive: Drive}
}

FileSelectFile(Filter := "", Options := "", Prompt := "", Root := "") {
	FileSelectFile, Out, % Options, % Root, % Prompt, % Filter
	Return, Out
}

OnMsgBox() {
    DetectHiddenWindows, On
    Process, Exist
    If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
        ControlSetText Button1, &Continue
        ControlSetText Button2, C&ancel
        ControlSetText Button3, &Run 32bit
    }
}
