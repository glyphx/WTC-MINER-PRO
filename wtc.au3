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
Global $np = 'notepad.exe wtc_log_'
Global $cmd = ""
While 1
$ming = Run("C:\Walton-GPU-64\GPUMing_v0.2\ming_run.exe")
Sleep(1500)
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
Sleep(3000)
Send("e")
Sleep(3000)
Send("s")
Sleep(20)
Send("{ENTER}")
$cmd = String(_NowTime() & "_" & String(_NowDate()))
$cmd = StringReplace($cmd, ":", "")
$cmd = StringReplace($cmd, "/", "")
$cmd = StringReplace($cmd, " ", "")
$cmd = $np & $cmd
$notepad = run($cmd)
WinWaitActive("")
Send("{ENTER}")
Send("^v")
Send("^s")
ProcessClose("walton.exe")
ProcessClose($walton)
ProcessClose($ming)
ProcessClose("notepad.exe")
Sleep(1500)
WEnd