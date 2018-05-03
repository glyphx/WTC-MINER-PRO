
#include <Array.au3>
#include <AutoItConstants.au3>
#include <CmdA.au3>
#include <Date.au3>
#include <FileConstants.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>
#include <_SingleScript.au3>
#include <Clipboard.au3>

_SingleScript() ;prevents more than one instance from running so long as they share the same name, the newer instance overwrites the old.

Global Const $LOOP_SIZE_IN_MIN = 120        ;change the time of the main loop here.
Global Const $ROOT_DIR = "C:\"              ;path to folder containing all copies of $FOLDER_NAME
Global Const $FOLDER_NAME = "WALTON-GPU-64" ;name of folder(s) inside $ROOT_DIR containing walton.exe
Global Const $MING_FOLDER_NAME = "GPUMing_v0.2" ;name of folder(s) inside $FOLDER_NAME that contains ming_run.exe
Global Const $NUM_GPUS = 1                  ;set the number of gpu's
Global Const $KILL_PROCS = 1                ;if set to 1 will kill processes and start anew every loop, otherwise logs have duplication.
Global Const $SHOW_WINDOW = @SW_SHOW        ;However, if you have a hard time aquiring peers, you might want to set kill_procs to 0.
Global Const $etherbase = ""
                                            ;change to @SW_HIDE to change to hidden windows.
Global $gpu_path = '1'
Global $working_dir = $ROOT_DIR & $FOLDER_NAME & $gpu_path & '\'
Global $log_path = $working_dir & "log.txt"
Global $ming_path = $working_dir & $MING_FOLDER_NAME & "\ming_run.exe"
Global $hFileOpen = FileOpen($log_path, $FO_APPEND)
Global $gpuPOW = ' --gpupow'
Global $peerPort = " 30303"                 ;Start first miner on 30303 and add +1 for each additional miner, eg. miner 2 would be 30304
Global $rpcPort = " 8545"                   ;Start first miner rpc on 8545, miner 2: 8546, miner 3: 8547 etc
Global $maxPeers = "50"                     ;Adjust the amount of maximum peers you can have per miner. 
Global $pids[$NUM_GPUS][2]
Global $first_run = 1
Global $NUM_CPUS = 0                        ;currently can only be 0 or 1

If $hFileOpen = -1 Then
     MsgBox($MB_SYSTEMMODAL, "", "An error occured opening the log file, make sure install "
     & "path matches the configuration. Make sure you're able to open a new file @ " & $ROOT_DIR & ".")
     Return False
EndIf
FileClose($hFileOpen)

While 1    
     _runCMDS()
     _timedEscape() ;listen for escape key, if pressed run: _ConsoleToFile, and _closeProcesses and then exit()
     _ConsoleToFile() ; writes console buffer to log file
     If $KILL_PROCS = 1 Then
          _closeProcesses() ; close all processes started by script
     EndIf
WEnd

Func _runCMDS()
    For $miner = 0 to $NUM_GPUS - 1 + $NUM_CPUS
          If $NUM_CPUS <> 0 & $first_run = 1 Then
               $gpuPOW = ""
          EndIf

          Global $runCMD = @COMSPEC _
          & ' /k walton' & $gpu_path _
          & ' --maxpeers ' & $maxPeers _
          & ' --port ' & $peerPort _
          & ' --rpcport ' & $rpcPort & ' console' _
          & ' --identity "development"' _
          & ' --rpc --rpcaddr 127.0.0.1' _
          & ' --rpccorsdomain "*"' _
          & ' --rpcapi "admin,personal,db,eth,net,web3,miner"' _
          & ' --datadir "node1"' _
          & ' --ipcdisable' _
          & ' --networkid 999' _
          & ' --mine' _
          & $gpuPOW _

          $gpuPOW = "--gpuPOW"
          $pids[$miner][0] = Run($ming_path)
          ProcessWait(($pids[$miner][0]))
          $pids[$miner][1] = Run($runCMD,$working_dir,$SHOW_WINDOW)
          ProcessWait($pids[$miner][1])
          If $NUM_GPUS -1 > $miner Then
               $peerPort += 1
               $rpcPort += 1
               $gpu_path += 1
               $working_dir = $ROOT_DIR & $FOLDER_NAME & $gpu_path & '\'
               $ming_path = $working_dir & $MING_FOLDER_NAME & "\ming_run.exe"
          EndIf
     Next
     $peerPort = "30303"
     $rpcPort = "8545"
     $gpu_path = "1"
     $working_dir = $ROOT_DIR & $FOLDER_NAME & $gpu_path & '\'
     Global $ming_path = $working_dir & $MING_FOLDER_NAME & "\ming_run.exe"
     $first_run = 0
EndFunc ;==>_runCmds()

; waiting to capture scroll lock, log, and quit.
Func _timedEscape()
    $pressed = 0
    $hTimer = TimerInit()
    While (TimerDiff($hTimer) < ($LOOP_SIZE_IN_MIN * 60000))
          If _IsPressed("91") Then ;is scroll lock pressed
               If Not $pressed Then
                    ToolTip("Scroll Lock Behind Held Down, Shutting Down")
                    $pressed = 1
                    _ConsoleToFile()
                    _closeProcesses()
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

;open a file, grab handle to console buffer of walton.exe, print to file.
Func _ConsoleToFile()
    For $miner = 0 to $NUM_GPUS - 1
          $hFileOpen = FileOpen($log_path, $FO_APPEND)
          FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
          $vhandle = _cmdAttachConsole($pids[$miner][1])
          $output = _CmdGetText($vhandle)
          FreeConsole()
          FileWrite($hFileOpen, $output & @CRLF)
          FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
          FileClose($hfileOpen)
    Next
EndFunc

; close all the processes the script opened not including itself
Func _closeProcesses() ;rewrite to be more generic so it can be started before main execution of script to ensure clear execution
     For $miner = 0 to $NUM_GPUS - 1
          $count = 5
          While ProcessExists('walton' & $miner + 1  & '.exe')
               $count = $count - 1
               sleep(200)
               ProcessClose('walton' & $miner + 1 & '.exe')
          WEnd
          WinKill('walton' & $miner + 1 & '.exe')
          $count = 5
          while ProcessExists($pids[$miner][1]) & $count > 0
               $count = $count - 1
               sleep(200)
               ProcessClose($pids[$miner][1])
          WEnd
          WinKill($pids[$miner][1])
          $count = 5
          while ProcessExists($pids[$miner][0]) & $count > 0
               $count = $count - 1
               sleep(200)
               ProcessClose($pids[$miner][0])
          WEnd
          WinKill($pids[$miner][0])
     Sleep(1000)
     Next
EndFunc