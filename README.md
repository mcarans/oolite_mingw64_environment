# Oolite MSYS2 MinGW64 Environment

Creates MSYS2 MinGW64 packages of dependencies that Oolite needs

You can also create an environment locally, building all dependencies, as follows:

Double click Run Me. You will be prompted for an install location. If you type c:, MSYS2 will be installed in c:\msys64. Then Oolite's dependencies will be installed followed by Oolite itself. A gcc build is created by default. 

Once completed, you can type the following in the shell: 

    cd oolite/oolite.app
	./oolite.exe
	
By default, install.sh is run with parameter gcc by setup.cmd (which is started by Run Me). install.sh can be run with parameter clang for a clang build. The GitHub Action passes no parameters which creates a clang build followed by a gcc build.
