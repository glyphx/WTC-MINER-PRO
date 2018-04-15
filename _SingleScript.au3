#include-once

;==============================================================================================================
; UDF Name:         _SingleScript.au3
; Description:      iMode=0  Close all executing scripts with the same name and continue.
;                   iMode=1  Wait for completion of predecessor scripts with the same name.
;                   iMode=2  Exit if other scripts with the same name are executing.
;                   iMode=3  Test, if other scripts with the same name are executing.
;
; Syntax:           _SingleScript([iMode=0])
;                   Default:  iMode=0
; Parameter(s):     iMode:     0/1/2/3    see above

; Requirement(s):   none

; Return Value(s): -1= error      @error=-1   invalid iMode

;                   0= no other script executing @error=0 @extended=0
;                   1= other script executing @error=0 @extended=1 (only iMode=3)
; Example:
;               #include <_SingleScript.au3>
;               _SingleScript() ; Close mode ( iMode defaults to 0 )
;               MsgBox(Default, Default, "No other script with name " & StringTrimRight(@ScriptName, 4) & " is executing.", 0)
;               ; see other example at end of this UDF
;
; Author:       Exit   ( http://www.autoitscript.com/forum/user/45639-exit )
; COPYLEFT:     © 2013 Freeware by "Exit"
;               ALL WRONGS RESERVED
;==============================================================================================================

Func _SingleScript($iMode = 0)
    Local $oWMI, $oProcess, $oProcesses, $aHandle, $aError, $sMutexName = "_SingleScript " & StringTrimRight(@ScriptName, 4)
    If $iMode < 0 Or $iMode > 3 Then Return SetError(-1, -1, -1)
    If $iMode = 0 Or $iMode = 3 Then ; (iMode = 0) close all other scripts with the same name.  (iMode = 3) check, if others are running.
        $oWMI = ObjGet("winmgmts:\\" & @ComputerName & "\root\CIMV2")
        If @error Then

            RunWait(@ComSpec & ' /c net start winmgmt  ', '', @SW_HIDE)
            RunWait(@ComSpec & ' /c net continue winmgmt  ', '', @SW_HIDE)
            $oWMI = ObjGet("winmgmts:\\" & @ComputerName & "\root\CIMV2")
        EndIf

        $oProcesses = $oWMI.ExecQuery("SELECT * FROM Win32_Process", "WQL", 0x30)
        For $oProcess In $oProcesses

            If $oProcess.ProcessId = @AutoItPID Then ContinueLoop

            If Not ($oProcess.Name = StringTrimRight(@ScriptName, 4) & ".EXE" Or ($oProcess.Name = "AutoIt3.exe" And StringInStr($oProcess.CommandLine, StringTrimRight(@ScriptName, 4) & ".au3"))) Then ContinueLoop

            If $iMode = 3 Then Return SetError(0, 1, 1) ; indicate other script is running. Return value and @extended set to 1.
            If ProcessClose($oProcess.ProcessId) Then ContinueLoop

            MsgBox(262144, "Debug " & @ScriptName, "Error: " & @error & " Extended: " & @extended & @LF & "Processclose error: " & $oProcess.Name & @LF & "******", 0)
        Next
        Sleep(100) ; allow process to terminate

    EndIf



    $aHandle = DllCall("kernel32.dll", "handle", "CreateMutexW", "struct*", 0, "bool", 1, "wstr", $sMutexName) ; try to create Mutex

    $aError = DllCall("kernel32.dll", "dword", "GetLastError") ; retrieve last error

    If Not $aError[0] Then Return SetError(0, 0, 0)
    If $iMode = "2" Then Exit 1
    If $iMode = "0" Then Return SetError(1, 0, 1) ; should not occur

    DllCall("kernel32.dll", "dword", "WaitForSingleObject", "handle", $aHandle[0], "dword", -1) ; infinite wait for lock
    Return SetError(0, 0, 0)
EndFunc   ;==>_SingleScript



#comments-start     Here is the other example. Uncomment and use TIDY to reformat.
    #include <_SingleScript.au3>
    If $cmdline[0] = 0 Then ; submit all scripts

    TraySetToolTip("No Case")
    _SingleScript() ; Kill other scripts, if others are executing

    For $i = 0 To 7
    Sleep(100)
    ShellExecute(@ScriptFullPath, $i)
    Next
    Exit MsgBox(64 + 262144, Default, "All scripts submitted. See icons in system tray. Case 1 already disappeared.", 0)
    EndIf

    TraySetToolTip("Case " & $cmdline[1])
    Switch $cmdline[1]
    Case 0
    $rc = _SingleScript(3) ; Check, if others are executing

    MsgBox(64 + 262144, Default, "Case " & $cmdline[1] & " executing. " & ($rc ? "Some" : "No") & " other scripts executing.", 0)
    Case 1
    _SingleScript(2) ; Kill this scropt, if others are executing

    Beep(440, 3000) ; you will NOT hear the long beep.
    Case 2, 3, 4, 6, 7
    _SingleScript(1) ; Wait for predecessors completed

    MsgBox(64 + 262144, Default, "Case " & $cmdline[1] & " executing.", 0)
    Case 5
    _SingleScript(1) ; Wait for predecessors completed (case 1-4)
    MsgBox(64 + 262144, Default, "Case " & $cmdline[1] & " executing." & @CRLF & "Now killing other scripts. See icons in system tray.", 0)
    _SingleScript() ; Now kill other scripts. Should be case 6 and 7
    _SingleScript(3) ; Check, if others are executing

    MsgBox(64 + 262144, Default, "Case " & $cmdline[1] & " executing. " & (@extended ? "Some" : "No") & " other scripts executing.", 0)
    EndSwitch

#comments-end