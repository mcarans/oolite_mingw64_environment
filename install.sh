pacman -S dos2unix --noconfirm
pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

rm -rf packages
mkdir packages

package_names=(gnustep-make gnustep-base nspr spidermonkey pcaudiolib espeak-ng SDL)

for packagename in "${package_names[@]}"; do
    echo "Making $packagename package"
	cd mingw-w64-$packagename
	# Deletes everything except PKGBUILD and *.patch
	find . -mindepth 1 ! -name PKGBUILD ! -name '*.patch' -exec rm -rf {} +
	dos2unix PKGBUILD
	if ! makepkg -s -f --noconfirm ; then
	    echo "❌ $packagename build failed!"
	    exit 1
	fi
	if ! pacman -U *$packagename*any.pkg.tar.zst --noconfirm ; then
	    echo "❌ $packagename install failed!"
	    exit 1
	fi
	rm -f ../packages/*$packagename*any.pkg.tar.zst
	mv *$packagename*any.pkg.tar.zst ../packages
	cd ..
done

pacman -S git --noconfirm
pacboy -S libpng --noconfirm
pacboy -S openal --noconfirm
pacboy -S libvorbis --noconfirm

pacman -Q > packages/installed-packages.txt

rm -rf oolite
git clone -b modern_build https://github.com/mcarans/oolite.git
cd oolite

cp .absolute_gitmodules .gitmodules
git submodule update --init
git checkout -- .gitmodules

source /mingw64/share/GNUstep/Makefiles/GNUstep.sh
make -f Makefile clean
make -f Makefile release -j16

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
