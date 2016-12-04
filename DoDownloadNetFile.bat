@echo off
setlocal ENABLEDELAYEDEXPANSION
REM DoDownloadNetFile-Bat
REM 根据配置文件从指定URL下载数据并根据配置文件作相应操作
REM V0.1, 20161204

REM 代码自定义配置模式(如此处定义配置则不再读取Config)
	REM 下载地址
	set URL=
	REM 下载路径
	set TARGET_DIR=
	REM 下载完毕后是否执行, 是: true, 否: false
	set IS_RUN=
	REM 下载完毕后执行延时, 此项需要IS_RUN开启状态, 默认为0/s
	set RUN_DELAY=

REM 读取传入参数
REM %1-URL, %2-TARGET_DIR, %3-IS_RUN, %4-RUN_DELAY
if defined URL goto checkConfig
	REM 下载地址
	set "URL=%~1"
	REM 下载路径
	set "TARGET_DIR=%~2"
	REM 下载完毕后是否执行, 是: true, 否: false
	set "IS_RUN=%~3"
	REM 下载完毕后执行延时, 此项需要IS_RUN开启状态, 默认为0/s
	set "RUN_DELAY=%~4"

REM 读取配置文件
REM 	批处理当前目录下`%bat文件基本名(不包含扩展名)%.ini`
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

REM 配置校验
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

REM 开始下载
	call:DownloadNetFile "%URL%" "%TARGET_DIR%"
	if not "%errorlevel%"=="0" exit/b 1
	
	if /i not "%IS_RUN%"=="true" exit/b 0
	
	REM ping -n %RUN_DELAY% 127.0.0.1 >nul 2>nul
	ping -n %RUN_DELAY% 127.0.0.1 >nul 2>nul
	start "" "%TARGET_DIR%"
	exit/b 0


REM :--------------------------子程序开始区域----------------------------:
goto end

REM 判断变量中是否含有非数字字符 call:DefinedNoNumberString 被判断字符
REM	返回值0代表有非数字字符，返回值1代表无非数字字符，返回值2代表参数为空
REM 版本：20151231
:DefinedNoNumberString
REM 判断子程序基本需求参数
if "%~1"=="" exit/b 2

REM 初始化子程序需求变量
for %%B in (DefinedNoNumberString) do set %%B=
set DefinedNoNumberString=%~1

REM 子程序开始运行
for /l %%B in (0,1,9) do (
	set DefinedNoNumberString=!DefinedNoNumberString:%%B=!
	if not defined DefinedNoNumberString exit/b 1
)
exit/b 0


REM call:DownloadNetFile 网址 路径及文件名
REM 下载网络文件 版本：20160114
:DownloadNetFile
REM 检查子程序使用规则正确与否
if "%~2"=="" (
	echo=	#[Error %0:参数2]文件路径及文件名为空
	exit/b 1
) else if "%~1"=="" (
	echo=	#[Error %0:参数1]网址为空
	exit/b 1
)

REM 初始化子程序需求变量
for %%- in (downloadNetFileTempPath downloadNetFileUrl downloadNetFileCachePath) do if defined %%- set %%-=
set downloadNetFileTempPath=%temp%\downloadNetFileTempPath%random%%random%%random%.vbs
set downloadNetFileUrl="%~1"
set downloadNetFileUrl="%downloadNetFileUrl:"=%"
set downloadNetFileFilePath=%~2

REM 生成动作脚本
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

REM 删除IE关于下载内容的缓存
for /f "tokens=3,* skip=2" %%- in ('reg query "hkcu\software\microsoft\windows\currentversion\explorer\shell folders" /v cache') do if "%%~."=="" (set downloadNetFileCachePath=%%-) else set downloadNetFileCachePath=%%- %%.
for /r "%downloadNetFileCachePath%" %%- in ("%~n1*") do if exist "%%~-" del /f /q "%%~-"

REM 运行脚本
cscript //b "%downloadNetFileTempPath%"

REM 删除临时文件
if exist "%downloadNetFIleTempPath%" del /f /q "%downloadNetFIleTempPath%"

REM 判断脚本运行结果
if exist "%downloadNetFileFilePath%" (exit/b 0) else exit/b 1

REM Properties_Tool_20161204版本
REM :------------------------------------------------------------Properties_Read------------------------------------------------------------------------------------:
REM Properties模式读取数据(key与value之间使用制表符分割模式)
REM call:Properties_Read "文件路径" "keyName" "接收数据变量名"
REM 例子：从文件 "config.ini" 中读取key为phoneNumber的数据到变量mobilePhoneNumber中
REM 		call:Properties_Read "config.ini" phoneNumber mobilePhoneNumber
REM 返回值详情: 0-读取成功, 1-查无此key(无数据), 2-参数错误
REM 备注: 本子程序需要子程序 Database_Find, Database_Read
:Properties_Read

REM 查找key是否在文件中存在
set p_r_find_result=
call:Database_Find /Q /i /first "%~1" "	" "%~2" 0 1 p_r_find_result
if "%errorlevel%"=="1" exit/b 1
if "%errorlevel%"=="2" exit/b 2

REM 查找到的话则读取获取该行行号
set p_r_find_line=
for %%a in (%p_r_find_result%) do for /f "tokens=1,2" %%b in ("%%~a") do (
	set p_r_find_line=%%b
)

REM 读取该行key次列数据并返回
call:Database_Read /Q "%~1" "	" "%p_r_find_line%" 2 "%~3"
exit/b %errorlevel%

