@echo off
setlocal ENABLEDELAYEDEXPANSION
REM DoDownloadNetFile-Bat
REM ���������ļ���ָ��URL�������ݲ����������ļ�����Ӧ����
REM V0.1, 20161204

REM �����Զ�������ģʽ(��˴������������ٶ�ȡConfig)
	REM ���ص�ַ
	set URL=
	REM ����·��
	set TARGET_DIR=
	REM ������Ϻ��Ƿ�ִ��, ��: true, ��: false
	set IS_RUN=
	REM ������Ϻ�ִ����ʱ, ������ҪIS_RUN����״̬, Ĭ��Ϊ0/s
	set RUN_DELAY=

REM ��ȡ�������
REM %1-URL, %2-TARGET_DIR, %3-IS_RUN, %4-RUN_DELAY
if defined URL goto checkConfig
	REM ���ص�ַ
	set "URL=%~1"
	REM ����·��
	set "TARGET_DIR=%~2"
	REM ������Ϻ��Ƿ�ִ��, ��: true, ��: false
	set "IS_RUN=%~3"
	REM ������Ϻ�ִ����ʱ, ������ҪIS_RUN����״̬, Ĭ��Ϊ0/s
	set "RUN_DELAY=%~4"

REM ��ȡ�����ļ�
REM 	������ǰĿ¼��`%bat�ļ�������(��������չ��)%.ini`
REM 		e.g. DoDownloadNetFile.bat -> DoDownloadNetFile.ini
if defined URL goto checkConfig
set "configFile=%~dpn0.ini"
if not exist "%configFile%" exit/b 1
	REM URL
	call:Properties_Read "%configFile%" "URL" "URL"
	if not "%errorlevel%"=="0" exit/b 1
	REM TARGET_DIR
	call:Properties_Read "%configFile%" "TARGET_DIR" "TARGET_DIR"
	REM IS_RUN
	call:Properties_Read "%configFile%" "IS_RUN" "IS_RUN"
	REM RUN_DELAY
	call:Properties_Read "%configFile%" "RUN_DELAY" "RUN_DELAY"

REM ����У��
:checkConfig
	REM URL
	if not defined URL exit/b 1
	if "%URL%"=="" exit/b 1
	REM TARGET_DIR
	if not defined TARGET_DIR set "TARGET_DIR=%temp%\tmp_%random%_%random%.exe"
	if "%TARGET_DIR:~-1%"=="\" (
		if exist "%TARGET_DIR%" (
			set "TARGET_DIR=%TARGET_DIR%tmp_!random!_!random!.exe"
		) else set "TARGET_DIR=%temp%\tmp_!random!_!random!.exe"
	) else if exist "%TARGET_DIR%" if exist "%TARGET_DIR%\" set "TARGET_DIR=%temp%\tmp_!random!_!random!.exe"
	REM IS_RUN
	if defined IS_RUN if /i not "%IS_RUN%"=="true" set "IS_RUN=false"
	REM RUN_DELAY
	if not defined RUN_DELAY set "RUN_DELAY=0"
	call:DefinedNoNumberString "%RUN_DELAY%"
	if not "%errorlevel%"=="1" set "RUN_DELAY=0"

REM ��ʼ����
	call:DownloadNetFile "%URL%" "%TARGET_DIR%"
	if not "%errorlevel%"=="0" exit/b 1
	
	if /i not "%IS_RUN%"=="true" exit/b 0
	
	REM ping -n %RUN_DELAY% 127.0.0.1 >nul 2>nul
	ping -n %RUN_DELAY% 127.0.0.1 >nul 2>nul
	start "" "%TARGET_DIR%"
	exit/b 0


REM :--------------------------�ӳ���ʼ����----------------------------:
goto end

REM �жϱ������Ƿ��з������ַ� call:DefinedNoNumberString ���ж��ַ�
REM	����ֵ0�����з������ַ�������ֵ1�����޷������ַ�������ֵ2�������Ϊ��
REM �汾��20151231
:DefinedNoNumberString
REM �ж��ӳ�������������
if "%~1"=="" exit/b 2

REM ��ʼ���ӳ����������
for %%B in (DefinedNoNumberString) do set %%B=
set DefinedNoNumberString=%~1

REM �ӳ���ʼ����
for /l %%B in (0,1,9) do (
	set DefinedNoNumberString=!DefinedNoNumberString:%%B=!
	if not defined DefinedNoNumberString exit/b 1
)
exit/b 0


