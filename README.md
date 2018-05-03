# MultiGPU + CPU Automation for WaltonChain Miner: 1.7.0

## [INSTALLATION]  :nut_and_bolt:

Step 1> Download scripts via .zip, .exe release, or git clone.  \
Step 2> *IMPORTANT* Rename first folder to Walton-GPU-641 and walton.exe to walton1.exe, further described below.  \
Step 3> Configure $NUM_GPU and $NUM_CPU inside of wtc.au3 *if you downloaded .exe just run it now* \
Step 4> compile and run

## [INSTALL AUTOIT IF COMPILING YOURSELF] :package:

For the fastest execution Autoit can be compiled as an .exe, but if autoit is installed it can also be run as a script by double-clicking wtc.au3. 
Feel free to download an .exe in the release section or compile/run it yourself. \
It's easy to compile Autoit, simply right click the wtc.au3 script after installing autoit and select compile (x86), an .exe will be generated.
The .exe's autoit generates are stand alone and do not require autoit to be installed to use. *release section*

https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3-setup.exe - **Direct Download Autoit 32/64**

## [DIRECTORY STRUCTURE ASSUMPTIONS \ DEFAULT CONFIG] :file_folder:

You have a directory structure of:
C:\Walton-GPU-641
C:\Walton-GPU-642
C:\Walton-GPU-643

## [FILE STRUCTURE ASSUMPTIONS \ DEFAULT CONFIG] :file_folder:

Walton.exe should also be renamed to walton 1, walton 2, etc.

## [EXAMPLE DIRECTORY STRUCTURE]  :file_folder:

C:\  \
├── Walton-GPU-641  \
│       ├── genesis.json  \
│       ├── GPUMing_v0.2
│       │       ├── cudart32_80.dll  \
│       │       ├── cudart64_80.dll  \
│       │       ├── ming_run.exe *If using CPU this isn't run. If not using CPU this must point to GPU0**   \
│       │       ├── ming_run.iobj  \
│       │       ├── ming_run.ipdb
│       │       └── ming_run.pdb  \
│       ├── log.txt   **Will be created for you**  \
│       ├── node1  \
│       │      └── keystores  \
│       │                   └── keystore.json **OPTIONAL, you can choose to include the etherbase information at the top of the script** \
│       ├── _This miner uses ports 30303 and 8545  \
│       └── walton1.exe  
└── Walton-GPU-642
         ├── genesis.json  \
         ├── GPUMing_v0.2
         │        ├── cudart32_80.dll  \
         │        ├── cudart64_80.dll  \
         │        ├── ming_run.exe **If using CPU this points to GPU0, if not using CPU this must point to GPU1. \
         ├── log.txt  \
         ├── node1  \
         │      └── keystores
         │                   └── Keystore.json  \
         ├── This miner uses ports 30304 and 8546  \
         └── walton2.exe  **If using CPU walton2.exe points to GPU0.**

## [MULTIGPU] :vhs:

Set $NUM_GPUS at the top of wtc.au3 \
It should correspond with the number of instances on GPU's you would like to run \
$NUM_GPU Default Configuration: 1

## [CPU] :computer:

If you want to use CPU, set $NUM_CPU's to 1 in the top of wtc.au3.  \
$NUM_CPU Default Configuration: 0 (Currently can only be 1 or 0)  \
If using cpu it will be walton1.exe, which means walton2.exe should point to gpu0 if using CPU + GPU

## [EXAMPLE MULTI-GPU AND CPU SETUP] :computer: :vhs: :vhs: :vhs: :vhs:

$GPU_NUM = 3 \
$CPU_NUM = 1 \
Then, CPU0 is Walton1.exe is on port 30303, and 8545.  GPU0 is walton2.exe on ports 30304, 8546/ GPU1. \
GPU1 is walton3.exe on port 30305, 8547, and finally GPU2 is walton4.exe, ports 30306, and 8548.

## [PORT ASSUMPTIONS \ DEFAULT CONFIG] :phone:

The script assumes that you have setup your multiGPU setup with ascending ports, from walton1 = 30303, 8545.  Walton2 = 30304,8546, etc.

## [LOGGING AND EXITING] :ledger: :door:

Press and hold scroll lock untill you see the tool tip change to "Scroll Lock Behind Held Down, Shutting Down", the script will log each miner and exit all processes including itself.
Another way to exit without logging or closing any of the miners is simply right clicking the .exe/script in the taskbar and selecting quit.

At the top of wtc.au3 is where all the user options are. Here is a code snippit of the relavent section.

## -----------------------------CORE USER OPTIONS --------------------------

```autoit
'Global $etherbase = ' --etherbase "0xf3faf814cd115ebba078085a3331774b762cf5ee"'
;Directly above is where to set your public wallet address.
;If you have ANY FILE inside of C:\Walton-GPU-64x\node1\keystores\ this etherbase setting won't be used.
;Instead it would use the address of the .json keystore file.
Global Const $NUM_GPUS = 1                      ;set the number of gpu's
Global Const $NUM_CPUS = 0                      ;set the number of cpu's -- currently can only be 0 or 1
Global Const $LOOP_SIZE_IN_MIN = 120            ;change the time of the main loop here.
Global Const $KILL_PROCS = 1 ;if set to 1 will kill processes and start anew every loop, otherwise logs have duplication.
;Set $KILL_PROCS to 0 if you have a hard time getting peers as it will reset the miners every $LOOP_SIZE_IN_MIN
Global Const $SHOW_WINDOW = @SW_SHOW  ;change $SHOW_WINDOW to @SW_HIDE to change to hidden windows, or @SW_MINIMIZE to start minimized.
Global Const $MINER_THREADS = ' --minerthreads=8' ;only affects CPU mining, the more your crush your cpu, more likely gpus get unstable.
```

0.6 Goals: Better user interface.