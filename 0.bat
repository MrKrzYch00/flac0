@echo off

REM We are obviously assuming some things with this code here as it was never meant to cover all forms of operator's stupidity.
REM It was also never meant to be beautiful but of function, a kind of proof-of-concept on flac file size optimization.
REM -
REM Simply, put all bat files in some subdir of flac, including the flac file to process itself.
REM Run this script as so: script_name.bat "flacfile.flac" with CMD from that subdir.
REM .wav extension should work too.
REM -
REM It should fast check for best block size to use (88 attempts, 6 threads), parse that and run very slow flac encode with that block size.
REM -
REM In case it fails to reduce the size, this may be a sign that you may need varying block size, a sign that flacout will win this race.
REM -
REM After using flacout (if you decide to do so), make sure to copy tags with:
REM metaflac --no-utf8-convert --export-tags-to=- "origfile" | metaflac --remove-all-tags --dont-use-padding --import-tags-from=- "flacoutfile"
REM (if original has images inside, you may need to copy that too) then add seektable for the flacout's flac to be nice:
REM metaflac --add-seekpoint=10s flacoutfile
REM Edit the file with some tool like Xvi32 and alter the reference to be something like: "reference flacout block: vary"
REM so you know the file was parsed with flacout and the block size is not of fixed size.
REM Finally alter the date of the file manually if you want to keep the original file's date after processing.
REM -
REM WARNING! We are working with lax subset here, for storage and somewhat still-common-sense compatibility.
REM Use at your own risk, obviously. Edit to your liking.
REM ~~~~
REM Mr_KrzYch00

IF NOT EXIST %1 GOTO :EOF

set dire=!outfast-%~1
mkdir "%dire%"

copy /Y "%~1" "%dire%\[ORIGINAL] %~1"

@echo on
start /AFFINITY 0x1 0_1.bat "%~1" "%dire%" "404 63488 496 52224 512 51712 516 2784 16896 1584 16640 1600 16512 1616 16384" 1
start /AFFINITY 0x4 0_1.bat "%~1" "%dire%" "51200 520 50688 528 45056 576 44544 1632 15872 1984 13056 2048 12928 2064 6464" 2
start /AFFINITY 0x10 0_1.bat "%~1" "%dire%" "696 33792 704 36864 792 33280 800 12800 2080 12672 2112 11264 2304 11136 64512" 3
start /AFFINITY 0x40 0_1.bat "%~1" "%dire%" "32768 808 31744 816 33024 992 9216 2816 8448 3168 8320 3200 8256 5568" 4
start /AFFINITY 0x100 0_1.bat "%~1" "%dire%" "1024 25856 14080 1032 25600 1040 25344 3232 8192 3264 7936 3968 6528 4096" 5
start /AFFINITY 0x400 0_1.bat "%~1" "%dire%" "1056 22528 1152 22272 1392 18432 1408 26112 4128 6400 4160 6336 4224 5632 4608" 6
@echo off

:LOOP
timeout /T 3 /NOBREAK >nul 2>&1

SET /A runningprocesses=0
FOR %%a IN ("%~n1.?.txt") DO CALL :IS_RUNNING "%%a"

IF %runningprocesses% EQU 0 GOTO :DONE
echo %runningprocesses% still running, waiting . . .

GOTO :LOOP


:IS_RUNNING
SET /A runningprocesses+=1
GOTO :EOF


:DONE
echo All processes finished...

set /A smallestfilesize=-1
set smallestfilename=NULL

FOR %%a IN ("%dire%\[TEST*.flac") DO CALL :CHECK "%%a"
set block=
set smallestfilename=%smallestfilename:"=%
set temp=%smallestfilename:~5,5%
FOR /L %%a IN (0,1,4) DO CALL :EXTRACTBLOCK %%a
echo Smallest: %smallestfilename% - %smallestfilesize%, best block: %block%
move "%dire%\%smallestfilename%.flac" "%smallestfilename%.flac"
rmdir /s /q "%dire%"
@echo on
call 0_2.bat "%~1" %block%
@echo off

GOTO :EOF

:CHECK
set /A curSize=%~z1
IF %smallestfilesize% EQU -1 (
    IF NOT %curSize% EQU 0 (
        set /A smallestfilesize=%curSize%
        set smallestfilename="%~n1"
    )
) ELSE (
    IF %curSize% LEQ %smallestfilesize% (
        set /A smallestfilesize=%curSize%
        set smallestfilename="%~n1"
    )
)
GOTO :EOF

:EXTRACTBLOCK
CALL SET "_testnum=%%temp:~%1,1%%"
FOR /L %%a IN (0,1,9) DO (
  IF %_testnum%==%%a GOTO :OK
)
GOTO :NOTOK
:OK
    SET block=%block%%_testnum%
:NOTOK
GOTO :EOF