pacman -S pactoys --noconfirm
pacboy -S binutils --noconfirm

cd mingw-w64-SDL
makepkg -s -f --noconfirm
pacman -U *any.pkg.tar.zst --noconfirm
cd ..

cd mingw-w64-gnustep-make
makepkg -s -f --noconfirm
pacman -U *any.pkg.tar.zst --noconfirm
cd ..

cd mingw-w64-gnustep-base
makepkg -s -f --noconfirm
pacman -U *any.pkg.tar.zst --noconfirm
cd ..

