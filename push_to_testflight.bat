@echo off
setlocal
title Sky Hop - Send to TestFlight
cd /d "%~dp0"

echo.
echo  ==========================================
echo    Sky Hop  -^>  GitHub  -^>  TestFlight
echo  ==========================================
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo  Git is not installed. Opening the download page...
    echo  Install it with the default options, then run this file again.
    start "" "https://git-scm.com/download/win"
    pause
    exit /b 1
)

rem ---- Make sure git knows who you are (needed to save a commit) ----
git config user.name >nul 2>nul
if errorlevel 1 goto askname
goto checkemail
:askname
set /p GIT_NAME=Your name (for the project history): 
git config --global user.name "%GIT_NAME%"
:checkemail
git config user.email >nul 2>nul
if errorlevel 1 goto askemail
goto checkrepo
:askemail
set /p GIT_EMAIL=Your email (for the project history): 
git config --global user.email "%GIT_EMAIL%"

rem ---- First run: connect this folder to your GitHub repository ----
:checkrepo
if exist ".git" goto checkremote
git init -b main >nul
:checkremote
git remote get-url origin >nul 2>nul
if not errorlevel 1 goto send
echo  First time setup: create an EMPTY private repository on github.com
echo  (no README), then copy its URL, e.g. https://github.com/you/skyhop.git
echo.
start "" "https://github.com/new"
set /p REPO_URL=Paste the repository URL here: 
if "%REPO_URL%"=="" (
    echo  No URL entered. Nothing was sent.
    pause
    exit /b 1
)
git remote add origin "%REPO_URL%"

rem ---- Save everything and send it ----
:send
git branch -M main >nul 2>nul
git add -A
git commit --allow-empty -q -m "TestFlight build %DATE% %TIME%"
echo  Sending to GitHub (a sign-in window may pop up the first time)...
git push -u origin main
if errorlevel 1 (
    echo.
    echo  Push failed. Check the URL, your internet, and that you signed in to GitHub.
    pause
    exit /b 1
)

for /f "delims=" %%U in ('git remote get-url origin') do set ORIGIN=%%U
set ORIGIN=%ORIGIN:.git=%
echo.
echo  Sent! GitHub is now building the app on a Mac and uploading it to Apple.
echo  Opening the progress page... (a green check = uploaded)
echo  The build then appears in App Store Connect ^> TestFlight in about 5-30 minutes.
start "" "%ORIGIN%/actions"
echo.
pause
