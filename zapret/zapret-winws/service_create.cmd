set ARGS=^
--wf-tcp=80,443 --wf-udp=443,50000,50100 ^

call :srvinst zapret
goto :eof

:srvinst
net stop %1
sc delete %1
sc create %1 binPath= "\"%~dp0winws.exe\" %ARGS%" DisplayName= "zapret DPI bypass : %1" start= auto
sc description %1 "zapret DPI bypass software"
sc start %1
