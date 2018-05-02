#include <CmdA.au3>
#include <Array.au3>
#include <Constants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>

$cmdPID = Run(@ComSpec & ' /k walton1 --identity "development" --gpupow --rpc --rpcaddr 127.0.0.1 --rpccorsdomain "*"  --datadir "node1" --port "30304" --rpcport 8546 console --rpcapi "admin,personal,db,eth,net,web3,miner" --ipcdisable --networkid 999',"C:\Walton-GPU-641\",@SW_SHOW,0x10)
WinWaitActive("")
Sleep(4000)
$vhandle = _cmdAttachConsole($cmdPID)

$ubounds = Ubound($vhandle)

$output = _CmdGetText($vhandle)
ProcessClose($cmdPID)
;ProcessClose("walton1.exe")
MsgBox(0,"",$cmdPID & @CRLF & $output)
