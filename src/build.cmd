set OLDDIR=%CD%
call makeFlatSols
cd ..\compile
call generate_contract_java_wrapper.bat
chdir /d %OLDDIR% &rem restore current directory