#include <Constants.au3>
Local $iPID = Run(@ComSpec & ' /k walton --identity "development" --gpupow --rpc --rpcaddr 127.0.0.1 --rpccorsdomain "*"  --datadir "node1" --port "30304" --rpcapi "admin,personal,db,eth,net,web3,miner" --ipcdisable --networkid 999 --rpcport 8546 console',"C:\Walton-GPU-64-2",@SW_SHOWNORMAL,0x10)
$hWnd = WinGetHandle()
While 1

Local $sStdOut = ""
$walton = ProcessExists("231164")
MsgBox(0,'',$walton)
Do
    Sleep(3000)
    $sStdOut &= StdoutRead("$iPID")
Until @error

MsgBox(0, '', $sStdOut)
WEnd
