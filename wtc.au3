#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author: @glyph
 Version 0.3

 Version 0.4 Goals:
 Input goes directly to shells
 try sticking to one console host window and restarting proceses, ming too if needed
 clear the copy buffer every time and make sure there is something there before writing the next Time


 Script Function:
     Opens WTC miner, starts mining, logs, and closes on a variable loop.
     Press and Hold Scroll Lock for ~3s and release to quit and log.

MIT LICENSE
Copyleft 2018 glyphx, all unicorns reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"),to deal in the
Software without restriction, including without limitationthe rights to use,
copy, modify, merge, publish, distribute, sublicense,and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULARPURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#ce ----------------------------------------------------------------------------\
;Assumptions: 
;Your directory structure looks like structure of C:\Walton-GPU-64, C:\Walton-GPU-64-2, C:\Walton-GPU-64-3, etc.
;Your .bat file includes --mine (should eliminate this need and construct the command ourselves instead of relying on .bat files)
#include <Array.au3>
#include <AutoItConstants.au3>
#include <Clipboard.au3>
#include <Date.au3>
#include <FileConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>
#include <_SingleScript.au3>

_SingleScript() ;prevents more than one instance from running.

Global Const $LOOP_SIZE_IN_MIN = 60                 ;change the time of the main loop here.
Global Const $ROOT_PATH = "C:\Walton-GPU-64"        ;installation folders root path
Global Const $NUM_GPUS = 2                          ;set the number of gpu's
Global Const $first_run = 
Global $gpu_path = ''
Global $log_path = $ROOT_PATH & $gpu_path & "\log.txt"
Global $ming_path = $ROOT_PATH & $gpu_path & "\ming_run.exe"
Global $consoleHostRunCmd = @COMSPEC & '/K "cd ' & $ROOT_PATH & $gpu_path & '\"'
Global $hFileOpen = FileOpen($log_path, $FO_APPEND)
Global $pressed = 0
Global $hTimer = 0
Global $consoleHostPID = 0


If $hFileOpen = -1 Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file, make sure install path matches the configuration. Make sure you're able to open a new file @ " & $ROOT_PATH & ".")
     Return False
EndIf
FileClose($hFileOpen)

;protip if time matters to you, the less processes you have running, the less time this takes.
;Function for getting HWND from PID
Func _GetHwndFromPID($PID)
     $hWnd = 0
     $winlist = WinList()
     Do
          For $i = 1 To $winlist[0][0]
               If $winlist[$i][0] <> "" Then
                    $iPID2 = WinGetProcess($winlist[$i][1])
                    If $iPID2 = $PID Then
                         $hWnd = $winlist[$i][1]
                         ExitLoop
                    EndIf
               EndIf
          Next
     Until $hWnd <> 0
     Return $hWnd
 EndFunc;==>_GetHwndFromPID

 Func _Au3Int_Clr()
    Local $hConsole, $aRet

    $aRet = DllCall("kernel32.dll", "hwnd", "GetStdHandle", "dword", -11)
    If @error Or (Not IsArray($aRet)) Or ($aRet[0] = -1) Then Return SetError(1, 0, False)
    $hConsole = $aRet[0]

    Local $tScreenBufferInfo = DllStructCreate("short X; short Y; short; short; short; short; short; short; short; short; short")

    $aRet = DllCall("kernel32.dll", "bool", "GetConsoleScreenBufferInfo", "hwnd", $hConsole, "ptr", DllStructGetPtr($tScreenBufferInfo))
    If @error Or (Not IsArray($aRet)) Or (Not $aRet[0]) Then Return SetError(2, 0, False)

    $aRet = DllCall("kernel32.dll", "int", "FillConsoleOutputCharacterW", _
            "handle", $hConsole, _
            "byte", 0x20, _
            "dword", DllStructGetData($tScreenBufferInfo, "X") * DllStructGetData($tScreenBufferInfo, "Y"), _
            "dword", 0, _
            "dword*", 0)
    If @error Or (Not IsArray($aRet)) Or (Not $aRet[0]) Then Return SetError(3, 0, False)

    $aRet = DllCall("kernel32.dll", "int", "SetConsoleCursorPosition", "hwnd", $hConsole, "dword", 0)
    If @error Or (Not IsArray($aRet)) Or (Not $aRet[0]) Then Return SetError(4, 0, False)

    Return True
