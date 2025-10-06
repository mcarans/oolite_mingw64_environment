:: Quick setup for testing that assumes c: drive install and the existence of a clean c:\msys64_orig directory

@echo off
setlocal

cd c:\

echo === Copy clean MSYS2 to msys64 folder ===
rmdir /s /q msys64
robocopy msys64_orig msys64 /E /Z /MT:16 /R:3 /W:5 /NFL /NDL

:: Change directory to the folder containing this script
cd /D "%~dp0"
echo Running in: %CD%

echo === Launch MinGW64 shell, build Oolite dependencies, install Oolite  ===

c:\msys64\msys2_shell.cmd -mingw64 -defterm -here -no-start -c "./install.sh; exec bash"

endlocal
