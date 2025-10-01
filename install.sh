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

pacman -Q > installed-packages.txt
cd ..