;TrayScheduler.ahk
;8/25/2011 JDunne Built from scratch

#Include StdoutToVar.ahk

;Start of script:
	#Persistent
	#SingleInstance,Force
	SetBatchLines,-1										;set script to run at maximum speed... (otherwise -1 is replaced by a time, ex: 20ms)
	AutoTrim,Off
	Gosub,READINI											;initialize variables by reading/creating an ini file.
	Gosub,TRAYMENU											;create the system tray menu	
;stdoutToVar.ahk usage example:
;	sOutput := StdoutToVar_CreateProcess("ipconfig.exe /all")
;	MsgBox % sOutput

;Determine if the scheduled process exists:
	GoSub,CHECKSCHEDULER

	;Example of adding time:
	;TimeInSeconds := TimeToSeconds(A_Now)
	;TimeInSeconds += 15
	;NewTime := SecondsToTimeStamp(TimeInSeconds)
	;FormatTime, Now, %NewTime%, HH:mm:ss
	;FormatTime, RightNow,, HH:mm:ss		
	;msgbox % RightNow . "    " . Now

Return													;exit initialization of the script (it doesn't exit until Quit is called)
		
	SecondsToTimeStamp(NumberOfSeconds)
	{
		;A_Now is in the following format: YYYYMMDDHH24MISS, (Which is the timestamp format that FormatTime accepts
		;MM: Month 01
		;DD: Day 01
		;HH24: Hour 00
		;MI: Minute 00
		;SS: Second 00

		myNewTime := substr(A_Now,1,8)
		;myNewTime is a timestamp variable, and it can be added to a specified number of seconds by adding ", seconds" to the end.
		myNewTime += %NumberOfSeconds%, seconds
		return myNewTime
	}

	TimeToSeconds(InputTime)
	{
		FormatTime, Secs, %InputTime%, ss
		FormatTime, mins, %InputTime%, mm
		FormatTime, Hrs, %InputTime%, HH
		
		return Secs + mins*60 + Hrs*3600
	}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;Initialize the system tray menu:
TRAYMENU:
	Menu,Tray,NoStandard 
	Menu,Tray,DeleteAll 
	Menu,Tray,Add,&Enable Scheduled Shutdown, ENABLESCHEDULE
	Menu,Tray,Add,&Disable Scheduled Shutdown, DISABLESCHEDULE
	Menu,Tray,Add,&Show Windows Scheduler, SHOWSCHEDULER
	Menu,Tray,Add,&Show Log, SHOWLOG
	Menu,Tray,Add,
	Menu,Tray,Add,&Help,HELP
	Menu,Tray,Add,Se&ttings,SETTINGS
	Menu,Tray,Add,R&eload settings,RELOAD
	Menu,Tray,Add,&Quit,QUIT
	;Menu,Tray,Default,TrayScheduler
Return

ENABLESCHEDULE:

;Determine if the scheduled process exists:
	sOutput := StdoutToVar_CreateProcess("schtasks /query")
	if (instr(sOutput, "Tray Scheduled Shutdown") != 0)
	{
		;StringReplace, Line, Line, %TwoTabs%, %A_Tab%
		;MsgBox % "Scheduled Process exists.  Remaking it with the current settings..."
		GoSub,DISABLESCHEDULE
	}
	else
	{
		;MsgBox % "Scheduled Process Does not exist.  Creating it.."
	}

	FormatTime, TodaysDate,,MM/dd/yyyy
	;msgbox % TodaysDate
	
	;Add 15 seconds to Now:
	TimeInSeconds := TimeToSeconds(A_Now)
	TimeInSeconds += 60
	NewTime := SecondsToTimeStamp(TimeInSeconds)
	FormatTime, myTimeOfDay, %NewTime%, HH:mm:ss

	;Problem is I think this needs to be run as an administrator: (otherwise I need to specify my user name and password..)
	CmdLine := "schtasks /create /SC WEEKLY /D " . DaysOfWeek . " /TN ""Tray Scheduled Shutdown"" /ST " . TimeOfDay . " /SD " . TodaysDate . " /TR \""" . PathToExecutable . "\"" " . OtherOptions
	
	;Special test version, which runs within 60 seconds:
	;myDaysOfWeek := "SUN,MON,TUE,WED,THU,FRI,SAT"
	;CmdLine := "schtasks /create /SC WEEKLY /D " . myDaysOfWeek . " /TN ""Tray Scheduled Shutdown"" /ST " . myTimeOfDay . " /SD " . TodaysDate . " /TR \""" . PathToExecutable . "\"" " . OtherOptions
	
	;msgbox % CmdLine
	sOutput := StdoutToVar_CreateProcess(CmdLine)
	
	MsgBox % sOutput
	
	;Update icon:
	GoSub,CHECKSCHEDULER
	
Return

DISABLESCHEDULE:
	sOutput := StdoutToVar_CreateProcess("schtasks /query")
	if (instr(sOutput, "Tray Scheduled Shutdown") != 0)
	{
		;StringReplace, Line, Line, %TwoTabs%, %A_Tab%
		;MsgBox % "Scheduled Process exists.  Deleting it now..."
		sOutput := StdoutToVar_CreateProcess("schtasks /delete /TN ""Tray Scheduled Shutdown"" /f")
		MsgBox % sOutput
	}
	else
	{
		;MsgBox % "Nothing to do. Process doesn't exist."
	}

	;Update icon:
	GoSub,CHECKSCHEDULER

Return

SHOWSCHEDULER:
	;Open task scheduler:
	Run % "control.exe  schedtasks"
Return

SHOWLOG:
	Run,shutdownscheduler.log
Return

CHECKSCHEDULER:
	sOutput := StdoutToVar_CreateProcess("schtasks /query")
	if (instr(sOutput, "Tray Scheduled Shutdown") != 0)
	{
		Menu, Tray, Icon, ShutdownDownEnabled.ico
	}
	else 
	{
		Menu, Tray, Icon, ShutdownDownDisabled.ico
	}
Return

SETTINGS:
	Gosub,READINI
	Run,TrayScheduler.ini
Return


RELOAD:
	Reload


READINI:
	IfNotExist,TrayScheduler.ini								;Generate INI file if it doesn't already exist:
	{
		ini=;TrayScheduler.ini
		ini=%ini%`n;[Settings]
		ini=%ini%`n;DaysOfWeek=SUN,MON,TUE,WED,THU							`;Comma separated list of which days of the week to run this
		ini=%ini%`n;TimeOfDay=23:59:59										`;24 hour time of day to run the scheduled application.
		ini=%ini%`n;PathToExecutable=C:\Progra~2\JoesTo~1\System~1\Shutdo~1.lnk			`;Path to executable to run (must be a .lnk file AND must use 8.3 extension format)
		ini=%ini%`n;OtherOptions=/ru DOMAIN\username /rp password			`;Any other command line options needed

		ini=%ini%`n
		ini=%ini%`n[Settings]
		ini=%ini%`nDaysOfWeek=SUN,MON,TUE,WED,THU
		ini=%ini%`nTimeOfDay=23:59:59
		ini=%ini%`nPathToExecutable=C:\Progra~2\JoesTo~1\System~1\Shutdo~1.lnk
		ini=%ini%`n;OtherOptions=

		FileAppend,%ini%,TrayScheduler.ini
		ini=
	}

	;Read each ini setting:

	IniRead,DaysOfWeek,TrayScheduler.ini,Settings,DaysOfWeek
	IniRead,TimeOfDay,TrayScheduler.ini,Settings,TimeOfDay
	IniRead,PathToExecutable,TrayScheduler.ini,Settings,PathToExecutable
	IniRead,OtherOptions,TrayScheduler.ini,Settings,OtherOptions


Return


HELP:
	about=Tray Scheduler
	about=%about%`n
	about=%about%`nThis program 

	about=%about%`nJoe Dunne 2011.
	MsgBox,0,Tray Scheduler,%about%
	about=
Return


QUIT:
	ExitApp

