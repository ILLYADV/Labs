@echo off
chcp 1251
if not exist "%~1" (echo %date% %time%: Log was created > "%~1") else (echo %date %time%: Log was opened >> "%~1")

echo Current time: %date% %time% >> "%~1"
w32tm /resync
echo Synchronized time: %date% %time% >> "%~1"

echo %date% %time%: Executed batch file with parameters: log file - "%~1", directory to archive - "%~2", processes to kill ^
- "%~3", directory to store archive - "%~4", computer with IPv4 to find and stop - "%~5", allowed size of log file - "%~6" >> "%~1"

echo %date% %time%: Logging all tasks >> "%~1"
tasklist >> "%~1"

echo %date% %time%: Terminating "%~3" >> "%~1"
tasklist | find "%~3" >> "%~1"
if %ERRORLEVEL% equ 0 (
    taskkill /f /im "%~3"
    echo %date% %time%: %~3 was terminated >> "%~1"
) else echo %date% %time%: %~3 was not found >> "%~1"

set /a del_files = 0
dir "%~2" >> "%~1"
for /r "%~2" %%f in (*.tmp, temp*.*) do (
    del /F "%%f"
    if %ERRORLEVEL% equ 0 (
	set /a del_files += 1
        echo %date% %time%: %%f was deleted >> "%~1"
    ) else (
	echo %date% %time%: %%f was not deleted >> "%~1"
    )
)
if %del_files% neq 0 (
    echo %date% %time%: Deletion of temporary files successful, number of files: %del_files% >> "%~1"
) else echo %date% %time%: No files found >> "%~1"

set hours=%time:~0,2%
if %hours% lss 10 set hours=0%time:~1,1%
set minutes=%time:~3,2%
set seconds=%time:~6,2%

echo %date% %time%: Starting archiving "%~2" into %~4 >> "%~1"
set archive=%date%_%hours%-%minutes%-%seconds%.rar
dir "%~2"
"C:\Program Files (x86)\WinRAR\RAR.exe" a -r -ep1 %archive% "%~2\*.*"
move "%archive%" "%~4"
echo %date% %time%: Created archive of "%~2" in "%~4" >> "%~1"

echo %date% %time%: Checking archives older than 30 days at "%~4" >> "%~1"
forfiles /p "%~4" /s /d -30 /c "del @file"
if "%ERRORLEVEL%" equ "0" (
    echo %date% %time%: Archieves older than 30 days were deleted >> "%~1"
) else (
    echo %date% %time%: No archieve older that 30 days found >> "%~1"
)

ping google.com
if "%ERRORLEVEL%" equ "0" (
    echo %date% %time%: Internet connection is established >> "%~1"
) else (
    echo %date% %time%: No Internet connection >> "%~1"
)

echo %date% %time%: Checking computers with IP "%~5" >> "%~1"
set isFound=false
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr IPv4) do (
    if "%~5" == "%%i" (
	set isFound=true
	echo %date% %time%: Computer was found >> "%~1"
	shutdown /s /c "Turning off the machine" /m \\"%~5" >> "%~1"
    )
)
if %isFound% == false (
    echo %date% %time%: Computer was not found >> "%~1"
)

echo %date% %time%: Looking for "%~5" in ARP >> "%~1"
setlocal ENABLEDELAYEDEXPANSION
for /f "tokens=1" %%i in ('arp -a') do (
    for /F %%a in ('ping -w 500 -n 1 %%i ^| find /c "Reply from %%i"') do set result=%%a
    if "!result!" equ "1" (
	echo %date% %time%: Computer with IP: %%i was found in LAN >> "%~1"
    ) else (
	echo %date% %time%: Computer with IP: %%i was not found in LAN >> "%~1"
    )
)
endlocal

echo %date% %time%: Looking for computers with IPs from ipon.txt >> "%~1"
setlocal ENABLEDELAYEDEXPANSION
for /f %%i in (ipon.txt) do ( 
    set /a computersWereFound=0
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr IPv4') do (
	if " %%i" == "%%a" (
	    set /a computersWereFound=!computersWereFound!+1
	)
    )
    if !COMPUTER_WAS_FOUND! equ 0 (
	echo %date% %time%: %%i was NOT found in LAN >> "%~1"
	echo %date% %time%: %%i was NOT found in LAN >> "ForEmail.txt"
    )
)
endlocal

set allowedSize=%~6
echo %date% %time%: Checking size of "%~1" file >> "%~1"
for /f "usebackq" %%A in ('%~1') do set fileSize=%%~zA
if %fileSize% lss %allowedSize% (
    echo %date% %time%: The size of "%~1" is LESS than maximum limit >> "%~1"
    echo %date% %time%: The size of "%~1" is LESS than maximum limit >> "ForEmail.txt"
) else (
    echo %date% %time%: The size of "%~1" is MORE than maximum limit >> "%~1"
    echo %date% %time%: The size of "%~1" is MORE than maximum limit >> "ForEmail.txt"
)

setlocal ENABLEDELAYEDEXPANSION
set COUNT=0
echo %date% %time%: Checking free, used and total space of all disks >> "%~1"

for /f "tokens=1-3" %%a in ('WMIC LOGICALDISK GET FreeSpace^,Name^,Size ^|FINDSTR /I /V "Name"') do (
    set /a COUNT=COUNT + 1

    if !COUNT! leq 1 (
	set TOTAL_SPACE=%%c
	set FREE_SPACE=%%a
	set Name=%%b

	set /a F_TOTAL_SPACE=!TOTAL_SPACE:~0,-4! / 1074
	set /a F_FREE_SPACE=!FREE_SPACE:~0,-4! / 1074
	set /a USED_SPACE=!F_TOTAL_SPACE!-!F_FREE_SPACE!
	set F_TOTAL_SPACE=!F_TOTAL_SPACE:~0,-2!,!F_TOTAL_SPACE:~-2! GB
	set F_FREE_SPACE=!F_FREE_SPACE:~0,-2!,!F_FREE_SPACE:~-2! GB
	set F_USED_SPACE=!USED_SPACE:~0,-2!,!USED_SPACE:~-2! GB

	echo %date% %time%: Name: !NAME! >> "%~1"
	echo %date% %time%: Free Space: !F_FREE_SPACE! >> "%~1"
	echo %date% %time%: Used Space: !F_USED_SPACE! >> "%~1"
	echo %date% %time%: Total space: !F_TOTAL_SPACE! >> "%~1"
    )
)
endlocal

set hours=%time:~0,2%
if %hours% lss 10 set hours=0%time:~1,1%
set minutes=%time:~3,2%
set seconds=%time:~6,2%
systeminfo >> "systeminfo+%date%_%CURRENT_HH%-%CURENT_MINUTES%-%CURRENT_SECONDS%.txt"