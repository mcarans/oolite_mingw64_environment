# No parameters: build both clang and gcc in that order (end setup will be for gcc)
# One parameter gcc = build gcc only (end setup will be for gcc)
# One parameter clang = build clang only (end setup will be for clang)

rename() {
	# First parameter is package name
	# Second parameter is file pattern
	# Third optional parameter is gcc or clang
    if [ -z "$3" ]; then
		fullname=$1
    else
		fullname="${1}_${3}"
    fi
    filename=$(ls $2 2>/dev/null)
    if [ -z "$filename" ]; then
        echo "❌ No file matching $2 found." >&2
        exit 1
    fi
    if [ "$3" ]; then
        newname="${filename/$1/$fullname}"
        mv $filename $newname
        filename=$newname
	fi

	echo "${filename}" "${fullname}"
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
	    echo "❌ $1 build failed!" >&2
	    exit 1
	fi

	# package file eg. mingw-w64-x86_64-libobjc2-2.3-3-any.pkg.tar.zst
	read filename fullname <<< "$(rename $1 "*$1*any.pkg.tar.zst" $2)"

	if ! pacman -U $filename --noconfirm ; then
	    echo "❌ $filename install failed!" >&2
	    exit 1
	fi
	rm -f ../packages/*$fullname*any.pkg.tar.zst
	mv $filename ../packages
	cd ..
}

pacman -S dos2unix --noconfirm
pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

rm -rf packages
mkdir packages

echo "Building common libraries"
package_names=(spidermonkey)
for packagename in "${package_names[@]}"; do
	build_install $packagename
done

pacman -Syu --noconfirm
pacman -S --noconfirm dos2unix git pactoys unzip
pacboy -S --noconfirm binutils espeak-ng jq libpng libvorbis mesa meson ninja nsis openal pcaudiolib python-pip sdl3

echo "Installing GitVersion"
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/GitTools/GitVersion/releases/latest \
  | jq -r '.assets[] | select(.name | match("gitversion-win-x64-.*\\.zip")) | .browser_download_url')
if [[ -z "$DOWNLOAD_URL" ]] || [[ "$DOWNLOAD_URL" == "null" ]]; then
    echo "Error: Could not find GitVersion download URL."
    exit 1
fi
TMP_DIR=$(mktemp -d)
curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/gitversion.zip"
mkdir -p /usr/local/bin
unzip -q -o "$TMP_DIR/gitversion.zip" -d "$TMP_DIR/extracted"
mv "$TMP_DIR/extracted/gitversion.exe" /usr/local/bin/
rm -rf "$TMP_DIR"

rm -rf oolite
git clone --filter=blob:none https://github.com/OoliteProject/oolite.git

if [[ -z "$1" || "$1" == "clang" ]]; then
	echo "Building GNUStep libraries with clang"
	export cc=$MINGW_PREFIX/bin/clang
	export cxx=$MINGW_PREFIX/bin/clang++
	clang_package_names=(libobjc2 gnustep-make gnustep-base)
	for packagename in "${clang_package_names[@]}"; do
		# add clang to filename
		build_install $packagename clang
	done
	pacman -Q > packages/installed-packages-clang.txt
	native_file="clang.ini"
else
	echo "Building GNUStep libraries with gcc"
	export cc=$MINGW_PREFIX/bin/gcc
	export cxx=$MINGW_PREFIX/bin/g++
	gcc_package_names=(gnustep-make gnustep-base)
	for packagename in "${gcc_package_names[@]}"; do
		# add gcc to filename
		build_install $packagename gcc
	done
	pacman -Q > packages/installed-packages-gcc.txt
	native_file="gcc.ini"
fi

export GS_MAKE="$MINGW_PREFIX/share/GNUstep/Makefiles"
echo "****************************"
echo "gnustep-config --objc-flags:"
GNUSTEP_MAKEFILES=$GS_MAKE gnustep-config --objc-flags
echo ""
echo "gnustep-config --debug-flags:"
GNUSTEP_MAKEFILES=$GS_MAKE gnustep-config --debug-flags
echo ""
echo "gnustep-config --objc-libs:"
GNUSTEP_MAKEFILES=$GS_MAKE gnustep-config --objc-libs
echo ""
echo "gnustep-config --base-libs:"
GNUSTEP_MAKEFILES=$GS_MAKE gnustep-config --base-libs
unset GS_MAKE
echo "****************************"
echo ""

cd oolite

cd build
# install gitversion
outputdir="."
download_github_release gitversion_zip "GitTools" "GitVersion" "win-x64" "$outputdir"
unzip -o ${gitversion_zip} -d "$outputdir"
chmod +x "$outputdir/gitversion.exe"
mv "$outputdir/gitversion.exe" "$MINGW_PREFIX/bin/gitversion.exe"
rm -f ${gitversion_zip}
cd ..

make clean
if make release NATIVE_FILE="$native_file"; then
	echo "✅ Oolite build completed successfully"
else
	echo "❌ Oolite build failed" >&2
	exit 1
fi
cd ..

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
