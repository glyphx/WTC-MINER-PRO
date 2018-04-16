#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author: @glyph
 Version 0.2
 Script Function:
	Opens WTC miner, starts mining, logs, closes on 1h loop.

MIT LICENSE
Copyright 2018 glyphx

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

_SingleScript() ;prevents more than one instance from running.

Global Const $logFilePath = "C:\Walton-GPU-64\log.txt"

Global $loopSizeInMins = 10
Global $hFileOpen = FileOpen($logFilePath, $FO_APPEND)
Global $pressed = 0
Global $hTimer = 0

If $hFileOpen = -1 Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file. Make sure you're able to open a new file @ C:\Walton-GPU-64.")
   Return False
   EndIf
FileClose($hFileOpen)
Func clipToFile()
   $count = 0
   While $count < 50
       $count = $count + 1
       WinActivate("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat")
       If WinActive("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat") <> 0 Then
		  Send("!{SPACE}")
		  Sleep(100)
	      If WinActive("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat") <> 0 Then
		     Send("e")
             Sleep(100)
			 If WinActive("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat") <> 0 Then
				Send("s")
				Sleep(100)
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

   $hFileOpen = FileOpen($logFilePath, $FO_APPEND)
   FileWrite($hFileOpen, _NowDate() & " " & _nowTime() & @CRLF)
   FileWrite($hFileOpen, _ClipBoard_GetData() & @CRLF)
   FileWrite($hFileOpen, _nowDate() & " " & _nowTime() & @CRLF)
   FileClose($hfileOpen)
   Sleep(2000)
   ProcessClose("walton.exe")
   ProcessClose($consoleHost)
   ProcessClose($ming)
   Sleep(500)

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
While 1
   $ming = Run("C:\Walton-GPU-64\GPUMing_v0.2\ming_run.exe")
   Sleep(500)
   $consoleHost = Run('cmd /K "cd C:\Walton-GPU-64\"') ;creates cmd.exe handle, either create .bat or use pid
   $count = 0
   While $count < 50
       WinActivate("C:\WINDOWS\SYSTEM32\cmd.exe")
	   If WinActivate("C:\WINDOWS\SYSTEM32\cmd.exe") <> 0 Then
		  Send("start_gpu.bat") ;can you send enter in one line?
		  Send("{ENTER}")
		  Sleep(750)
		  If Winactive("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat") <> 0 Then
		     ExitLoop(1)
		  EndIf
	   EndIf
	Wend

   $count = 0
   While $count < 50
	  $count = $count + 1
	   WinActivate("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat")
	   If Winactive("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat") <> 0 Then
		  Send("miner.start()")
		  Send("{ENTER}")
		  ExitLoop(1)
	   EndIf
	  WEnd
   timedEscape()
   clipToFile()
WEnd

