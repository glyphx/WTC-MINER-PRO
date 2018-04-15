#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author: @glyph
 Version 0.1
 Script Function:
	Opens WTC miner, starts mining, logs, closes on 1h loop.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <AutoItConstants.au3>
#include <Date.au3>
#include <Clipboard.au3>
#include <FileConstants.au3>
#include <WinAPIFiles.au3>
#include <MsgBoxConstants.au3>

Global $cmd = ""
Global Const $logFilePath = "C:\Walton-GPU-64\log.txt"
Global $hFileOpen = FileOpen($logFilePath, $FO_APPEND)

If $hFileOpen = -1 Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file. Make sure you're able to open a new file @ C:\Walton-GPU-64.")
   Return False
   EndIf
;FileClose($hFileOpen)
While 1
$ming = Run("C:\Walton-GPU-64\GPUMing_v0.2\ming_run.exe")
Sleep(500)
$walton = Run("cmd.exe")
WinWaitActive("")
Send("cd C:\Walton-GPU-64\")
Send("{ENTER}")
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
;FileOpen($hFileOpen, $FO_APPEND)
FileWrite($hFileOpen, _ClipBoard_GetData())
;FileClose($hFileOpen)
ProcessClose("walton.exe")
ProcessClose($walton)
ProcessClose($ming)
Sleep(500)
WEnd

