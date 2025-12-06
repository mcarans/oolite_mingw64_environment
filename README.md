# Oolite MSYS2 Package Dependency Maker and Full Local Build from Source

Creates MSYS2 UCRT64 Clang or MinGW64 GCC packages of dependencies that Oolite needs. The GitHub Action creates a UCRT64 Clang build followed by a MinGW64 GCC build and puts the packages into the release on GitHub.

You can also create an environment locally, building all dependencies from source, as follows:

Double click Run Me. The Run Me shortcut runs setup.cmd. setup.cmd installs MSYS2. You will be prompted for an install location. If you type c:, MSYS2 will be installed in c:\msys64. You can choose the MSYS2 environment and compiler combination - 1 for UCRT64 Clang or 2 for MinGW64 GCC. setup.cmd launches the aprropriate MSYS2 shell corresponding to the chosen environment and passes gcc or clang as a parameter to install.sh. install.sh builds Oolite's dependencies from source and then Oolite. 

Once completed, you can type the following in the shell: 

    cd oolite/oolite.app
	./oolite.exe

If you subsequently wish to try the other environment/compiler combination, open the environment's shell and then run install.sh passing parameter gcc or clang as appropriate.
