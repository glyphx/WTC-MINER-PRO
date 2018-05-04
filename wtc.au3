;@Author : glyph
;@License : MIT, A copy should have been included in your copy of the software. If not, you can get one at: https://opensource.org/licenses/MIT
;TOMORROW - START COUNT FROM 0, MAKE CPU LAST
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

;------------------------------------CORE USER OPTIONS ----------------------------------------------------------------------------------
Global Const $ETHERBASE = ' --etherbase "0xf3faf814cd115ebba078085a3331774b762cf5ee"' ;aka pubkey, aka wallet address
;Directly above is where to set your public wallet address.  --
;If you have ANY FILE inside of C:\Walton-GPU-64x\node1\keystores\ this etherbase setting won't be used.
;Instead it would use the address of the .json keystore file.
Global Const $NUM_GPUS = 3                      ;set the number of gpu's
Global Const $NUM_CPUS = 1                      ;set the number of cpu's -- currently can only be 0 or 1
Global Const $LOOP_SIZE_IN_MIN = 120            ;change the time of the main loop here.
Global Const $KILL_PROCS = 1 ;if set to 1 will kill processes and start anew every loop, otherwise logs have duplication.
;Set $KILL_PROCS to 0 if you have a hard time getting peers as it will reset the miners every $LOOP_SIZE_IN_MIN
Global Const $SHOW_WINDOW = @SW_SHOW  ;change $SHOW_WINDOW to @SW_HIDE to change to hidden windows, or @SW_MINIMIZE to start minimized.
Global $MINER_THREADS = ' --minerthreads=3' ;only affects CPU mining, the more your crush your cpu, more likely gpus get unstable.
; https://steemit.com/waltonchain/@slackerjack/mining-waltonchain-mainnet-with-cpu-via-cli  TODO: Include CPU Affinity Logic to Program
;----------------------------------------------------------------------------------------------------------------------------------------

;--------------------------------------PATH OPTIONS--------------------------------------------------------------------------------------
Global Const $ROOT_DIR = "C:\"                  ;path to folder containing all copies of $FOLDER_NAME
Global Const $FOLDER_NAME = "WALTON-GPU-64"     ;name of folder(s) inside $ROOT_DIR containing walton.exe
Global Const $MING_FOLDER_NAME = "GPUMing_v0.2" ;name of folder(s) inside $FOLDER_NAME that contains ming_run.exe
Global $gpu_path = '0' ;how miner files are differentiated, don't touch this unless you trace the code to see how it works
;---------------------------------------------------------------------------------------------------------------------------------------
Global Const $lastRun = $NUM_CPUS + $NUM_GPUS - 1
Global $working_dir = $ROOT_DIR & $FOLDER_NAME & $gpu_path & '\'  ;directory we're currently in
Global $log_path = $working_dir & "log.txt" ;yep, you got it, it's the path of the log file we create.
Global $ming_path = $working_dir & $MING_FOLDER_NAME & "\ming_run.exe"  ; MING MING MING!
Global $keystorejson_path = $working_dir & "node1\keystores\"
Global $gpuOrCpu = ' --gpupow'    ;tells walton.exe if it is cpu or gpu, if gpu isn't active this is set to $MINER_THREADS
Global $peerPort = " 30303"     ;Start first miner on 30303 and add +1 for each additional miner, eg. miner 2 would be 30304
Global $rpcPort = " 8545"       ;Start first miner rpc on 8545, miner 2: 8546, miner 3: 8547 etc
Global $maxPeers = "50"         ;Adjust the amount of maximum peers you can have per miner.
Global $pids[$NUM_GPUS+$NUM_CPUS][2]      ;array that stores the process id's of all the walton / mings
Global $ETHERBASEHolder = $ETHERBASE ; temp holder for etherbase address in case situations are different between miners
Global $runNonKillProcs = 0

_Main() ;HERE WE GOOOOOOO!

Func _Main()
     While 1
          If $KILL_PROCS = 1 Then
               _runCMDS()
          ElseIf $KILL_PROCS = 0 & $runNonKillProcs = 0 Then
               _runCMDS()
               $runNonKillProcs = 1
          EndIf
          _timedEscape() ;listen for escape key, if pressed run: _ConsoleToFile, and _closeProcesses and then exit()
          _ConsoleToFile() ; writes console buffer to log file
          If $KILL_PROCS = 1 Then
               _closeProcesses() ; close all processes started by script
          EndIf
     WEnd
EndFunc;==>_Main()

