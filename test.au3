#include <Array.au3>
#include <Constants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>


Global $avChildren

Local $iPID = Run(@ComSpec & ' /k walton --identity "development" --gpupow --rpc --rpcaddr 127.0.0.1 --rpccorsdomain "*"  --datadir "node1" --port "30304" --rpcapi "admin,personal,db,eth,net,web3,miner" --ipcdisable --networkid 999 --rpcport 8546 console',"C:\Walton-GPU-64-2",@SW_HIDE,0x10)
Sleep(10000)

$thehwnd = _GetHwndFromPID($iPID)
$parent = _WinAPI_GetParentProcess($iPID)
MsgBox(0,"",$iPID & ' '  & $thehwnd & ' ' & $parent)
WinListChildren($thehwnd, $avChildren)
$attach = _WinAPI_AttachConsole($iPID)
MsgBox(0,"",$attach)
_ArrayDisplay($avChildren)
ProcessClose($iPID)
Exit


Func WinListChildren($hWnd, ByRef $avArr)
    If UBound($avArr, 0) <> 2 Then
        Local $avTmp[10][2] = [[0]]
        $avArr = $avTmp
    EndIf
    
    Local $hChild = _WinAPI_GetWindow($hWnd, $GW_CHILD)
    
    While $hChild
        If $avArr[0][0]+1 > UBound($avArr, 1)-1 Then ReDim $avArr[$avArr[0][0]+10][2]
        $avArr[$avArr[0][0]+1][0] = $hChild
        $avArr[$avArr[0][0]+1][1] = _WinAPI_GetWindowText($hChild)
        $avArr[0][0] += 1
        WinListChildren($hChild, $avArr)
        $hChild = _WinAPI_GetWindow($hChild, $GW_HWNDNEXT)
    WEnd
    
    ReDim $avArr[$avArr[0][0]+1][2]
EndFunc
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