# asm-browser-windows

Linux 版汇编浏览器内核（[asm-browser-linux](https://github.com/wjw-exe/asm-browser-linux)）的 **Windows x86-64 移植**。
采用 Microsoft x64 调用约定，改走 kernel32.dll（控制台 I/O、文件 I/O），网络位预留 ws2_32（Winsock）。
输出与 Linux 版**完全相同的行式 IPC 协议**，因此 `gui/browser_gui.py` 在 Windows 上原样可用。

## 文件

- `win/kernel.S` —— Win64 内核（单文件模块化结构）
- `gui/browser_gui.py` —— Tkinter 前端（与 Linux 版一致）
- `tests/sample.html` —— 演示页
- `Makefile` —— MinGW-w64 构建

## 构建

需要 MinGW-w64（Windows 上 MSYS2，或 Linux 上 `apt install mingw-w64` 交叉编译）：

```
make        # 产出 browser.exe
```

## 运行

```
./browser.exe
NAV file:///C:/path/to/sample.html
QUIT

# 或图形前端
python3 gui/browser_gui.py "file:///C:/path/to/sample.html"
```

## 当前状态

- 本 cut 实现 `file://` 导航、HTML 文本/标题/链接/实体渲染，输出与 Linux 版相同的 `C/T/A/N/E/D` 指令。
- http/https 走 Winsock，链接位已留但未实现；导航到非 file:// 会打印 `E` 而不静默失败。
- 源码已用 GNU as 做过汇编语法体检；Windows 上的完整实跑请在装好 MinGW-w64 的环境 `make` 验证。
