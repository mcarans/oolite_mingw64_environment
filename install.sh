# No parameters: build both clang and gcc in that order (end setup will be for gcc)
# One parameter gcc = build gcc only (end setup will be for gcc)
# One parameter clang = build clang only (end setup will be for clang)

rename() {
    # First parameter is package name
    # Second parameter is file pattern
    # Third optional parameter is gcc or clang
    local fullname filename newname

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
        mv "$filename" "$newname"
        filename=$newname
    fi

    echo "${filename}" "${fullname}"
}

build_install() {
    # First parameter is package name
    # Second optional parameter is gcc or clang
    local filename fullname

    echo "Building and installing $1 package"
    cd "mingw-w64-$1"
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

    if ! pacman -U "$filename" --noconfirm ; then
        echo "❌ $filename install failed!" >&2
        exit 1
    fi
    rm -f ../packages/*$fullname*any.pkg.tar.zst
    mv "$filename" ../packages
    cd ..
}

pacman -S dos2unix --noconfirm
pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

rm -rf packages
mkdir packages

echo "Building common libraries"
PACKAGE_NAMES=(spidermonkey)
for PACKAGE_NAME in "${PACKAGE_NAMES[@]}"; do
    build_install "$PACKAGE_NAME"
done

pacman -Syu --noconfirm
pacman -S --noconfirm dos2unix git pactoys unzip
pacboy -S --noconfirm binutils espeak-ng jq libpng libvorbis mesa meson ninja nsis openal pcaudiolib python-pip sdl3

if [[ -z "$1" || "$1" == "clang" ]]; then
    echo "Building GNUStep libraries with clang"
    export CC=$MINGW_PREFIX/bin/clang
    export CXX=$MINGW_PREFIX/bin/clang++
    CLANG_PACKAGE_NAMES=(libobjc2 gnustep-make gnustep-base)
    for PACKAGE_NAME in "${CLANG_PACKAGE_NAMES[@]}"; do
        # add clang to filename
        build_install "$PACKAGE_NAME" clang
    done
    pacman -Q > packages/installed-packages-clang.txt
    NATIVE_FILE="clang.ini"
else
    echo "Building GNUStep libraries with gcc"
    export CC=$MINGW_PREFIX/bin/gcc
    export CXX=$MINGW_PREFIX/bin/g++
    GCC_PACKAGE_NAMES=(gnustep-make gnustep-base)
    for PACKAGE_NAME in "${GCC_PACKAGE_NAMES[@]}"; do
        # add gcc to filename
        build_install "$PACKAGE_NAME" gcc
    done
    pacman -Q > packages/installed-packages-gcc.txt
    NATIVE_FILE="gcc.ini"
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

DEST_DIR="/usr/local/bin"
echo "Fetching latest GitVersion release info..."
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/GitTools/GitVersion/releases/latest")
DOWNLOAD_URL=$(echo "${RELEASE_JSON}" | jq -r '.assets[] | select(.name | contains("win-x64")) | .browser_download_url' | head -n 1)
if [[ -z "${DOWNLOAD_URL}" || "${DOWNLOAD_URL}" == "null" ]]; then
    echo "❌ Could not find a matching win-x64 download URL!" >&2
    exit 1
fi
TMP_DIR=$(mktemp -d)
ZIP_NAME=$(basename "${DOWNLOAD_URL}")
ZIP_PATH="${TMP_DIR}/${ZIP_NAME}"
echo "📥 Downloading ${ZIP_NAME}..."
curl -fsSL "${DOWNLOAD_URL}" -o "${ZIP_PATH}"
echo "📦 Extracting GitVersion..."
mkdir -p "${TMP_DIR}/extracted"
unzip -o "${ZIP_PATH}" -d "${TMP_DIR}/extracted"
echo "⚙️ Installing binary to ${DEST_DIR}..."
mkdir -p "${DEST_DIR}"
chmod +x "${TMP_DIR}/extracted/gitversion.exe"
mv "${TMP_DIR}/extracted/gitversion.exe" "${DEST_DIR}/gitversion.exe"
rm -rf "${TMP_DIR}"

if ! gitversion -version; then
    echo "❌ Could not install gitversion!" >&2
    exit 1
fi
echo "✅ GitVersion installed successfully!"

rm -rf oolite
git clone --filter=blob:none https://github.com/OoliteProject/oolite.git
cd oolite

./mk.sh clean dev
if ./mk.sh build dev --native-file="$NATIVE_FILE"; then
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
