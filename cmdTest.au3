#include <CmdA.au3>
#include <Array.au3>
#include <Constants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>

$cmdPID = Run("cmd.exe /k dir")
WinWaitActive("")
$vhandle = _cmdAttachConsole($cmdPID)
$output = _CmdGetText($vhandle)
$ubounds = Ubound($vhandle)
MsgBox(0,"","output" & @CRLF & $output)