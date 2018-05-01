#include <CmdA.au3>
#include <Array.au3>
#include <Constants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>

$cmdPID = Run(@ComSpec & ' /k walton --identity "development" --gpupow --rpc --rpcaddr 127.0.0.1 --rpccorsdomain "*"  --datadir "node1" --port "30304" --rpcapi "admin,personal,db,eth,net,web3,miner" --ipcdisable --networkid 999 --rpcport 8546 console',"C:\Walton-GPU-64-2",@SW_HIDE,0x10)
Wait
$vhandle = _cmdAttachConsole($cmdPID)

$ubounds = Ubound($vhandle)
while 1
$output = _CmdGetText($vhandle)
MsgBox(0,"","output" & @CRLF & $output)
WEnd