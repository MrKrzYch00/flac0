@echo off

copy /y NUL "%~n1.%4.txt"

set list=%~3

FOR %%a IN (%list%) DO (
  ..\flac "%~2\[ORIGINAL] %~1" -o "%~2\[TEST%%a] %~n1.flac" -0 -mep -r 15 -P 0 -b %%a --lax -f
)

del "%~n1.%4.txt"

exit