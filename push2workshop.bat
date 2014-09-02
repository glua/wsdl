@echo off

set WSID=309020990

echo Please Confirm. Is everything ready?

pause
"../../../bin/gmad" create -folder . -out packaged.gma
"../../../bin/gmpublish" update -addon packaged.gma -id %WSID%
del packaged.gma
pause