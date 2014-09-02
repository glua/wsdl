@echo off

set WSID=NULL_AND_VOID

echo Please Confirm. Is everything ready?

pause
"../../../bin/gmad" create -folder . -out packaged.gma
"../../../bin/gmpublish" update -addon packaged.gma -id %WSID%
del packaged.gma
pause