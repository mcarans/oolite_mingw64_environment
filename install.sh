pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm
pacboy -S dos2unix --noconfirm

rm -rf packages
mkdir packages

package_names=(pcaudiolib espeak-ng nspr spidermonkey gnustep-make gnustep-base SDL)

for packagename in "${package_names[@]}"; do
    echo "Making $packagename package"
	cd mingw-w64-$packagename
	find . -mindepth 1 ! -name PKGBUILD -exec rm -rf {} +	
	dos2unix PKGBUILD
	makepkg -s -f --noconfirm
	pacman -U *$packagename*any.pkg.tar.zst --noconfirm
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
