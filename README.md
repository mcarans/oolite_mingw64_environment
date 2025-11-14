# Oolite MSYS2 MinGW64 Environment

Creates MSYS2 MinGW64 packages of dependencies that Oolite needs including both clang and gcc versions for the GNUStep libraries.

You can also create an environment locally, building all dependencies from source, as follows:

Double click Run Me. You will be prompted for an install location. If you type c:, MSYS2 will be installed in c:\msys64. You will then be prompted for the compiler to use. Type gcc or clang as desired. Then Oolite's dependencies will be built from source followed by Oolite itself.

Once completed, you can type the following in the shell: 

    cd oolite/oolite.app
	./oolite.exe

Run Me is a shortcut which runs setup.cmd. setup.cmd installs MSYS2. It passes parameter gcc or clang to install.sh. install.sh builds Oolite's dependencies from source and then Oolite. The GitHub Action passes no parameters which creates a clang build followed by a gcc build of Oolite.
