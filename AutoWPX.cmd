@echo off
setlocal EnableDelayedExpansion
mode con cols=80 lines=30

echo.
echo ==========================================================
echo "    _         _     __        ________  __              "
echo "   / \  _   _| |_ __\ \      / /  _ \ \/ /              "
echo "  / _ \| | | | __/ _ \ \ /\ / /| |_) \  /               "
echo " / ___ \ |_| | || (_) \ V  V / |  __//  \               "
echo "/_/   \_\__,_|\__\___/ \_/\_/  |_|  /_/\_\              "
echo.                                                         "
echo   Author    : Sayfullah Sayeb                            "
echo   Version   : 1.0.5                                      "
echo   Source    : https://github.com/SayfullahSayeb/AutoWPX  "
echo   Details   : WordPress Auto Setup Script for XAMPP      "
echo ========================================================="
echo.

:: === XAMPP paths ===
set "XAMPP=C:\xampp"
set "MYSQL_EXE=%XAMPP%\mysql\bin\mysql.exe"

:: === Ask for type of site ===
echo ===============================
echo   AutoWPX - XAMPP Site Setup
echo ===============================
echo 1 - Create WordPress Site
echo 2 - Create Static HTML Site
echo ===============================
set /p SITE_TYPE=Choose [1/2]: 

:: === Ask for domain ===
set /p DOMAIN=Enter your domain (e.g., mysite.local): 
set "SITE_DIR=%XAMPP%\htdocs\%DOMAIN%"
set "DB_NAME=%DOMAIN%"

:: === Create site directory ===
if not exist "%SITE_DIR%" mkdir "%SITE_DIR%"

if "%SITE_TYPE%"=="1" (

    :: === Download and extract WordPress ===
    echo Downloading WordPress...
    cd /d "%SITE_DIR%"
    powershell -Command "Invoke-WebRequest -Uri https://wordpress.org/latest.zip -OutFile 'latest.zip'"

    echo Extracting WordPress...
    powershell -Command "Expand-Archive -Path 'latest.zip' -DestinationPath '.' -Force"
    xcopy /E /I /Y ".\wordpress\*" "." >nul
    rmdir /S /Q ".\wordpress"
    del latest.zip

    :: === Create MySQL database ===
    echo Creating database...
    "%MYSQL_EXE%" -u root -e "CREATE DATABASE IF NOT EXISTS `%DB_NAME%`;"

    :: === Setup wp-config.php ===
    copy "wp-config-sample.php" "wp-config.php" >nul
    powershell -Command "(Get-Content 'wp-config.php') -replace 'database_name_here', '%DB_NAME%' -replace 'username_here', 'root' -replace 'password_here', '' | Set-Content 'wp-config.php'"

) else if "%SITE_TYPE%"=="2" (

    :: === Create basic index.html for static site ===
    echo Creating static site files...
    (
        echo ^<html^>
        echo ^<head^>^<title^>%DOMAIN%^</title^>^</head^>
        echo ^<body^>
        echo ^<h1^>Welcome to %DOMAIN%^</h1^>
        echo ^<p^>This is a static HTML site.^</p^>
        echo ^</body^>
        echo ^</html^>
    ) > "%SITE_DIR%\index.html"

)

:: === Add to hosts file ===
findstr /C:"%DOMAIN%" C:\Windows\System32\drivers\etc\hosts >nul || (
    echo 127.0.0.1 %DOMAIN% >> C:\Windows\System32\drivers\etc\hosts
)

:: === Set up Virtual Host ===
set "VHOST_CONF=%XAMPP%\apache\conf\extra\httpd-vhosts.conf"
findstr /C:"ServerName %DOMAIN%" "%VHOST_CONF%" >nul || (
    echo Adding virtual host...
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

:: === Ensure Apache includes vhost file ===
findstr /C:"Include conf/extra/httpd-vhosts.conf" "%XAMPP%\apache\conf\httpd.conf" >nul || (
    echo Include conf/extra/httpd-vhosts.conf >> "%XAMPP%\apache\conf\httpd.conf"
)

:: === Restart XAMPP (Apache & MySQL) ===
echo Restarting XAMPP services...
"%XAMPP%\xampp_stop.exe" >nul 2>&1
timeout /t 2 >nul
"%XAMPP%\xampp_start.exe" >nul 2>&1

:: === Launch site ===
echo Done! Opening site...
if "%SITE_TYPE%"=="1" (
    start http://%DOMAIN%/wp-admin/install.php
) else (
    start http://%DOMAIN%/
)
pause
