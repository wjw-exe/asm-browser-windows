@echo off
REM ============================================================
REM  在 Windows 上编译 asm-browser-windows -> browser.exe
REM  前置: 安装 MSYS2 (https://www.msys2.org/)
REM        打开 "MSYS2 UCRT64" 终端, 执行:
REM          pacman -S --needed mingw-w64-ucrt-x86_64-gcc make
REM        然后把本仓库代码放进一个目录, 在该目录运行本脚本,
REM        或直接在 UCRT64 终端里执行: make
REM ============================================================
x86_64-w64-mingw32-gcc -O0 -o browser.exe win/kernel.S -lkernel32 -lws2_32
if errorlevel 1 (
  echo [失败] 编译出错, 请确认已安装 mingw-w64-ucrt-x86_64-gcc
  pause
  exit /b 1
)
echo [成功] 已生成 browser.exe
browser.exe