EndFunc   ;==>_Au3Int_Clr

;pure jank, uses alt+space -> e -> s to copy buffer. Replace with nonjank, thx. -self
Func bufferToClip()
    $count = 0
    While $count < 50
        $count = $count + 1
        WinActivate($consoleHostHwnd)
        If WinActive($consoleHostHwnd) <> 0 Then
              Send("!{SPACE}")
             If WinActive($consoleHostHwnd) <> 0 Then
                  Send("e")
                   If WinActive($consoleHostHwnd) <> 0 Then
                         Send("s")
                         Send("{ENTER}")
                         ExitLoop(1)
                    Else
                    Sleep(150)
               EndIf
          Else
              Sleep(150)
          EndIf
     Else
          Sleep(150)
     EndIf
    WEnd
EndFunc

; append clipboard contents and date to log file
Func writeToFile()
     $hFileOpen = FileOpen($log_path, $FO_APPEND)
     FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
     FileWrite($hFileOpen, _ClipBoard_GetData() & @CRLF)
     FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
     FileClose($hfileOpen)
EndFunc
;kill processes associated on a range of ports
Func killProcessesOnPorts()
EndFunc
;rewrite to accept array of pids as input to kill -- or associated ports
; close all the processes the script opened not including itself
Func closeProcesses() ;rewrite to be more generic so it can be started before main execution of script to ensure clear execution
     ProcessClose("walton.exe");needs to be fixed 
     Sleep(100)
     ProcessClose($consoleHostPID)
     Sleep(100)
     $count = 3
     while ProcessExists($mingPID) & $count > 0
          $count = $count - 1
          sleep(1000)
          WinKill($mingPID)
     WEnd
     Sleep(100)
EndFunc

; This function runs most of the time the script is active,
; waiting to capture scroll lock, log, and quit.
Func timedEscape()
     $pressed = 0
     $hTimer = TimerInit()
     While (TimerDiff($hTimer) < ($LOOP_SIZE_IN_MIN * 60000))
          If _IsPressed("91") Then ;is scroll lock pressed
               If Not $pressed Then
                    ToolTip("Scroll Lock Behind Held Down, Shutting Down")
                    $pressed = 1
                    bufferToClip()
                    writeToFile()
                    closeProcesses()
                    Exit(0)
               EndIf
          Else
               If $pressed Then
                    ToolTip("")
                    $pressed = 0
               EndIf
          EndIf
     Sleep(250)
     WEnd
EndFunc

Func runCmds(); write arrray to contain pid, handle, and also title if necessary

     $mingPID = Run($ming_path)
     Sleep(750)
     $consoleHostPID = Run($consoleHostRunCmd)
     sleep(750)
     $mingHwnd = _GetHwndFromPID($mingPID)
     $consoleHostHwnd = _GetHwndFromPID($consoleHostPID)
EndFunc ;==>_runCmds() Returns array(s) containing pid/handles of run cmds

;main(), runs commands, in turn getting PID's and translating them to window handles.

;replace this below section with constructed command - test in isolation
While 1   
     $count = 0
     While $count < 15
          $count = $count + 1
          Sleep(750)
          WinActivate($consoleHostHwnd)
          If WinActive($consoleHostHwnd) <> 0 Then
               Send("start_gpu.bat")
               Send("{ENTER}")
               Sleep(100)
               If Winactive($consoleHostHwnd) <> 0 Then
                    ExitLoop(1)
               EndIf
          EndIf
     Wend

   timedEscape() ;listen for escape key, if pressed run bufferToClip, writeToFile, and closeProcesses

   bufferToclip()  ; Restart and log if escape key was pressed

   writeToFile() ; writes clipboard to logfile

   closeProcesses() ; close all processes started by script
WEnd