Func _runCMDS()
    For $thisRun = 0 to $lastRun

          If _WinAPI_PathIsDirectory($working_dir) = 0 Then
               MsgBox(0,"","Check your directory structure " & $working_dir & " does not exist")
               Exit(0)
          EndIf
          If $NUM_CPUS = 1 Then
               If $thisRun = $lastRun Then
                    $gpuOrCpu = $MINER_THREADS
               EndIf
          EndIf
          If not _WinAPI_PathIsDirectory($working_dir & "node1\") Then
               Run(@ComSpec & ' /c walton' & $gpu_path & " --datadir node1 init genesis.json",$working_dir)
          EndIf
          If _WinAPI_PathIsDirectory($keystorejson_path) = True Then
               If _WinAPI_PathIsDirectoryEmpty($keystorejson_path) = False Then
                    $ETHERBASEHolder = ""
               EndIf
          EndIf

          Global $runCMD = @COMSPEC _
          & ' /k walton' & $gpu_path _
          & $ETHERBASEHolder _
          & $gpuOrCpu _
          & ' --port ' & $peerPort _
          & ' --rpcport ' & $rpcPort & ' console' _
          & ' --maxpeers ' & $maxPeers _
          & ' --identity "development"' _
          & ' --rpc --rpcaddr 127.0.0.1' _
          & ' --rpccorsdomain "*"' _
          & ' --rpcapi "admin,personal,db,eth,net,web3,miner"' _
          & ' --datadir "node1"' _
          & ' --ipcdisable' _
          & ' --networkid 999' _
          & ' --mine'

          If $NUM_CPUS = 0 Then
               $pids[$thisRun][0] = Run($ming_path)
               ProcessWait($pids[$thisRun][0])
          ElseIf $thisRun <> $lastRun  Then
               $pids[$thisRun][0] = Run($ming_path)
               ProcessWait($pids[$thisRun][0])
          EndIf
          $gpuOrCpu = ' --gpupow'
          $ETHERBASEHolder = $ETHERBASE

          $pids[$thisRun][1] = Run($runCMD,$working_dir,$SHOW_WINDOW)
          ProcessWait($pids[$thisRun][1])
          If Not $lastRun = 0 Then
               $peerPort += 1
               $rpcPort += 1
               $gpu_path += 1
               $working_dir = $ROOT_DIR & $FOLDER_NAME & $gpu_path & '\'
               $ming_path = $working_dir & $MING_FOLDER_NAME & "\ming_run.exe"
               $keystorejson_path = $working_dir & "node1\keystores\"
          EndIf
     Next
     ;Reset things back to their initial values to through go the loop again
     If $lastRun > 0 Then
          $peerPort = "30303"
          $rpcPort = "8545"
          $gpu_path = "1"
          $working_dir = $ROOT_DIR & $FOLDER_NAME & $gpu_path & '\'
          $ming_path = $working_dir & $MING_FOLDER_NAME & "\ming_run.exe"
          $keystorejson_path = $working_dir & "node1\keystores\"
     EndIf
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
EndFunc;==>_timedEscape()

;open a file, grab handle to console buffer of walton.exe, print to file.
Func _ConsoleToFile()
    For $thisRun = 0 to $lastRun
          $log_path = $ROOT_DIR & $FOLDER_NAME & $thisRun + 1 & "\log.txt"
          $hFileOpen = FileOpen($log_path, $FO_APPEND)
          FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
          $vhandle = _cmdAttachConsole($pids[$thisRun][1]) ; attach to console and get handle to buffer
          $output = _CmdGetText($vhandle) ; kernel call to grab the text from the buffer
          FreeConsole() ;detatch from the console
          FileWrite($hFileOpen, $output & @CRLF)
          FileWrite($hFileOpen, _NowDate() & " " & _NowTime() & @CRLF)
          FileClose($hfileOpen)
    Next
    $log_path = $ROOT_DIR & $FOLDER_NAME & $gpu_path & "\log.txt"
EndFunc;==>_ConsoleToFile()

; close all the processes the script opened not including itself
Func _closeProcesses() ;rewrite to be more generic so it can be started before main execution of script to ensure clear execution
     For $thisRun = 0 to $lastRun
          $count = 5
          While ProcessExists('walton' & $thisRun + 1  & '.exe')
               $count = $count - 1
               ProcessClose('walton' & $thisRun + 1 & '.exe')
               sleep(500)
          WEnd
          WinKill('walton' & $thisRun + 1 & '.exe')
          $count = 5
          while ProcessExists($pids[$thisRun][1]) & $count > 0
               $count = $count - 1
               ProcessClose($pids[$thisRun][1])
               sleep(500)
          WEnd
          WinKill($pids[$thisRun][1])
          $count = 5
          while ProcessExists($pids[$thisRun][0]) & $count > 0
               $count = $count - 1
               ProcessClose($pids[$thisRun][0])
               sleep(500)
          WEnd
          WinKill($pids[$thisRun][0])
     Sleep(1000)
     Next
EndFunc;==>_closeProcesses()