
:: Dev helper file for launching quickly:


::  If you are using VSCode,
::  Put this inside of your `keybindings.json`:
:: {
::     "key": "alt+j",
::     "command": "workbench.action.terminal.sendSequence",
::     "when": "editorTextFocus",
::     "args": {
::         "text": "dev.bat\r"
::     }
:: }



@echo off

:: Kill any leftover love/lovec instances from previous runs. A force-closed
:: window can leave its UDP socket bound (or orphan the process entirely),
:: which holds the server port and makes the next launch fail to bind.
taskkill /F /IM lovec.exe >nul 2>&1
taskkill /F /IM love.exe  >nul 2>&1

start "Server" lovec . "{\"mode\":\"server\",\"localServer\":true}"
start "Client" lovec . "{\"mode\":\"client\",\"localClient\":true}"



