@echo off
REM Compile resource file
windres PopupDialog.rc -O coff -o PopupDialog.res

REM Compile and link DLL (32-bit)
g++ -m32 -shared -o PopupDLL.dll PopupDLL.cpp PopupDialog.res -static-libgcc -static-libstdc++ -Wl,--add-stdcall-alias

echo Build complete. DLL is PopupDLL.dll
pause