@echo off
setlocal EnableDelayedExpansion

echo.
echo ==========================================================
echo "    _         _     __        ________  __              "
echo "   / \  _   _| |_ __\ \      / /  _ \ \/ /              "
echo "  / _ \| | | | __/ _ \ \ /\ / /| |_) \  /               "
echo " / ___ \ |_| | || (_) \ V  V / |  __//  \               "
echo "/_/   \_\__,_|\__\___/ \_/\_/  |_|  /_/\_\              "
echo.                                                         "
echo   Author    : Sayfullah Sayeb                            "
echo   Version   : 1.0.1                                      "
echo   Source    : https://github.com/SayfullahSayeb/AutoWPX  "
echo   Details   : WordPress Auto Setup Script for XAMPP      "
echo ========================================================="
echo.


echo Choose how to set up WordPress:
echo   1 - Download from wordpress.org
echo   2 - Use local ZIP file
echo.
set /p CHOICE=Your choice [1/2]: 


:: === Temp folder ===
set TEMP_DIR=%cd%\wp_temp
rmdir /S /Q "%TEMP_DIR%" >nul 2>&1

if "%CHOICE%"=="1" (
    echo Downloading WordPress...
    powershell -Command "Invoke-WebRequest -Uri https://wordpress.org/latest.zip -OutFile wordpress-latest.zip"
    powershell -Command "Expand-Archive -LiteralPath 'wordpress-latest.zip' -DestinationPath '%TEMP_DIR%' -Force"
    del wordpress-latest.zip
) else (
    :getLocalPath
    set "LOCAL_ZIP="
    set /p LOCAL_ZIP=Enter full path to your local WordPress ZIP file: 
    if not exist "!LOCAL_ZIP!" (
        echo ZIP file not found at "!LOCAL_ZIP!"
        echo Please try again.
        goto getLocalPath
    )
    powershell -Command "Expand-Archive -LiteralPath '!LOCAL_ZIP!' -DestinationPath '%TEMP_DIR%' -Force"
)

:: === Step 2: Domain Setup ===
echo.
echo ===============================
echo Enter your custom domain (e.g., mysite.com)
echo ===============================
set /p DOMAIN=Domain: 

:: === Paths and config ===
set XAMPP=C:\xampp
set SITE_DIR=%XAMPP%\htdocs\%DOMAIN%
set DB_NAME=%DOMAIN%
set CONFIG_FILE=%SITE_DIR%\wp-config.php

:: === Clean and copy WordPress ===
rmdir /S /Q "%SITE_DIR%" >nul 2>&1
xcopy /E /I /Y "%TEMP_DIR%\wordpress" "%SITE_DIR%" >nul
rmdir /S /Q "%TEMP_DIR%" >nul 2>&1

:: === Create Database ===
"%XAMPP%\mysql\bin\mysql.exe" -u root -e "CREATE DATABASE IF NOT EXISTS `%DOMAIN%`;"

:: === Setup wp-config.php ===
copy "%SITE_DIR%\wp-config-sample.php" "%CONFIG_FILE%" >nul
powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'database_name_here', '%DB_NAME%' -replace 'username_here', 'root' -replace 'password_here', '' | Set-Content '%CONFIG_FILE%'"

:: === Update hosts file ===
findstr /C:"%DOMAIN%" C:\Windows\System32\drivers\etc\hosts >nul || (
    echo 127.0.0.1 %DOMAIN% >> C:\Windows\System32\drivers\etc\hosts
)

:: === Virtual Host Setup ===
set VHOST_CONF=%XAMPP%\apache\conf\extra\httpd-vhosts.conf

:: Add virtual host only if not already there
findstr /C:"ServerName %DOMAIN%" "%VHOST_CONF%" >nul
if errorlevel 1 (
    echo Adding virtual host for %DOMAIN%...
    (
        echo.
        echo ^<VirtualHost *:80^>
        echo     ServerName %DOMAIN%
        echo     DocumentRoot "%SITE_DIR%"
        echo     ^<Directory "%SITE_DIR%"^>
        echo         Options Indexes FollowSymLinks
        echo         AllowOverride All
        echo         Require all granted
        echo     ^</Directory^>
        echo ^</VirtualHost^>
    ) >> "%VHOST_CONF%"
)

:: === Ensure httpd-vhosts.conf is included ===
findstr /C:"Include conf/extra/httpd-vhosts.conf" "%XAMPP%\apache\conf\httpd.conf" >nul || (
    echo Include conf/extra/httpd-vhosts.conf >> "%XAMPP%\apache\conf\httpd.conf"
)

:: === Restart Apache and MySQL to apply vhost changes ===
"%XAMPP%\xampp_stop.exe" >nul 2>&1
timeout /t 2 >nul
"%XAMPP%\xampp_start.exe" >nul 2>&1

:: === Open site in browser ===
start http://%DOMAIN%


:: === Final Menu ===
:MENU
echo.
echo ===============================
echo 1 - Open site in browser
echo 2 - Main menu 
echo 0 - Exit
echo ===============================
set /p ACTION=Choose an option: 

if "%ACTION%"=="1" (
    start http://%DOMAIN%
    goto MENU
) else if "%ACTION%"=="2" (
    call "%~f0"
    exit
) else if "%ACTION%"=="0" (
    exit
) else (
    echo Invalid option. Try again.
    goto MENU
)
