pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

rm -rf packages
mkdir packages

cd mingw-w64-SDL
makepkg -s -f --noconfirm
mv *any.pkg.tar.zst ../packages
cd ..

cd mingw-w64-gnustep-make
makepkg -s -f --noconfirm
mv *any.pkg.tar.zst ../packages
cd ..

cd mingw-w64-gnustep-base
makepkg -s -f --noconfirm
mv *any.pkg.tar.zst ../packages
cd ..

cd packages
pacman -U *SDL*any.pkg.tar.zst --noconfirm
pacman -U *gnustep-make*any.pkg.tar.zst --noconfirm
pacman -U *gnustep-base*any.pkg.tar.zst --noconfirm
