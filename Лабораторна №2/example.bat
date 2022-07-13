@echo off
if not exist "%~1" (echo %date% %time%: Log file with name "%~1" was created >> "%~1") else (echo %date% %time%: Log file with name "%~1" was opened >> "%~1")
echo Previous time: %date% %time% >> "%~1"
w32tm /resync
echo Synchronized time: %date% %time% >> "%~1"
tasklist >> "%~1"

tasklist | find "%~3"
if %ERRORLEVEL% equ 0 (
  taskkill /f /im %~3
  echo "%~3 is killed" >> "%~1"
) else (
  echo "%~3 was not killed" >> "%~1"
)

SET /a DELETED_FILES = 0
echo %date% %time%: All processes "%~3" were killed >> "%~1"
for /r %~2 %%g in (*.tmp, temp*.*)do (
  SET /a DELETED_FILES=DELETED_FILES+1
  del "%%g"
  echo %date% %time%: File "%%g" was deleted >>"%~1"
)
if %DELETED_FILES% gtr 0 (
  echo %date% %time%: Amount of deleted files: %DELETED_FILES% >> "%~1"
  ) else (echo %date% %time%: No files were deleted >> "%~1"
)
set CURRENT_HH=%time:~0,2%
if %CURRENT_HH% lss 10 (set CURRENT_HH=0%time:~1,1%)
set CURENT_MINUTES=%time:~3,2%
set CURRENT_SECONDS=%time:~6,2%
"C:\Program Files (x86)\WinRAR\Rar.exe" a -r "%date%_%CURRENT_HH%-%CURENT_MINUTES%-%CURRENT_SECONDS%.rar" "%~2\*"
echo %date% %time%: Archieve all files whch corresponds to "%~2" >>"%~1"
move "%date%_%CURRENT_HH%-%CURENT_MINUTES%-%CURRENT_SECONDS%.rar*" "%~4"
echo %date% %time%: Moving of created archieve to specified path: "%~4" >>"%~1"
forfiles /p "%~4" /s /d 1 /c "cmd /c echo @file" >> "%~1"
if "%ERRORLEVEL%" equ "0" (
  echo %date% %time%: There is archieve for yesterday >> "%~1"
) else (
  echo %date% %time%: There is NOT archieve for yesterday >> "%~1"
  echo %date% %time%: There is NOT archieve for yesterday. Please, check confifuration of your script. >>"ForEmail.txt"
)
forfiles /p "%~4" /s /d -30 /c "/c del @file""
if "%ERRORLEVEL%" equ "0" (
  echo %date% %time%: Archieves which were older that 30 days were removed >> "%~1"
) else (
  echo %date% %time%: There are not archieves which are older that 30 days >> "%~1"
)

ping google.com
if "%ERRORLEVEL%" equ "0" (
  echo %date% %time%: Internet connection is established >> "%~1"
) else (
  echo %date% %time%: No Internet connection >> "%~1"
)

for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr IPv4') do ( 
  if "%~5" == "%%i" (
    echo %date% %time%: Computer with specified IP in LAN was found >> "%~1"
    shutdown /s /c "This machine is turning off" /m \\"%~5"  >> "%~1"
    echo %date% %time%: Computer with specified IP: %~5 will be turned off in 30 seconds >> "%~1"
  ) else (
    echo %date% %time%: Computer with specified IP: %~5 in LAN was NOT found >> "%~1"
  )
)

setlocal ENABLEDELAYEDEXPANSION
for /f "tokens=1" %%i in ('arp -a') do (
  for /f %%a in ('ping -w 500 -n 1 %%i ^|find /c "Reply from %%i"') do  set RESULT=%%a
  if "!RESULT!" equ "1" (
    echo %date% %time%: Computer with IP: %%i was found in LAN >> "%~1"
  )
)
endlocal

setlocal ENABLEDELAYEDEXPANSION
for /f %%i in (ipon.txt) do ( 
  set COMPUTER_WAS_FOUND=0
  for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr IPv4') do (
    if " %%i" == "%%a" (
      set /a COMPUTER_WAS_FOUND=!COMPUTER_WAS_FOUND!+1
    )
  )
  if !COMPUTER_WAS_FOUND! equ 0 (
    echo %date% %time%: %%i was NOT found in LAN >> "%~1"
    echo %date% %time%: %%i was NOT found in LAN >> "ForEmail.txt"
  )
)
endlocal

set ALLOWED_SIZE=%~6

for /f "usebackq" %%A in ('%~1') do set FILE_SIZE=%%~zA
if %FILE_SIZE% lss %ALLOWED_SIZE% (
  echo %date% %time%: The size of log file is LESS than maximum limit >> "%~1"
  echo %date% %time%: The size of log file is LESS than maximum limit >> "ForEmail.txt"
) else (
  echo %date% %time%: The size of log file is MORE than maximum limit >> "%~1"
  echo %date% %time%: The size of log file is MORE than maximum limit >> "ForEmail.txt"
)

setlocal ENABLEDELAYEDEXPANSION
set COUNT=0

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

set CURRENT_HH=%time:~0,2%
if %CURRENT_HH% lss 10 (set CURRENT_HH=0%time:~1,1%)
set CURENT_MINUTES=%time:~3,2%
set CURRENT_SECONDS=%time:~6,2%
systeminfo >> "systeminfo+%date%_%CURRENT_HH%-%CURENT_MINUTES%-%CURRENT_SECONDS%.txt"