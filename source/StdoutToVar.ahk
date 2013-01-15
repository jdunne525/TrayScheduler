;------------------------------------------------------------------------------
; StdoutToVar_CreateProcess(sCmd, bStream = "", sDir = "", sInput = "")
; by Sean
;------------------------------------------------------------------------------

/*	Example1
MsgBox % sOutput := StdoutToVar_CreateProcess("ipconfig.exe /all")
*/

/*	Example2 with Streaming
MsgBox % sOutput := StdoutToVar_CreateProcess("ping.exe www.autohotkey.com", True)
*/

/*	Example3 with Streaming and Calling Custom Function	; Custom Function Name must not consist solely of numbers!
MsgBox % sOutput := StdoutToVar_CreateProcess("ping.exe www.autohotkey.com", "Stream")	; Custom Function Name is "Stream" in this example!

Stream(sString)
{
;	Custom Routine here! For example,
;	OutputDebug %sString%
}
*/

/*	Example4 with Working Directory
MsgBox % sOutput := StdoutToVar_CreateProcess("cmd.exe /c dir /a /o", "", A_WinDir)
*/

/*	Example5 with Input String
MsgBox % sOutput := StdoutToVar_CreateProcess("sort.exe", "", "", "abc`r`nefg`r`nhijk`r`n0123`r`nghjki`r`ndflgkhu`r`n")
*/

StdoutToVar_CreateProcess(sCmd, bStream = False, sDir = "", sInput = "")
{
   DllCall("CreatePipe", "UintP", hStdInRd , "UintP", hStdInWr , "Uint", 0, "Uint", 0)
   DllCall("CreatePipe", "UintP", hStdOutRd, "UintP", hStdOutWr, "Uint", 0, "Uint", 0)
   DllCall("SetHandleInformation", "Uint", hStdInRd , "Uint", 1, "Uint", 1)
   DllCall("SetHandleInformation", "Uint", hStdOutWr, "Uint", 1, "Uint", 1)
   VarSetCapacity(pi, 16, 0)
   NumPut(VarSetCapacity(si, 68, 0), si)   ; size of si
   NumPut(0x100   , si, 44)      ; STARTF_USESTDHANDLES
   NumPut(hStdInRd   , si, 56)      ; hStdInput
   NumPut(hStdOutWr, si, 60)      ; hStdOutput
   NumPut(hStdOutWr, si, 64)      ; hStdError
   If Not   DllCall("CreateProcess", "Uint", 0, "Uint", &sCmd, "Uint", 0, "Uint", 0, "int", True, "Uint", 0x08000000, "Uint", 0, "Uint", sDir ? &sDir : 0, "Uint", &si, "Uint", &pi)   ; bInheritHandles and CREATE_NO_WINDOW
      ExitApp
   DllCall("CloseHandle", "Uint", NumGet(pi,0))
   DllCall("CloseHandle", "Uint", NumGet(pi,4))
   DllCall("CloseHandle", "Uint", hStdOutWr)
   DllCall("CloseHandle", "Uint", hStdInRd)
   If   sInput <>
   DllCall("WriteFile", "Uint", hStdInWr, "Uint", &sInput, "Uint", StrLen(sInput), "UintP", nSize, "Uint", 0)
   DllCall("CloseHandle", "Uint", hStdInWr)
   bStream ? (bAlloc:=DllCall("AllocConsole"),hCon:=DllCall("CreateFile","str","CON","Uint",0x40000000,"Uint",bAlloc ? 0 : 3,"Uint",0,"Uint",3,"Uint",0,"Uint",0)) : ""
   VarSetCapacity(sTemp, nTemp:=bStream ? 64-nTrim:=1 : 4095)
   Loop
      If   DllCall("ReadFile", "Uint", hStdOutRd, "Uint", &sTemp, "Uint", nTemp, "UintP", nSize:=0, "Uint", 0)&&nSize
      {
         NumPut(0,sTemp,nSize,"Uchar"), VarSetCapacity(sTemp,-1), sOutput.=sTemp
         If   bStream&&hCon+1
            Loop
               If   RegExMatch(sOutput, "[^\n]*\n", sTrim, nTrim)
                  DllCall("WriteFile", "Uint", hCon, "Uint", &sTrim, "Uint", StrLen(sTrim), "UintP", nSize:=0, "Uint", 0)&&nSize ? nTrim+=nSize : ""
               Else   Break
      }
      Else   Break
   DllCall("CloseHandle", "Uint", hStdOutRd)
   bStream ? (DllCall("Sleep","Uint",1000),hCon+1 ? DllCall("CloseHandle","Uint",hCon) : "",bAlloc ? DllCall("FreeConsole") : "") : ""
   Return   StrGet(&sOutput,"CP0")
}