REM call:DownloadNetFile ��ַ ·�����ļ���
REM ���������ļ� �汾��20160114
:DownloadNetFile
REM ����ӳ���ʹ�ù�����ȷ���
if "%~2"=="" (
	echo=	#[Error %0:����2]�ļ�·�����ļ���Ϊ��
	exit/b 1
) else if "%~1"=="" (
	echo=	#[Error %0:����1]��ַΪ��
	exit/b 1
)

REM ��ʼ���ӳ����������
for %%- in (downloadNetFileTempPath downloadNetFileUrl downloadNetFileCachePath) do if defined %%- set %%-=
set downloadNetFileTempPath=%temp%\downloadNetFileTempPath%random%%random%%random%.vbs
set downloadNetFileUrl="%~1"
set downloadNetFileUrl="%downloadNetFileUrl:"=%"
set downloadNetFileFilePath=%~2

REM ���ɶ����ű�
(
	echo=Set xPost = CreateObject^("Microsoft.XMLHTTP"^)
	echo=xPost.Open "GET",%downloadNetFileUrl%,0
	echo=xPost.Send^(^)
	echo=Set sGet = CreateObject^("ADODB.Stream"^)
	echo=sGet.Mode = 3
	echo=sGet.Type = 1
	echo=sGet.Open^(^)
	echo=sGet.Write^(xPost.responseBody^)
	echo=sGet.SaveToFile "%downloadNetFileFilePath%",2
)>"%downloadNetFileTempPath%"

REM ɾ��IE�����������ݵĻ���
for /f "tokens=3,* skip=2" %%- in ('reg query "hkcu\software\microsoft\windows\currentversion\explorer\shell folders" /v cache') do if "%%~."=="" (set downloadNetFileCachePath=%%-) else set downloadNetFileCachePath=%%- %%.
for /r "%downloadNetFileCachePath%" %%- in ("%~n1*") do if exist "%%~-" del /f /q "%%~-"

REM ���нű�
cscript //b "%downloadNetFileTempPath%"

REM ɾ����ʱ�ļ�
if exist "%downloadNetFIleTempPath%" del /f /q "%downloadNetFIleTempPath%"

REM �жϽű����н��
if exist "%downloadNetFileFilePath%" (exit/b 0) else exit/b 1

REM Properties_Tool_20161204�汾
REM :------------------------------------------------------------Properties_Read------------------------------------------------------------------------------------:
REM Propertiesģʽ��ȡ����(key��value֮��ʹ���Ʊ���ָ�ģʽ)
REM call:Properties_Read "�ļ�·��" "keyName" "�������ݱ�����"
REM ���ӣ����ļ� "config.ini" �ж�ȡkeyΪphoneNumber�����ݵ�����mobilePhoneNumber��
REM 		call:Properties_Read "config.ini" phoneNumber mobilePhoneNumber
REM ����ֵ����: 0-��ȡ�ɹ�, 1-���޴�key(������), 2-��������
REM ��ע: ���ӳ�����Ҫ�ӳ��� Database_Find, Database_Read
:Properties_Read

REM ����key�Ƿ����ļ��д���
set p_r_find_result=
call:Database_Find /Q /i /first "%~1" "	" "%~2" 0 1 p_r_find_result
if "%errorlevel%"=="1" exit/b 1
if "%errorlevel%"=="2" exit/b 2

REM ���ҵ��Ļ����ȡ��ȡ�����к�
set p_r_find_line=
for %%a in (%p_r_find_result%) do for /f "tokens=1,2" %%b in ("%%~a") do (
	set p_r_find_line=%%b
)

REM ��ȡ����key�������ݲ�����
call:Database_Read /Q "%~1" "	" "%p_r_find_line%" 2 "%~3"
exit/b %errorlevel%

