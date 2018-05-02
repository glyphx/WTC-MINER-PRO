#include-Once

#include <WinAPI.au3>

; #INDEX# =======================================================================================================================
; Title .........: Cmd
; AutoIt Version : 3.3.6++
; Language ......: English
; Description ...: Functions for manipulating command prompt windows.
; Author(s) .....: PhilHibbs
; ===============================================================================================================================

; #CONSTANTS# ===================================================================================================================
Global Const $STD_INPUT_HANDLE = -10
Global Const $STD_OUTPUT_HANDLE = -11
Global Const $STD_ERROR_HANDLE = -12
Global Const $_CONSOLE_SCREEN_BUFFER_INFO = "short dwSizeX; short dwSizeY;" & _
    "short dwCursorPositionX; short dwCursorPositionY; short wAttributes;" & _
    "short Left; short Top; short Right; short Bottom; short dwMaximumWindowSizeX; short dwMaximumWindowSizeY"
Global Const $_COORD = "short X; short Y"
Global Const $_CHAR_INFO = "wchar UnicodeChar; short Attributes"
Global Const $_SMALL_RECT = "short Left; short Top; short Right; short Bottom"
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
;_CmdGetWindow
;_CmdAttachConsole
;_CmdWaitFor
;_CmdWaitList
; ===============================================================================================================================

;@glyph
Func FreeConsole()
    Local $aResult = DllCall("kernel32.dll", "bool", "FreeConsole")
    If @error Then Return SetError(@error, @extended, False)
    Return $aResult[0]
EndFunc   ;==>_WinAPI_FreeConsole

; #FUNCTION# ====================================================================================================================
; Name...........: _CmdGetWindow
; Description ...: Locates the window handle for a given Command Prompt process.
; Syntax.........: _CmdGetWindow($pCmd)
; Parameters ....: $pCmd  - Process id of the Command Prommpt application
; Return values .: Success - Window handle
;                  Failure - -1, sets @error
;                  |1 - Process $pCmd not found
; Author ........: Phil Hibbs (phil at hibbs dot me dot uk)
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func _CmdGetWindow( $pCmd )
    Local $WinList, $i
    While True
        $WinList = WinList()
        For $i = 1 to $WinList[0][0]
            If $WinList[$i][0] <> "" And WinGetProcess( $WinList[$i][1] ) = $pCmd Then
                Return $WinList[$i][1]
            EndIf
        Next
    WEnd
EndFunc   ;==>_CmdGetWindow

; #FUNCTION# ====================================================================================================================
; Name...........: _CmdAttachConsole
; Description ...: Locates the console handle for a given Command Prompt process.
; Syntax.........: _CmdAttachConsole($pCmd)
; Parameters ....: $pCmd  - Process id of the Command Prommpt application
; Return values .: Success - Window handle structure
;                  Failure - -1, sets @error
;                  |1 - Unable to attach console
;                  |2 - Unable to create file handle
; Author ........: Phil Hibbs (phil at hibbs dot me dot uk)
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func _CmdAttachConsole($nPid)
    ; Try to attach to the console of the PID.
    Local $aRet = DllCall("kernel32.dll", "int", "AttachConsole", "dword", $nPid)
    If @error Then Return SetError(@error, @extended, False)
    If $aRet[0] Then
        ; The user should treat this as an opaque handle, but internally it contains a handle
        ; and some structures.
        Local $vHandle[3]
        $vHandle[0] = _GetStdHandle($STD_OUTPUT_HANDLE) ; STDOUT Handle
        $vHandle[1] = DllStructCreate($_CONSOLE_SCREEN_BUFFER_INFO) ; Screen Buffer structure
        $vHandle[2] = DllStructCreate($_SMALL_RECT) ; SMALL_RECT structure

        ; Return the handle on success.
        Return $vHandle
    EndIf

    ; Return 0 on failure.
    Return 0
EndFunc ; _CmdAttachConsole()

Func _GetStdHandle($nHandle)
    Local $aRet = DllCall("kernel32.dll", "hwnd", "GetStdHandle", "dword", $nHandle)
    If @error Then Return SetError(@error, @extended, $INVALID_HANDLE_VALUE)
    Return $aRet[0]
EndFunc ; _GetStdHandle()

