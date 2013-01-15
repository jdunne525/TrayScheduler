; basic script template for NSIS installers
;
; Written by Philip Chu
; Copyright (c) 2004-2005 Technicat, LLC
;
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it ; and redistribute
; it freely, subject to the following restrictions:
 
;    1. The origin of this software must not be misrepresented; you must not claim that
;       you wrote the original software. If you use this software in a product, an
;       acknowledgment in the product documentation would be appreciated but is not required.
 
;    2. Altered source versions must be plainly marked as such, and must not be
;       misrepresented as being the original software.
 
;    3. This notice may not be removed or altered from any source distribution.

;-----------------------------------------
; Modified by Joe Dunne.  This version is much easier to use for multiple file installations.
;
;Note: To build this installer executable:
;First, install "Nullsoft installer" from: http://nsis.sourceforge.net/Download
;Then right click on this file (installer.nsi) and click "Compile NSIS Script". 

;-------------------------------
;-------------------------------
;User modifiable section:
;-------------------------------
;-------------------------------

;Executable file name:
!define setup "TrayShutdownScheduler.exe"
  
;Company name:
!define company "Joes Tools"
 
;Title to be displayed while installing:
!define prodname "System Tray Shutdown Scheduler"

;Executable file that is being installed (shortcuts will automatically be made to it)
;Don't change this filename!!
!define exec "TrayScheduler.exe"

;Executable to run during setup:  (This can be one of the additional files below)
;This line is commented out. Don't bother modifying it.
;!define filetoexec ""

;list of additional files (See install section and uninstall section to create install and uninstalls for these files).
!define	file1 "TrayScheduler.ini"
!define	file2 "ShutdownDownEnabled.ico"
!define	file3 "ShutdownDownDisabled.ico"
!define	file4 "shutdownscheduler.ini"
!define	file5 "ShutdownScheduler.exe"
!define	file6 "GetIdleTimeAPI.dll"
!define	file7 "NetworkMonitor.dll"

; change this to wherever the files to be packaged reside
!define srcdir "."

;-------------------------------
;-------------------------------
;End user modifiable section
;-------------------------------
;-------------------------------

; optional stuff
 
; text file to open in notepad after installation
; !define notefile "README.txt"
 
; license text file
; !define licensefile license.txt
 
; icons must be Microsoft .ICO files
 !define icon "icon.ico"
 
; installer background screen
; !define screenimage background.bmp
 
;-------------------------------
; registry stuff
 
!define regkey "Software\${company}\${prodname}"
!define uninstkey "Software\Microsoft\Windows\CurrentVersion\Uninstall\${prodname}"
 
!define startmenu "$SMPROGRAMS\${company}\${prodname}"
!define uninstaller "uninstall.exe"
 
;--------------------------------
 
XPStyle on
ShowInstDetails hide
ShowUninstDetails hide
 
Name "${prodname}"
Caption "${prodname}"
 
!ifdef icon
Icon "${icon}"
!endif
 
OutFile "${setup}"
 
SetDateSave on
SetDatablockOptimize on
CRCCheck on
SilentInstall normal
 
InstallDir "$PROGRAMFILES\${company}\${prodname}"
InstallDirRegKey HKLM "${regkey}" ""
 
!ifdef licensefile
LicenseText "License"
LicenseData "${srcdir}\${licensefile}"
!endif
 
; pages
; we keep it simple - leave out selectable installation types
 
!ifdef licensefile
Page license
!endif
 
; Page components
Page directory
Page instfiles
 
UninstPage uninstConfirm
UninstPage instfiles
 
;--------------------------------
 
AutoCloseWindow false
ShowInstDetails show
 
 
!ifdef screenimage
 
; set up background image
; uses BgImage plugin
 
Function .onGUIInit
	; extract background BMP into temp plugin directory
	InitPluginsDir
	File /oname=$PLUGINSDIR\1.bmp "${screenimage}"
 
	BgImage::SetBg /NOUNLOAD /FILLSCREEN $PLUGINSDIR\1.bmp
	BgImage::Redraw /NOUNLOAD
FunctionEnd
 
Function .onGUIEnd
	; Destroy must not have /NOUNLOAD so NSIS will be able to unload and delete BgImage before it exits
	BgImage::Destroy
FunctionEnd
 
!endif
 
;--------------------------------------------------------------
; beginning (invisible) section
Section
 
  WriteRegStr HKLM "${regkey}" "Install_Dir" "$INSTDIR"
  ; write uninstall strings
  WriteRegStr HKLM "${uninstkey}" "DisplayName" "${prodname} (remove only)"
  WriteRegStr HKLM "${uninstkey}" "UninstallString" '"$INSTDIR\${uninstaller}"'
 
!ifdef filetype
  WriteRegStr HKCR "${filetype}" "" "${prodname}"
