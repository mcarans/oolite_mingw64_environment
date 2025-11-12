# No parameters: build both clang and gcc in that order (end setup will be for gcc)
# One parameter gcc = build gcc only (end setup will be for gcc)
# One parameter clang = build clang only (end setup will be for clang)

pacman -S dos2unix --noconfirm
pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

rm -rf packages
mkdir packages

rename() {
	# First parameter is package name
	# Second parameter is file pattern
	# Third optional parameter is gcc or clang
    if [ -z "$3" ]; then
		fullname=$1
    else
		fullname="${1}_${3}"
    fi
	# package file eg. mingw-w64-x86_64-libobjc2-2.3-3-any.pkg.tar.zst
    filename=$(ls $2 2>/dev/null)
    if [ -z "$filename" ]; then
        echo "❌ No file matching $3 found."
        exit 1
    fi
    if [ "$3" ]; then
		# add gcc or clang to filename
        newname="${filename/$1/$fullname}"
        mv $filename $newname
        filename=$newname
	fi

	echo "${filename}"
}

build_install() {
	# First parameter is package name
	# Second optional parameter is gcc or clang
    echo "Building and installing $1 package"
	cd mingw-w64-$1
	# Deletes everything except PKGBUILD* and *.patch
	find . -mindepth 1 ! -name 'PKGBUILD*' ! -name '*.patch' -exec rm -rf {} +

    if [ -n "$2" ]; then
		# copy PKGBUILD_gcc or PKGBUILD_clang to PKGBUILD
		cp "PKGBUILD_${2}" PKGBUILD
    fi
	dos2unix PKGBUILD *.patch
	if ! makepkg -s -f --noconfirm ; then
	    echo "❌ $1 build failed!"
	    exit 1
	fi

	filename=$(rename $1 "*$1*any.pkg.tar.zst" $2)

	if ! pacman -U $filename --noconfirm ; then
	    echo "❌ $filename install failed!"
	    exit 1
	fi
	rm -f ../packages/*$fullname*any.pkg.tar.zst
	mv $filename ../packages
	cd ..
}

echo "Building common libraries"
package_names=(spidermonkey pcaudiolib espeak-ng SDL)
for packagename in "${package_names[@]}"; do
	build_install $packagename
done

pacman -S git --noconfirm
pacboy -S libpng --noconfirm
pacboy -S openal --noconfirm
pacboy -S libvorbis --noconfirm

rm -rf oolite
git clone -b modern_build --filter=blob:none https://github.com/mcarans/oolite.git
cd oolite
cp .absolute_gitmodules .gitmodules
git submodule update --init
git checkout -- .gitmodules
cd ..

if [[ -z "$1" || "$1" == "clang" ]]; then
	echo "Building GNUStep libraries with clang"
	export cc=/mingw64/bin/clang
	export cpp=/mingw64/bin/clang++
	clang_package_names=(libobjc2 gnustep-make gnustep-base)
	for packagename in "${clang_package_names[@]}"; do
		build_install $packagename clang
	done
	pacman -Q > packages/installed-packages-clang.txt
	source /mingw64/share/GNUstep/Makefiles/GNUstep.sh

	cd oolite
	make -f Makefile clean
	make -f Makefile release -j16
	cd ..
fi

if [[ -z "$1" ]]; then
	echo "Uninstalling clang GNUStep libraries"
	pacboy -R gnustep-base
	pacboy -R gnustep-make
	pacboy -R libobjc2
fi

if [[ -z "$1" || "$1" == "gcc" ]]; then
	echo "Building GNUStep libraries with gcc"
	export cc=/mingw64/bin/gcc
	export cpp=/mingw64/bin/g++
	gcc_package_names=(gnustep-make gnustep-base)
	for packagename in "${gcc_package_names[@]}"; do
		build_install $packagename gcc
	done
	pacman -Q > packages/installed-packages-gcc.txt
	source /mingw64/share/GNUstep/Makefiles/GNUstep.sh

	cd oolite
	make -f Makefile clean
	make -f Makefile release -j16
	cd ..
fi

cp /mingw64/share/GNUstep/Makefiles/GNUstep.sh /etc/profile.d/

if ! grep -q "# Custom history settings" ~/.bashrc; then
  cat >> ~/.bashrc <<'EOF'

# Custom history settings
WIN_HOME=$(cygpath "$USERPROFILE")
export HISTFILE=$WIN_HOME/.bash_history
export HISTSIZE=5000
export HISTFILESIZE=10000
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
EOF
fi
