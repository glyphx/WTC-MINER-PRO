Multigpu + CPU Automation for WaltonChain Miner: 1.7.0



[INSTALLATION]:
Autoit can be compiled as an .exe (bit faster) or run as a script, feel free to download an .exe in the release section or compile/run it yourself.

https://www.autoitscript.com/site/autoit/downloads/ -Downloads page
https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3-setup.exe - Setup file


If you want to change the directory default configuration, they can be fairly easily modified at the top of the script.

MULTIGPU: The default is setup for 1 GPU, a quick edit at the top to $NUM_GPUS set to another value, such as 2,3,4 etc will spawn these extra processes at the corresponding ports.
$NUM_GPU Default Configuration: 1

CPU: SET $NUM_CPU's to 1 in the top of the script. 
$NUM_CPU Default Configuration: 0 (Currently can only be 1 or 0)


[DIRECTORY STRUCTURE ASSUMPTIONS \ DEFAULT CONFIG]: 
You have a directory structure of:
C:\Walton-GPU-641
C:\Walton-GPU-642
C:\Walton-GPU-643 etc

[EXAMPLE DIRECTORY STRUCTURE]
C:\
├── Walton-GPU-641
│   ├── genesis.json
│   ├── GPUMing_v0.2
│   │   ├── cudart32_80.dll
│   │   ├── cudart64_80.dll
│   │   ├── ming_run.exe
│   │   ├── ming_run.iobj
│   │   ├── ming_run.ipdb
│   │   └── ming_run.pdb
│   ├── log.txt   *Will be created for you* 
│   ├── node1     
│   │   └── keystores
│   │       └── keystore.json *This is optional, you can choose to include the etherbase information at the top of the script*
│   ├── _This miner uses ports 30303 and 8545
│   └── walton1.exe
└── Walton-GPU-642
    ├── genesis.json
    ├── GPUMing_v0.2
    │   ├── cudart32_80.dll
    │   ├── cudart64_80.dll
    │   ├── ming_run.exe
    ├── log.txt
    ├── node1
    │   └── keystores
    │       └── Keystore.json     
    ├── This miner uses ports 30304 and 8546
    └── walton2.exe

[FILE STRUCTURE ASSUMPTIONS \ DEFAULT CONFIG]:
Walton.exe should also be renamed to walton 1, walton 2, etc.

[PORT ASSUMPTIONS \ DEFAULT CONFIG]:
The script assumes that you have setup your multiGPU setup with ascending ports, from walton1 = 30303, 8545.  Walton2 = 30304,8546, etc.

[EXITING AND LOGGING]:
Press and hold scroll lock untill you see the tool tip change to "Scroll Lock Behind Held Down, Shutting Down", the script will log each miner and exit all processes including itself.
Another way to exit without logging or closing any of the miners is simply right clicking the .exe/script in the taskbar and selecting quit. 


0.6 Goals: Better user interface.