!endif
 
  WriteRegStr HKCR "${prodname}\Shell\open\command\" "" '"$INSTDIR\${exec} "%1"'
 
!ifdef icon
  WriteRegStr HKCR "${prodname}\DefaultIcon" "" "$INSTDIR\${icon}"
!endif
 
  SetOutPath $INSTDIR
 
 
; package all files, recursively, preserving attributes
; assume files are in the correct places
File /a "${srcdir}\${exec}"
 
!ifdef licensefile
File /a "${srcdir}\${licensefile}"
!endif
 
!ifdef notefile
File /a "${srcdir}\${notefile}"
!endif
 
!ifdef icon
File /a "${srcdir}\${icon}"
!endif
 
;--------------------------------------------------------
; any application-specific files  **Make sure all files in File List are also listed here:
File /a "${srcdir}\${file1}"
File /a "${srcdir}\${file2}"
File /a "${srcdir}\${file3}"
File /a "${srcdir}\${file4}"
File /a "${srcdir}\${file5}"
File /a "${srcdir}\${file6}"
File /a "${srcdir}\${file7}"

;--------------------------------------------------------
 
  WriteUninstaller "${uninstaller}"
 
SectionEnd
 
;--------------------------------------------------------------
; create shortcuts
Section
 
  CreateDirectory "${startmenu}"
  SetOutPath $INSTDIR ; for working directory
!ifdef icon
  CreateShortCut "${startmenu}\${prodname}.lnk" "$INSTDIR\${exec}" "" "$INSTDIR\${icon}"
  CreateShortCut "$DESKTOP\${prodname}.lnk" "$INSTDIR\${exec}" "" "$INSTDIR\${icon}"
!else
  CreateShortCut "${startmenu}\${prodname}.lnk" "$INSTDIR\${exec}"
  CreateShortCut "$DESKTOP\${prodname}.lnk" "$INSTDIR\${exec}"
!endif


  SetOutPath $INSTDIR ; for working directory
  CreateShortCut "$INSTDIR\ShutdownScheduler.lnk" "$INSTDIR\ShutdownScheduler.exe"

!ifdef notefile
  CreateShortCut "${startmenu}\Release Notes.lnk "$INSTDIR\${notefile}"
!endif
 
!ifdef helpfile
  CreateShortCut "${startmenu}\Documentation.lnk "$INSTDIR\${helpfile}"
!endif
 
!ifdef website
WriteINIStr "${startmenu}\web site.url" "InternetShortcut" "URL" ${website}
 ; CreateShortCut "${startmenu}\Web Site.lnk "${website}" "URL"
!endif
 
!ifdef notefile
ExecShell "open" "$INSTDIR\${notefile}"
!endif

;Create uninstall shortcut:
CreateShortCut "${startmenu}\Uninstall.lnk "$INSTDIR\${uninstaller}"

;Set full access permissions on Installation folder:
;IMPORTANT NOTE: Install the NSIS AccessControl plugin in order to utilize the following function:
AccessControl::GrantOnFile "$INSTDIR" "(S-1-1-0)" "FullAccess"

!ifdef filetoexec
ExecWait "$INSTDIR\${filetoexec}"
!endif

SectionEnd
 
;--------------------------------------------------------------
; Uninstaller
; All section names prefixed by "Un" will be in the uninstaller
 
UninstallText "This will uninstall ${prodname}."
 
!ifdef icon
UninstallIcon "${icon}"
!endif
 
Section "Uninstall"
 
  DeleteRegKey HKLM "${uninstkey}"
  DeleteRegKey HKLM "${regkey}"
 
  Delete "${startmenu}\*.*"
  RMDir "${startmenu}"

;Delete desktop shortuct:
Delete "$DESKTOP\${prodname}.lnk"

!ifdef licensefile
Delete "$INSTDIR\${licensefile}"
!endif
 
!ifdef notefile
Delete "$INSTDIR\${notefile}"
!endif
 
!ifdef icon
Delete "$INSTDIR\${icon}"
!endif
 
Delete "$INSTDIR\${exec}"

Delete $INSTDIR\ShutdownScheduler.lnk"

;--------------------------------------------------------
; any application-specific files  **Make sure all files in File List are also listed here::
Delete "$INSTDIR\${file1}"
Delete "$INSTDIR\${file2}"
Delete "$INSTDIR\${file3}"
Delete "$INSTDIR\${file4}"
Delete "$INSTDIR\${file5}"
Delete "$INSTDIR\${file6}"
Delete "$INSTDIR\${file7}"

;--------------------------------------------------------
 
;Delete installer:
Delete "$INSTDIR\${uninstaller}"
 
;Delete install folder:
RMDir $INSTDIR
 
SectionEnd