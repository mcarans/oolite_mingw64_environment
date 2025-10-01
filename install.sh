pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

mkdir packages

package_names=(SDL gnustep-make gnustep-base pcaudiolib espeakng nspr spidermonkey)

for packagename in "${package_names[@]}"; do
    echo "Making $packagename package"
	cd mingw-w64-$packagename
	makepkg -s -f --noconfirm
	rm -f ../packages/*$packagename*any.pkg.tar.zst
	mv *$packagename*any.pkg.tar.zst ../packages
	cd ..	
done

cd packages
for packagename in "${package_names[@]}"; do
    echo "Installing $packagename package"
	pacman -U *$packagename*any.pkg.tar.zst --noconfirm
done

pacman -Q > installed-packages.txt
cd ..