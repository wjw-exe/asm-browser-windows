# asm-browser-windows

一个教学级浏览器：**C 写的极简内核 + Python Tkinter 前端**，跑在 Windows x86-64 上。
[Linux 版](https://github.com/wjw-exe/asm-browser-linux) 的 Windows 移植。

## 它是什么

- **内核**（`kernel.c`）：负责开文件 / 发 HTTP 请求 / 扫描 HTML，按行往 stdout 吐绘制指令。
- **前端**（`gui/browser_gui.py`）：Tkinter 画布，读 stdin 的指令流把文字画出来。
- 两者通过 stdin/stdout 的行式 IPC 解耦——内核是无窗口的控制台程序，前端是 Python 进程。

## 功能

| 能力 | 状态 |
|---|---|
| `file://` 打开本地 HTML | ✅ |
| `http://` 明文 80 端口 | ✅（Winsock2） |
| `https://` | ❌（未接 TLS） |
| HTML 标签跳过 / 文本提取 | ✅ |
| 中文 / 符号 / emoji | ✅ |
| 实体 `&amp; &lt;` | ⚠️ 原样输出，未解码 |
| CSS / JS / 排版 | ❌（纯文本流，无盒模型） |

## 构建

依赖：[MinGW-w64](https://www.mingw-w64.org/)（`gcc` 在 PATH 里）。

```
gcc kernel.c -o kernel.exe -lkernel32 -lws2_32
```

产出 `kernel.exe`（前端默认找这个名字）。

## 运行

直接跑内核（管道 IPC）：

```
echo NAV file:///C:/path/to/page.html | ./kernel.exe
```

或启动图形前端：

```
python gui/browser_gui.py
```

然后在地址栏输 URL，例如：

```
http://example.com
file:///D:/at/asm-browser-windows-main/tests/test.html
```

## IPC 协议

内核 stdout 每行一条指令，前端解析：

| 指令 | 含义 |
|---|---|
| `C x y w h r g b` | 清屏，设置画布大小和背景色 |
| `N 标题` | 设窗口标题 |
| `T x y size r g b bold :文本` | 在 (x,y) 画一段文字 |
| `A x y w h :href` | 注册一个可点击链接热区 |
| `E 错误信息` | 状态栏报错 |
| `S 状态信息` | 状态栏提示 |
| `D` | 本页渲染结束 |

前端往 stdin 写 `NAV <url>` 导航，`QUIT` 退出。

## 目录

```
kernel.c              内核（C，文件 + HTTP + HTML 扫描 + IPC）
gui/browser_gui.py    Tkinter 前端
tests/test.html       测试页（标题/段落/列表/实体/emoji）
tests/sample.html     演示页
win/kernel.S          早期手写 Win64 汇编版（保留作历史，未启用）
```

## 已知限制

- 只支持 `http://` 80 端口；`https://` 需要 TLS。
- 渲染是"跳标签、吐文本块"：`<style>` 内容会当正文画出来，没有 CSS 选择器。
- 无 JS、无 cookie、无缓存、无重定向跟随。
- 单线程，HTTP 请求时 UI 会卡住直到响应回来。