REM (�������ı����ݿ⹤����)Database_Tools_20160625�汾
REM :--------------------------------------------------------------------Database_Read-------------------------------------------------------------------------------:
REM ��ָ���ļ���ָ���С�ָ���ָ�����ָ���л�ȡ���ݸ�ֵ��ָ������
REM call:Database_Read [/Q(����ģʽ������ʾ����)] "����Դ�ļ�" "�����зָ���" "����������" "�Էָ���Ϊ�ָ��N������(��Ŀ������Ŀ��֮��ʹ��,�ָ�ҿ�������ָ��-)" "������������(�������֮��ʹ�ÿո��,���зָ�)"
REM ���ӣ����ļ� "c:\users\a\Database.ini" �н��� "	" Ϊ�ָ����ĵ�4�����ݵĵ�1,2,3,6�����ݷֱ�ֵ��var1,var2,var3,var4
REM					call:Database_Read "c:\users\a\Database.ini" "	" "4" "1-3,6" "var1 var2 var3 var4"
REM ����ֵ���飺0-����������1-���޴��У�2-�����������ӳ���
REM ע�⣺����ֵ���ֻ֧�ֵ�31�У��Ƽ��ڴ������ݵ�ʱ��ʹ���Ʊ��"	"Ϊ�ָ������Է��������ݺͷָ�������,�ı����ݿ��в�Ҫ���п��кͿ�ֵ����ֹ�������ݴ���
REM �汾:20151127
:Database_Read
REM ����ӳ������л����������
set "d_R_ErrorPrint="
if /i "%~1"=="/q" (shift/1) else set "d_R_ErrorPrint=Yes"
if "%~5"=="" (
	if defined d_R_ErrorPrint echo=	[����%0:����5-ָ������ֵ������Ϊ��]
	exit/b 2
)
if "%~4"=="" (
	if defined d_R_ErrorPrint echo=	[����%0:����4-ָ����Ŀ��Ϊ��]
	exit/b 2
)
if "%~3"=="" (
	if defined d_R_ErrorPrint echo=	[����%0:����3-ָ���к�Ϊ��]
	exit/b 2
)
if %~3 lss 1 (
	if defined d_R_ErrorPrint echo=	[����%0:����3-ָ���к�С��1:%~3]
	exit/b 2
)
if "%~2"=="" (
	if defined d_R_ErrorPrint echo=	[����%0:����2-ָ���ָ���Ϊ��]
	exit/b 2
)
if "%~1"=="" (
	if defined d_R_ErrorPrint echo=	[����%0:����1-ָ������Դ�ļ�Ϊ��]
	exit/b 2
) else if not exist "%~1" (
	if defined d_R_ErrorPrint echo=	[����%0:����1-ָ������Դ�ļ�������:%~1]
	exit/b 2
)

REM ��ʼ������
for %%_ in (d_R_Count d_R_Pass) do set "%%_="
for /l %%_ in (1,1,31) do if defined d_R_Count%%_ set "d_R_Count%%_="
set /a "d_R_Pass=%~3-1"
if "%d_R_Pass%"=="0" (set "d_R_Pass=") else set "d_R_Pass=skip=%d_R_Pass%"

REM �ӳ���ʼ����
for %%_ in (%~5) do (
	set /a "d_R_Count+=1"
	set "d_R_Count!d_R_Count!=%%_"
)
set "d_R_Count="
for /f "usebackq eol=^ %d_R_Pass% tokens=%~4 delims=%~2" %%? in ("%~1") do (
	for %%_ in ("!d_R_Count1!=%%~?","!d_R_Count2!=%%~@","!d_R_Count3!=%%~A","!d_R_Count4!=%%~B","!d_R_Count5!=%%~C","!d_R_Count6!=%%~D","!d_R_Count7!=%%~E","!d_R_Count8!=%%~F","!d_R_Count9!=%%~G","!d_R_Count10!=%%~H","!d_R_Count11!=%%~I","!d_R_Count12!=%%~J","!d_R_Count13!=%%~K","!d_R_Count14!=%%~L","!d_R_Count15!=%%~M","!d_R_Count16!=%%~N","!d_R_Count17!=%%~O","!d_R_Count18!=%%~P","!d_R_Count19!=%%~Q","!d_R_Count20!=%%~R","!d_R_Count21!=%%~S","!d_R_Count22!=%%~T","!d_R_Count23!=%%~U","!d_R_Count24!=%%~V","!d_R_Count25!=%%~W","!d_R_Count26!=%%~X","!d_R_Count27!=%%~Y","!d_R_Count28!=%%~Z","!d_R_Count29!=%%~[","!d_R_Count30!=%%~\","!d_R_Count31!=%%~]") do (
		set /a "d_R_Count+=1"
		if defined d_R_Count!d_R_Count! set %%_
	)
	exit/b 0
)
if not defined d_R_Count if defined d_R_ErrorPrint echo=	[����%0:���-���޴���:%~3]
exit/b 1


