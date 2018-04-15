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

_SingleScript() ;prevents more than one instance from running.

Global Const $logFilePath = "C:\Walton-GPU-64\log.txt"
Global $hFileOpen = FileOpen($logFilePath, $FO_APPEND)

If $hFileOpen = -1 Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file. Make sure you're able to open a new file @ C:\Walton-GPU-64.")
   Return False
   EndIf
FileClose($hFileOpen)

While 1
$ming = Run("C:\Walton-GPU-64\GPUMing_v0.2\ming_run.exe")
Sleep(500)
$consoleHost = Run('cmd /K "cd C:\Walton-GPU-64\"')
WinWaitActive("")
Send("start_gpu.bat")
Send("{ENTER}")
Sleep(1000)
Send("miner.start()")
Send("{ENTER}")
Sleep(3600000)
WinActivate("C:\WINDOWS\SYSTEM32\cmd.exe - start_gpu.bat")
Send("!{SPACE}")
Sleep(100)
Send("e")
Sleep(100)
Send("s")
Sleep(20)
Send("{ENTER}")
$hFileOpen = FileOpen($logFilePath, $FO_APPEND)
FileWrite($hFileOpen, _NowDate() & " " & _nowTime() & @CRLF)
FileWrite($hFileOpen, _ClipBoard_GetData() & @CRLF)
FileWrite($hFileOpen, _nowDate() & " " & _nowTime() & @CRLF)
FileClose($hfileOpen)
ProcessClose("walton.exe")
ProcessClose($consoleHost)
ProcessClose($ming)
Sleep(500)
WEnd

