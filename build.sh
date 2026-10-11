#!/usr/bin/env bash
# Linux 上用 MinGW-w64 交叉编译出 browser.exe
# 前置: sudo apt install mingw-w64   (或对应发行版的 mingw-w64 包)
set -e
x86_64-w64-mingw32-gcc -O0 -o browser.exe win/kernel.S -lkernel32 -lws2_32
echo "[成功] 已生成 browser.exe (Windows PE)"