REM :--------------------------------------------------------------------Database_Find-------------------------------------------------------------------------------:
REM ��ָ���ļ���ָ���С�ָ���ָ�����ָ���С�ָ���ַ�����������������������к�д�뵽ָ��������
REM call:Database_Find [/Q(����ģʽ������ʾ����)] [/i(�����ִ�Сд)] [/first(���ز��ҵ��ĵ�һ�����)] "����Դ" "�����зָ���"  "�����ַ���" "����������(֧�ֵ����ָ���,�����������ָ���-,0Ϊָ��ȫ����)" "����������(֧�ֵ����ָ���,�����������ָ���-)" "���ҽ���к��кŽ�����ܸ�ֵ������"
	REM ע�⣺-------------------------------------------------------------------------------------------------------------------------------
	REM 	��������������ʽΪ��"�� ��","�� ��","..."���εݼӣ�����ڶ��е����к͵����е����еĸ�ֵ���ݾ�Ϊ��"2 3","5 6"
	REM 	����ʹ�� 'for %%a in (%�������%) do for /f "tokens=1,2" %%b in ("%%~a") do echo=��%%b�У���%%c��' �ķ������н��ʹ��
	REM -------------------------------------------------------------------------------------------------------------------------------------
REM ���ӣ����ļ� "c:\users\a\Database.ini"�е�����������"	"Ϊ�ָ����ĵ�һ���в����ִ�Сд�Ĳ����ַ���data(��ȫƥ��)����������������кŸ�ֵ������result
REM					call:Database_Find /i "c:\users\a\Database.ini" "	" "data" "3-5" "1" "result"
REM ����ֵ���飺0-����ָ���ַ����ҵ�������Ѹ�ֵ������1-δ���ҵ������2-�����������ӳ���
REM ע�⣺����ֵ���ֻ֧�ֵ�31�У��Ƽ��ڴ������ݵ�ʱ��ʹ���Ʊ��"	"Ϊ�ָ������Է��������ݺͷָ�������,�ı����ݿ��в�Ҫ���п��кͿ�ֵ����ֹ�������ݴ���
REM �汾:20160625
:Database_Find
REM ����ӳ������л����������
for %%A in (d_F_ErrorPrint d_F_Insensitive d_F_FindFirst) do set "%%A="
if /i "%~1"=="/i" (
	set "d_F_Insensitive=/i"
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set "d_F_ErrorPrint=Yes"
if /i "%~1"=="/i" (
	set "d_F_Insensitive=/i"
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set "d_F_ErrorPrint=Yes"

if /i "%~1"=="/first" (
	set d_F_FindFirst=Yes
	shift/1
)

if "%~6"=="" (
	if defined d_F_ErrorPrint echo=	[����%0:����6-ָ�����ܽ��������Ϊ��]
	exit/b 2
)
if "%~5"=="" (
	if defined d_F_ErrorPrint echo=	[����%0:����5-ָ�������к�Ϊ��]
	exit/b 2
)
if "%~4"=="" (
	if defined d_F_ErrorPrint echo=	[����%0:����4-ָ�������к�Ϊ��]
	exit/b 2
)
if "%~3"=="" (
	if defined d_F_ErrorPrint echo=	[����%0:����3-ָ�������ַ���Ϊ��]
	exit/b 2
)
if "%~2"=="" (
	if defined d_F_ErrorPrint echo=	[����%0:����2-ָ�������зָ���Ϊ��]
	exit/b 2
)
if "%~1"=="" (
	if defined d_F_ErrorPrint echo=	[����%0:����1-ָ������Դ�ļ�Ϊ��]
	exit/b 2
) else if not exist "%~1" (
	if defined d_F_ErrorPrint echo=	[����%0:����1-ָ������Դ�ļ�������:%~1]
	exit/b 2
)

REM ��ʼ������
for %%_ in (d_F_Count d_F_StringTest d_F_Count2 d_F_Pass %~6) do set "%%_="
for /f "delims==" %%_ in ('set d_F_AlreadyLineNumber 2^>nul') do set "%%_="
for /f "delims==" %%_ in ('set d_F_Column 2^>nul') do set "%%_="

REM �ӳ���ʼ����
REM �ж��û������к��Ƿ���Ϲ���
set "d_F_StringTest=%~4"
for %%_ in (1,2,3,4,5,6,7,8,9,0,",",-) do if defined d_F_StringTest set "d_F_StringTest=!d_F_StringTest:%%~_=!"
if defined d_F_StringTest (
	if defined d_F_ErrorPrint echo=	[����%0:����4:ָ�������кŲ����Ϲ���:%~4]
	exit/b 2
)

REM ���кŸ�ֵ���б���
for /f "tokens=%~5" %%? in ("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31") do for /f "delims=%%" %%_ in ("%%? %%@ %%A %%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U %%V %%W %%X %%Y %%Z %%[ %%\ %%]") do for %%: in (%%_) do (
	set /a "d_F_Count+=1"
	set "d_F_Column!d_F_Count!=%%:"
)
set "d_F_Count="
REM �����кŽ��в��ִ������
for %%_ in (%~4) do (
	set "d_F_Pass="
	set "d_F_Pass=%%~_"
	if "!d_F_Pass!"=="!d_F_Pass:-=!" (
		if "%%~_"=="0" (
			set "d_F_Count2=0"
			set "d_F_Count=No"
			set "d_F_Pass="
		) else (
			set /a "d_F_Count2=%%~_-1"
			set /a "d_F_Pass=%%~_-1"
			set "d_F_Count=0"
			if "!d_F_Pass!"=="0" (set "d_F_Pass=") else set "d_F_Pass=skip=!d_F_Pass!"
		)
		call:Database_Find_Run "%~1" "%~2" "%~5" "%~3" "%~6"
		if defined d_F_FindFirst if defined %~6 (
			set "%~6=!%~6:~1!"
			exit/b 0
		)
	) else (
		for /f "tokens=1,2 delims=-" %%: in ("%%~_") do (
			if "%%~:"=="%%~;" (
				set /a "d_F_Count2=%%~:-1"
				set /a "d_F_Pass=%%~:-1"
				set "d_F_Count=0"
			) else call:Database_Find2 "%%~:" "%%~;"
			if "!d_F_Pass!"=="0" (set "d_F_Pass=") else set "d_F_Pass=skip=!d_F_Pass!"
			call:Database_Find_Run "%~1" "%~2" "%~5" "%~3" "%~6"
			if defined d_F_FindFirst if defined %~6 (
				set "%~6=!%~6:~1!"
				exit/b 0
			)
		)
	)
)

if defined %~6 (set "%~6=!%~6:~1!") else (
	if defined d_F_ErrorPrint echo=	[���%0:���ݹؼ���"%~3"δ�ܴ�ָ���ļ��������ҵ����]
	exit/b 1
)
exit/b 0

REM call:Database_Find_Run "�ļ�" "�ָ���" "��" "�����ַ���" "������"
:Database_Find_Run
set "d_F_Count3="
for /f "usebackq %d_F_Pass% eol=^ tokens=%~3 delims=%~2" %%? in ("%~1") do (
	set /a "d_F_Count3+=1"
	set /a "d_F_Count2+=1"
	
	if not defined d_F_AlreadyLineNumber!d_F_Count2! (
		set "d_F_AlreadyLineNumber!d_F_Count2!=Yes"
		
		if "%%?"=="%%~?" (
			if %d_F_Insensitive% "%%?"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column1!"&if defined d_F_FindFirst exit/b
		)
		if "%%@"=="%%~@" (
			if %d_F_Insensitive% "%%@"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column2!"&if defined d_F_FindFirst exit/b
		)
		if "%%A"=="%%~A" (
			if %d_F_Insensitive% "%%A"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column3!"&if defined d_F_FindFirst exit/b
		)
		if "%%B"=="%%~B" (
			if %d_F_Insensitive% "%%B"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column4!"&if defined d_F_FindFirst exit/b
		)
		if "%%C"=="%%~C" (
			if %d_F_Insensitive% "%%C"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column5!"&if defined d_F_FindFirst exit/b
		)
		if "%%D"=="%%~D" (
			if %d_F_Insensitive% "%%D"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column6!"&if defined d_F_FindFirst exit/b
		)
		if "%%E"=="%%~E" (
			if %d_F_Insensitive% "%%E"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column7!"&if defined d_F_FindFirst exit/b
		)
		if "%%F"=="%%~F" (
			if %d_F_Insensitive% "%%F"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column8!"&if defined d_F_FindFirst exit/b
		)
		if "%%G"=="%%~G" (
			if %d_F_Insensitive% "%%G"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column9!"&if defined d_F_FindFirst exit/b
		)
		if "%%H"=="%%~H" (
			if %d_F_Insensitive% "%%H"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column10!"&if defined d_F_FindFirst exit/b
		)
		if "%%I"=="%%~I" (
			if %d_F_Insensitive% "%%I"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column11!"&if defined d_F_FindFirst exit/b
		)
		if "%%J"=="%%~J" (
			if %d_F_Insensitive% "%%J"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column12!"&if defined d_F_FindFirst exit/b
		)
		if "%%K"=="%%~K" (
			if %d_F_Insensitive% "%%K"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column13!"&if defined d_F_FindFirst exit/b
		)
		if "%%L"=="%%~L" (
			if %d_F_Insensitive% "%%L"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column14!"&if defined d_F_FindFirst exit/b
		)
		if "%%M"=="%%~M" (
			if %d_F_Insensitive% "%%M"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column15!"&if defined d_F_FindFirst exit/b
		)
		if "%%N"=="%%~N" (
			if %d_F_Insensitive% "%%N"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column16!"&if defined d_F_FindFirst exit/b
		)
		if "%%O"=="%%~O" (
			if %d_F_Insensitive% "%%O"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column17!"&if defined d_F_FindFirst exit/b
		)
		if "%%P"=="%%~P" (
			if %d_F_Insensitive% "%%P"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column18!"&if defined d_F_FindFirst exit/b
		)
		if "%%Q"=="%%~Q" (
			if %d_F_Insensitive% "%%Q"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column19!"&if defined d_F_FindFirst exit/b
		)
		if "%%R"=="%%~R" (
			if %d_F_Insensitive% "%%R"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column20!"&if defined d_F_FindFirst exit/b
		)
		if "%%S"=="%%~S" (
			if %d_F_Insensitive% "%%S"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column21!"&if defined d_F_FindFirst exit/b
		)
		if "%%T"=="%%~T" (
			if %d_F_Insensitive% "%%T"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column22!"&if defined d_F_FindFirst exit/b
		)
		if "%%U"=="%%~U" (
			if %d_F_Insensitive% "%%U"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column23!"&if defined d_F_FindFirst exit/b
		)
		if "%%V"=="%%~V" (
			if %d_F_Insensitive% "%%V"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column24!"&if defined d_F_FindFirst exit/b
		)
		if "%%W"=="%%~W" (
			if %d_F_Insensitive% "%%W"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column25!"&if defined d_F_FindFirst exit/b
		)
		if "%%X"=="%%~X" (
			if %d_F_Insensitive% "%%X"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column26!"&if defined d_F_FindFirst exit/b
		)
		if "%%Y"=="%%~Y" (
			if %d_F_Insensitive% "%%Y"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column27!"&if defined d_F_FindFirst exit/b
		)
		if "%%Z"=="%%~Z" (
			if %d_F_Insensitive% "%%Z"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column28!"&if defined d_F_FindFirst exit/b
		)
		if "%%["=="%%~[" (
			if %d_F_Insensitive% "%%["=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column29!"&if defined d_F_FindFirst exit/b
		)
		if "%%\"=="%%~\" (
			if %d_F_Insensitive% "%%\"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column30!"&if defined d_F_FindFirst exit/b
		)
		if "%%]"=="%%~]" (
			if %d_F_Insensitive% "%%]"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column31!"&if defined d_F_FindFirst exit/b
		)
	)
	if /i not "%d_F_Count%"=="No" (
		if "%d_F_Count%"=="0" exit/b
		if "!d_F_Count3!"=="%d_F_Count%" exit/b
	)
)
exit/b

REM ��������Ƕ�����ԭ���µ����ⲻ�ò�д��һ���ӳ�������ж�
REM call:Database_Find2 ��һ��ֵ �ڶ���ֵ
:Database_Find2
if %~10 gtr %~20 (
	set /a "d_F_Count2=%~2-1"
	set /a "d_F_Pass=%~2-1"
	set /a "d_F_Count=%~1-%~2+1"
) else (
	set /a "d_F_Count2=%~1-1"
	set /a "d_F_Pass=%~1-1"
	set /a "d_F_Count=%~2-%~1+1"
)
exit/b

:end
REM :--------------------------�ӳ����������----------------------------:
