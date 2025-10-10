pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

rm -rf packages
mkdir packages

package_names=(pcaudiolib espeak-ng nspr spidermonkey gnustep-make gnustep-base SDL)

for packagename in "${package_names[@]}"; do
    echo "Making $packagename package"
	cd mingw-w64-$packagename
	makepkg -s -f --noconfirm
	pacman -U *$packagename*any.pkg.tar.zst --noconfirm
	rm -f ../packages/*$packagename*any.pkg.tar.zst
	mv *$packagename*any.pkg.tar.zst ../packages
	cd ..
done

pacman -Q > packages/installed-packages.txt

pacman -S git --noconfirm

pacboy -S libpng
pacboy -S openal
pacboy -S libvorbis

git clone -b modern_build https://github.com/mcarans/oolite.git
cd oolite

cp .absolute_gitmodules .gitmodules
git submodule update --init
git checkout -- .gitmodules

source /mingw64/share/GNUstep/Makefiles/GNUstep.sh
make -f Makefile clean
make -f Makefile release -j16
