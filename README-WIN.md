# ASM Browser Kernel — Windows x86-64 版

本目录是同一款汇编浏览器内核的 Windows 移植，与 Linux 版（`../browser-kernel`）输出**完全相同的行式 IPC 协议**，因此 `gui/browser_gui.py` 在 Windows 上原样可用。

## 与 Linux 版的差异

| 项 | Linux 版 | Windows 版 |
|---|---|---|
| 系统接口 | Linux x86-64 原生 syscall | kernel32.dll 导出（GetStdHandle/ReadFile/WriteFile/CreateFileA/GetFileSize/CloseHandle），网络用 ws2_32（Winsock） |
| 调用约定 | System V AMD64 | Microsoft x64（rcx/rdx/r8/r9 + 32B 影子空间） |
| 文件格式 | ELF | PE (browser.exe) |
| 网络 | DNS/UDP/HTTP/代理（file:// 验证，http 沙箱内未决） | 本 cut 仅实现 file://；http 走 Winsock 留作扩展（代码里已留 `ws2_32` 链接位） |
| GUI | Tkinter（跨平台） | 同一份 `gui/browser_gui.py` |

## 构建

需要 MinGW-w64（Windows 上 MSYS2，或 Linux 上 `apt install mingw-w64` 后交叉编译）：

```
make          # 产出 browser.exe
```

## 运行

```
# 命令行直接喂 IPC：
./browser.exe
NAV file:///C:/path/to/sample.html
QUIT

# 或用图形前端（需 Windows 上装了 Python + Tk）：
python3 gui/browser_gui.py "file:///C:/path/to/sample.html"
```

## 诚实状态

- 本沙箱是 Linux，无 MinGW-w64，**未能在此链接出真正的 PE**；`win/kernel.S` 已用 GNU as 做过汇编语法体检（`as --64` 通过），但未在 Windows 上实跑。
- 解析/渲染为 Linux 版的精简移植（h1/h2/p/a、实体 `&amp;&lt;&gt;`、中文），同样输出 C/T/A/N/D 指令。
- http/https 在本 cut 不支持，导航到非 file:// 会打印 `E` 而不静默失败。