; #FUNCTION# ====================================================================================================================
; Name...........: _CmdGetText
; Description ...: Gets all the text in a Command Prompt window
; Syntax.........: _CmdGetText($hWin, $hConsole )
; Parameters ....: $hWin     - Window handle
;                  $hConsole - Console handle
; Return values .: Success - True
;                  Failure - False
;                  |1 - Window does not exist
; Author ........: Phil Hibbs (phil at hibbs dot me dot uk)
; Modified.......: Glyph
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func _CmdGetText(ByRef $vHandle)
    ; Basic sanity check to validate the handle.
    If UBound($vHandle) = 3 Then
        ; Create some variables for convenience.
        Local Const $hStdOut = $vHandle[0]
        Local Const $pConsoleScreenBufferInfo = $vHandle[1]
        Local Const $pRect = $vHandle[2]

        ; Try to get the screen buffer information.
        If _GetConsoleScreenBufferInfo($hStdOut, $pConsoleScreenBufferInfo) Then
            ; Load the SMALL_RECT with the projected text position.
            Local $iLeft = 0
            Local $iRight = DllStructGetData( $pConsoleScreenBufferInfo, 1) -1
            Local $iTop = 0
            Local $iBottom = DllStructGetData( $pConsoleScreenBufferInfo, 2) -1
            DllStructSetData( $pRect, "Left", $iLeft )
            DllStructSetData( $pRect, "Right", $iRight )
            DllStructSetData( $pRect, "Top", $iTop )
            DllStructSetData( $pRect, "Bottom", $iBottom )

            Local $iWidth = $iRight - $iLeft + 1
            Local $iHeight = $iBottom - $iTop + 1

            ; Set up the coordinate structures.
            Local $coordBufferCoord = _WinAPI_MakeDWord($iLeft, $iTop)
            Local $coordBufferSize = _WinAPI_MakeDWord($iWidth, $iHeight)

            Local $pBuffer = DllStructCreate("dword[" & $iWidth * $iHeight & "]")

            ; Read the console output.
            If _CmdReadConsoleOutput($hStdOut, $pBuffer, $coordBufferSize, $coordBufferCoord, $pRect) Then

                ; This variable holds the output string.
                Local $sText = ""

                For $j = 0 To $iHeight - 1
                    Local $sLine = ""
                    For $i = 0 To $iWidth - 1
                        ; We offset the buffer each iteration by 4 bytes because that is the size of the CHAR_INFO
                        ; structure.  We do this so we can read each individual character.
                        Local $pCharInfo = DllStructCreate($_CHAR_INFO, DllStructGetPtr($pBuffer) + ($j * $iWidth * 4) + ($i * 4))

                        ; Append the character.
                        $sLine &= DllStructGetData($pCharInfo, "UnicodeChar")
                    Next
                    $sText &= StringStripWS( $sLine, 2 ) & @CRLF
                Next
                $sText = StringStripWS( $sText, 2 )

                ; Ensure we read a valid percentage.  If so return the cast to a number.
                Return $sText
            EndIf
        EndIf
    EndIf

    ; On failure we return -1 which is obviously not a valid percentage.
    Return -1
EndFunc   ;==>_CmdGetText

Func _GetConsoleScreenBufferInfo($hConsoleOutput, $pConsoleScreenBufferInfo)
    Local $aRet = DllCall("kernel32.dll", "int", "GetConsoleScreenBufferInfo", "hwnd", $hConsoleOutput, _
        "ptr", _SafeGetPtr($pConsoleScreenBufferInfo))
    If @error Then Return SetError(@error, @extended, False)
    Return $aRet[0]
EndFunc ; _GetConsoleScreenBufferInfo()

Func _CmdReadConsoleOutput($hConsoleOutput, $pBuffer, $coordBufferSize, $coordBufferCoord, $pRect)
    ; We lie about the types for the COORD structures.  Since they are the size of an int we expect a packed
    ; int.  Otherwise we may crash or just pass garbage.
    Local $aRet = DllCall("kernel32.dll", "int", "ReadConsoleOutputW", "ptr", $hConsoleOutput, _
        "ptr", _SafeGetPtr($pBuffer), "int", $coordBufferSize, "int", $coordBufferCoord, _
        "ptr", _SafeGetPtr($pRect))
    If @error Then SetError(@error, @extended, False)
    Return $aRet[0]
EndFunc ; _CmdReadConsoleOutput()

; #FUNCTION# ====================================================================================================================
; Name...........: _CmdWaitFor
; Description ...: Waits for a particular string to be found in a Command Prompt window
; Syntax.........: _CmdWaitFor( $hWin, $vHandle, $text, $timeout = -1, $period, $prefix = "" )
; Parameters ....: $hWin    - Window handle
;                  $text    - String to search for
;                  $timeout - How long to wait for in ms, 0 = look once and return, -1 = keep looking for ever
;                  $period  - How long to pause between each content grab
;                  $prefix  - Prefix string, anything prior to this prefix is discarded before searching for $text
; Return values .: Success - True
;                  Failure - False
;                  |1 - Text is not found within the time limit
;                  |2 - Window does not exist
; Author ........: Phil Hibbs (phil at hibbs dot me dot uk)
; Modified.......:
; Remarks .......: The prefix is for searching for something that might occur multiple times, for instance if you issue a command
;                  and want to wait for the User@ prompt, the command itself should be the preifx. If you are issuing the same
;                  command multiple times, you could echo a unique string and use that as the prefix, e.g.
;                     Send( "echo :cmd123:;ls -l{Enter}" )
;                     _CmdWaitFor( $hTelnet, $wTelnet, $User & "@", -1, ":cmd123:" )
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func _CmdWaitFor( $hWin, ByRef $vHandle, $text, $timeout = Default, $period = Default, $prefix = "" )
    Local $bScrInfo, $bScrContent, $timer, $con, $i

    If $timeout = Default Then $timeout = -1
    If $period = Default Then $period = 1000

    $timer = TimerInit()
    While ($timeout <= 0 Or TimerDiff($timer) < $timeout) And WinExists( $hWin )
        $con = _CmdGetText( $vHandle )
        If $prefix <> "" Then
            $con = StringMid( $con, StringInStr( $con, $prefix, False, -1 ) + StringLen( $prefix ) )
        EndIf
        If StringInStr( $con, $text ) > 0 Then
            Return True
        EndIf
        If $timeout = 0 Then ExitLoop
        Sleep($period)
    WEnd
    Return False
EndFunc   ;==>_CmdWaitFor

; #FUNCTION# ====================================================================================================================
; Name...........: _CmdWaitList
; Description ...: Waits for one of a set of strings to be found in a Command Prompt window
; Syntax.........: _CmdWaitList($hWin, $vHandle, $aText, $timeout = -1, $period, $prefix = "" )
; Parameters ....: $hWin    - Window handle
;                  $aText   - Array of strings to search for
;                  $timeout - How long to wait for in ms, 0 = look once and return, -1 = keep looking for ever
;                  $period  - How long to pause between each content grab
;                  $prefix  - Prefix string, anything prior to this prefix is discarded before searching for $text
; Return values .: Success - Element number found
;                  Failure - -1, sets @error
;                  |1 - Text is not found within the time limit
;                  |2 - Window does not exist
; Author ........: Phil Hibbs (phil at hibbs dot me dot uk)
; Modified.......:
; Remarks .......: The prefix is for searching for something that might occur multiple times, for instance if you issue a command
;                  and want to wait for the User@ prompt, the command itself should be the preifx. If you are issuing the same
;                  command multiple times, you could echo a unique string and use that as the prefix.
; Related .......:
; Link ..........:
; Example .......:
; ===============================================================================================================================
Func _CmdWaitList( $hWin, ByRef $vHandle, ByRef $aText, $timeout = Default, $period = Default, $prefix = "" )
    Local $timer, $con, $i

    If $timeout = Default Then $timeout = -1
    If $period = Default Then $period = 1000

    SendKeepActive( $hWin )

    $timer = TimerInit()
    While ($timeout <= 0 Or TimerDiff($timer) < $timeout) And WinExists( $hWin )
        $con = _CmdGetText( $vHandle )
        If $prefix <> "" Then
            $con = StringMid( $con, StringInStr( $con, $prefix, False, -1 ) + StringLen( $prefix ) )
        EndIf
        For $i = 0 To UBound( $aText ) - 1
            If StringInStr( $con, $aText[$i] ) > 0 Then
                Return $i
            EndIf
        Next
        If $timeout = 0 Then ExitLoop
        Sleep($period)
    WEnd
    If Not(WinExists( $hWin )) Then Return SetError(2, 0, -1)
    Return SetError(1, 0, -1)
EndFunc   ;==>_CmdWaitList

Func _SafeGetPtr(Const ByRef $ptr)
    Local $_ptr = DllStructGetPtr($ptr)
    If @error Then $_ptr = $ptr
    Return $_ptr
EndFunc ; _SafeGetPtr()

Func _WinAPI_MakeDWord($LoWORD, $HiWORD)
    Local $tDWord = DllStructCreate("dword")
    Local $tWords = DllStructCreate("word;word", DllStructGetPtr($tDWord))
    DllStructSetData($tWords, 1, $LoWORD)
    DllStructSetData($tWords, 2, $HiWORD)
    Return DllStructGetData($tDWord, 1)
EndFunc   ;==>_WinAPI_MakeDWord