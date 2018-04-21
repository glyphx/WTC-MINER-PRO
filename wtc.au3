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

Global Const $logFilePath = "C:\Walton-GPU-64\log.txt"
Global $loopSizeInMins = 60 ;change the time of the main loop here.
Global $hFileOpen = FileOpen($logFilePath, $FO_APPEND)
Global $pressed = 0
Global $hTimer = 0
Global $consoleHost = 0
Global $consoleHandle = 0
Global $winTitle = "C:\Walton-GPU-64"

If $hFileOpen = -1 Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file. Make sure you're able to open a new file @ C:\Walton-GPU-64.")
   Return False
   EndIf
FileClose($hFileOpen)

Func clipToFile()
   $count = 0
   While $count < 50
       $count = $count + 1
       WinActivate("start_gpu.bat")
       If WinActive("start_gpu.bat") <> 0 Then
		  Send("!{SPACE}")
	      If WinActive("start_gpu.bat") <> 0 Then
		     Send("e")
			 If WinActive("start_gpu.bat") <> 0 Then
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
   ;chop this function here, split to two functions one for copy, one for quit.
   $hFileOpen = FileOpen($logFilePath, $FO_APPEND)
   FileWrite($hFileOpen, _NowDate() & " " & _nowTime() & @CRLF)
   FileWrite($hFileOpen, _ClipBoard_GetData() & @CRLF)
   FileWrite($hFileOpen, _nowDate() & " " & _nowTime() & @CRLF)
   FileClose($hfileOpen)
   Sleep(2000)
   ProcessClose("walton.exe")
   Sleep(100)
   ProcessClose($consoleHost)
   Sleep(100)
   $count = 3
   while ProcessExists($ming) & $count > 0
	  $count = $count - 1
	  sleep(1000)
	  Processclose($ming)
   WEnd
   Sleep(100)
EndFunc
Func timedEscape()
   $pressed = 0
   $hTimer = TimerInit()
   While (TimerDiff($hTimer) < ($loopSizeInMins * 60000))
	   If _IsPressed("91") Then ;is scroll lock pressed
		   If Not $pressed Then
			   ToolTip("Scroll Lock Behind Held Down, Shutting Down")
			   $pressed = 1
			   clipToFile()
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

; Returns an array of all Windows associated with a given process
Func WinHandFromPID($pid, $winTitle = "", $timeout = 8)
    Local $secs = TimerInit()
    Do
        $wins = WinList($winTitle)
        For $i = UBound($wins) - 1 To 1 Step -1
            If (WinGetProcess($wins[$i][1]) <> $pid) Or (BitAND(WinGetState($wins[$i][1]), 2) = 0) Then _ArrayDelete($wins, $i)
        Next
        $wins[0][0] = UBound($wins) - 1
        If $wins[0][0] Then Return SetError(0, 0, $wins)
        Sleep(1000)
    Until TimerDiff($secs) >= $timeout * 1000
    Return SetError(1, 0, $wins)
 EndFunc   ;==>WinHandFromPID

While 1
   $ming = Run("C:\Walton-GPU-64\GPUMing_v0.2\ming_run.exe")
   Sleep(500)
   $consoleHost = Run('cmd /K "cd C:\Walton-GPU-64\"') ;creates cmd.exe handle, either create .bat or use pid
   ;$consoleHandle = WinHandFromPID($consoleHost, $winTitle = "C:\Walton-GPU-64", $timeout = 8)
   $count = 0
   While $count < 50
	  $count = $count + 1
       WinActivate("C:\Windows\SYSTEM32\cmd.exe")
	   If WinActive("C:\Windows\SYSTEM32\cmd.exe") <> 0 Then
		  Send("start_gpu.bat")
		  Send("{ENTER}")
		  Sleep(750)
		  If Winactive("C:\Windows\SYSTEM32\cmd.exe - start_gpu.bat") <> 0 Then
		     ExitLoop(1)
		  EndIf
	   EndIf
	Wend

   $count = 0
   While $count < 50
	  $count = $count + 1
	   WinActivate("C:\Windows\SYSTEM32\cmd.exe - start_gpu.bat")
	   If Winactive("C:\Windows\SYSTEM32\cmd.exe - start_gpu.bat") <> 0 Then
		  Send("miner.start()")
		  Send("{ENTER}")
		  ExitLoop(1)
	   EndIf
	  WEnd
   timedEscape()
   clipToFile()
WEnd