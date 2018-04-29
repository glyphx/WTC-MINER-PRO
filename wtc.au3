#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author: @glyph
 Version 0.3

 Version 0.4 Goals:
 Input goes directly to shells
 Remove all ambiguity from windows like cmd.Exe
 code check for Windows / WINDOWS problem
 try shell execute, track all pids, convert to handle if needed.
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

#ce ----------------------------------------------------------------------------

#include <AutoItConstants.au3>
#include <Date.au3>
#include <Clipboard.au3>
#include <FileConstants.au3>
#include <WinAPIFiles.au3>
#include <MsgBoxConstants.au3>
#include <_SingleScript.au3>
#include <Misc.au3>
#include <Array.au3>

_SingleScript() ;prevents more than one instance from running.

Global Const $LOOP_SIZE_IN_MIN = 60 ;change the time of the main loop here.
Global Const $LOG_PATH = "C:\Walton-GPU-64\log.txt"
Global Const $ROOT_PATH = "C:\Walton-GPU-64"
Global Const $MING_PATH = "C:\Walton-GPU-64\GPUMing_v0.2\ming_run.exe"
Global Const $CONSOLE_HOST_RUN_CMD = 'cmd /K "cd C:\Walton-GPU-64\"'
Global Const $START_GPU_BAT_TITLE = "C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat"
Global Const $CONSOLE_HOST_TITLE = "C:\WINDOWS\SYSTEM32\cmd.exe"
;rewrite so these constants aren't necessary, but derived from opened processes.


Global $hFileOpen = FileOpen($LOG_PATH, $FO_APPEND)
Global $pressed = 0
Global $hTimer = 0
Global $consoleHost = 0

If $hFileOpen = -1 Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file, make sure install path matches. Make sure you're able to open a new file @ " & $ROOT_PATH & ".")
   Return False
   EndIf
FileClose($hFileOpen)

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

;pure jank, uses alt+space -> e -> s to copy buffer.
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
   $hFileOpen = FileOpen($LOG_PATH, $FO_APPEND)
   FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
   FileWrite($hFileOpen, _ClipBoard_GetData() & @CRLF)
   FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
   FileClose($hfileOpen)
EndFunc

; close all the processes the script opened not including itself
Func closeProcesses() ;rewrite to be more generic so it can be started before main execution of script to ensure clear execution
   ProcessClose("walton.exe")
   Sleep(100)
   ProcessClose($consoleHost)
   Sleep(100)
   $count = 3
   while ProcessExists($ming) & $count > 0
	  $count = $count - 1
	  sleep(100)
	  Processclose($ming)
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

While 1
   $ming = Run($MING_PATH)
   Sleep(750)

   $consoleHost = Run($CONSOLE_HOST_RUN_CMD)
   sleep(750)
   $mingHwnd = _GetHwndFromPID($ming)
   $consoleHostHwnd = _GetHwndFromPID($consoleHost)
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

   $count = 0
   While $count < 15
	    sleep(100)
	    $count = $count + 1
	    WinActivate($consoleHostHwnd)
	    If Winactive($consoleHostHwnd) <> 0 Then
		    Send("miner.start()")
		    Send("{ENTER}")
		    ExitLoop(1)
	    EndIf
	WEnd

   timedEscape() ;listen for escape key, if pressed run bufferToClip, writeToFile, and closeProcesses

   bufferToclip()  ; Restart and log if escape key was pressed

   writeToFile() ; writes clipboard to logfile

   closeProcesses() ; close all processes started by script
WEnd