REM (批处理文本数据库工具箱)Database_Tools_20160625版本
REM :--------------------------------------------------------------------Database_Read-------------------------------------------------------------------------------:
REM 从指定文件、指定行、指定分隔符、指定列获取内容赋值到指定变量
REM call:Database_Read [/Q(安静模式，不提示错误)] "数据源文件" "数据列分隔符" "数据所在行" "以分隔符为分割的N列数据(列目号与列目号之间使用,分割，且可以区间分割符-)" "单个或多个变量(多个变量之间使用空格或,进行分割)"
REM 例子：从文件 "c:\users\a\Database.ini" 中将以 "	" 为分隔符的第4行数据的第1,2,3,6列数据分别赋值到var1,var2,var3,var4
REM					call:Database_Read "c:\users\a\Database.ini" "	" "4" "1-3,6" "var1 var2 var3 var4"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20151127
:Database_Read
REM 检查子程序运行基本需求参数
set "d_R_ErrorPrint="
if /i "%~1"=="/q" (shift/1) else set "d_R_ErrorPrint=Yes"
if "%~5"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数5-指定被赋值变量名为空]
	exit/b 2
)
if "%~4"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数4-指定列目号为空]
	exit/b 2
)
if "%~3"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数3-指定行号为空]
	exit/b 2
)
if %~3 lss 1 (
	if defined d_R_ErrorPrint echo=	[错误%0:参数3-指定行号小于1:%~3]
	exit/b 2
)
if "%~2"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数2-指定分隔符为空]
	exit/b 2
)
if "%~1"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)

REM 初始化变量
for %%_ in (d_R_Count d_R_Pass) do set "%%_="
for /l %%_ in (1,1,31) do if defined d_R_Count%%_ set "d_R_Count%%_="
set /a "d_R_Pass=%~3-1"
if "%d_R_Pass%"=="0" (set "d_R_Pass=") else set "d_R_Pass=skip=%d_R_Pass%"

REM 子程序开始运作
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
if not defined d_R_Count if defined d_R_ErrorPrint echo=	[错误%0:结果-查无此行:%~3]
exit/b 1


REM :--------------------------------------------------------------------Database_Find-------------------------------------------------------------------------------:
REM 从指定文件、指定行、指定分隔符、指定列、指定字符串搜索并将搜索结果的行列号写入到指定变量中
REM call:Database_Find [/Q(安静模式，不提示错误)] [/i(不区分大小写)] [/first(返回查找到的第一个结果)] "数据源" "数据列分隔符"  "查找字符串" "查找数据行(支持单数分隔符,与区间连续分隔符-,0为指定全部行)" "查找数据列(支持单数分隔符,与区间连续分隔符-)" "查找结果行号列号结果接受赋值变量名"
	REM 注意：-------------------------------------------------------------------------------------------------------------------------------
	REM 	结果变量的输出格式为："行 列","行 列","..."依次递加，例如第二行第三列和第五行第六列的赋值内容就为："2 3","5 6"
	REM 	可以使用 'for %%a in (%结果变量%) do for /f "tokens=1,2" %%b in ("%%~a") do echo=第%%b行，第%%c列' 的方法进行结果使用
	REM -------------------------------------------------------------------------------------------------------------------------------------
REM 例子：从文件 "c:\users\a\Database.ini"中第三到五行以"	"为分隔符的第一列中不区分大小写的查找字符串data(完全匹配)并将搜索结果的行列号赋值到变量result
REM					call:Database_Find /i "c:\users\a\Database.ini" "	" "data" "3-5" "1" "result"
REM 返回值详情：0-根据指定字符串找到结果并已赋值变量，1-未查找到结果，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20160625
:Database_Find
REM 检查子程序运行基本需求参数
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
	if defined d_F_ErrorPrint echo=	[错误%0:参数6-指定接受结果变量名为空]
	exit/b 2
)
if "%~5"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数5-指定查找列号为空]
	exit/b 2
)
if "%~4"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数4-指定查找行号为空]
	exit/b 2
)
if "%~3"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数3-指定查找字符串为空]
	exit/b 2
)
if "%~2"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数2-指定数据列分隔符为空]
	exit/b 2
)
if "%~1"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)

REM 初始化变量
for %%_ in (d_F_Count d_F_StringTest d_F_Count2 d_F_Pass %~6) do set "%%_="
for /f "delims==" %%_ in ('set d_F_AlreadyLineNumber 2^>nul') do set "%%_="
for /f "delims==" %%_ in ('set d_F_Column 2^>nul') do set "%%_="

REM 子程序开始运作
REM 判断用户输入行号是否符合规则
set "d_F_StringTest=%~4"
for %%_ in (1,2,3,4,5,6,7,8,9,0,",",-) do if defined d_F_StringTest set "d_F_StringTest=!d_F_StringTest:%%~_=!"
if defined d_F_StringTest (
	if defined d_F_ErrorPrint echo=	[错误%0:参数4:指定查找行号不符合规则:%~4]
	exit/b 2
)

REM 将列号赋值到列变量
for /f "tokens=%~5" %%? in ("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31") do for /f "delims=%%" %%_ in ("%%? %%@ %%A %%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U %%V %%W %%X %%Y %%Z %%[ %%\ %%]") do for %%: in (%%_) do (
	set /a "d_F_Count+=1"
	set "d_F_Column!d_F_Count!=%%:"
)
set "d_F_Count="
REM 根据行号进行拆分执行命令
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
	if defined d_F_ErrorPrint echo=	[结果%0:根据关键字"%~3"未能从指定文件行列中找到结果]
	exit/b 1
)
exit/b 0

REM call:Database_Find_Run "文件" "分隔符" "列" "查找字符串" "变量名"
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

REM 可能由于嵌套深度原因导致的问题不得不写出一个子程序进行判断
REM call:Database_Find2 第一个值 第二个值
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
REM :--------------------------子程序结束区域----------------------------:
