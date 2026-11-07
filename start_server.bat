@echo off
setlocal
cd /d "%~dp0"

echo ==================================================
echo   PharmaBuy B2B - Pharmaceutical Distribution Portal
echo ==================================================
echo.

python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python was not found on PATH.
    echo         Install Python 3.10 or newer from https://python.org and retry.
    pause
    exit /b 1
)

if not exist ".env" (
    echo [INFO] No .env file found - copying .env.example.
    echo        Edit .env to match your SQL Server instance.
    copy /y ".env.example" ".env" >nul
)

echo [1/2] Installing dependencies...
python -m pip install --quiet --upgrade pip
python -m pip install --quiet -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Dependency installation failed.
    pause
    exit /b 1
)

echo [2/2] Starting the development server...
echo.
echo   URL: http://127.0.0.1:5000
echo   Stop with Ctrl+C
echo.
python app.py

pause
