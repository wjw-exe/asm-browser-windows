#!/usr/bin/env python3
# browser_gui.py — 汇编浏览器内核的 Python GUI 前端
# 通过管道与内核进程通信：发送 NAV 命令，接收绘制指令流并渲染。
import os
import queue
import subprocess
import sys
import threading
import tkinter as tk

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KERNEL = os.path.join(ROOT, "kernel.exe")
SAMPLE = os.path.join(ROOT, "tests", "sample.html")


class AsmBrowser(tk.Tk):
    def __init__(self, start_url=None):
        super().__init__()
        self.title("ASM 浏览器内核 — 汇编 + Python GUI")
        self.geometry("880x700")
        self.q = queue.Queue()
        self.links = []
        self.history = []
        self.hist_pos = -1
        self.loading = False

        self.kernel = subprocess.Popen(
            [KERNEL], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            text=True, bufsize=1)
        t = threading.Thread(target=self._reader, daemon=True)
        t.start()

        self._build_ui()
        self.protocol("WM_DELETE_WINDOW", self._quit)
        self.after(50, self._poll)
        url = start_url or ("file://" + SAMPLE)
        self._navigate(url)

    # ---------- UI ----------
    def _build_ui(self):
        bar = tk.Frame(self)
        bar.pack(side="top", fill="x", padx=4, pady=4)
        self.btn_back = tk.Button(bar, text="◀ 后退", command=self._back)
        self.btn_back.pack(side="left")
        self.btn_fwd = tk.Button(bar, text="前进 ▶", command=self._forward)
        self.btn_fwd.pack(side="left")
        self.entry = tk.Entry(bar)
        self.entry.pack(side="left", fill="x", expand=True, padx=4)
        self.entry.bind("<Return>", lambda e: self._navigate(self.entry.get()))
        tk.Button(bar, text="前往", command=lambda: self._navigate(self.entry.get())).pack(side="left")

        self.canvas = tk.Canvas(self, width=840, height=620, bg="white",
                                highlightthickness=0)
        self.canvas.pack(side="top", fill="both", expand=True, padx=6)
        self.canvas.bind("<Button-1>", self._on_click)

        self.status = tk.Label(self, text="就绪", anchor="w", fg="#444")
        self.status.pack(side="bottom", fill="x", padx=6, pady=2)

    # ---------- 内核通信 ----------
    def _reader(self):
        try:
            for line in self.kernel.stdout:
                self.q.put(line.rstrip("\n"))
        except Exception:
            pass

    def _send(self, cmd):
        try:
            self.kernel.stdin.write(cmd + "\n")
            self.kernel.stdin.flush()
        except (BrokenPipeError, OSError):
            self.status.config(text="内核进程已退出")

    def _poll(self):
        try:
            while True:
                line = self.q.get_nowait()
                self._handle(line)
        except queue.Empty:
            pass
        self.after(50, self._poll)

    def _handle(self, line):
        if not line:
            return
        cmd = line[0]
        rest = line[1:].strip()
        if cmd == "C":
            self.canvas.delete("all")
        elif cmd == "T":
            body = rest.split(":", 1)[1] if ":" in rest else ""
            f = rest.split(":", 1)[0].split()
            if len(f) >= 7:
                x, y, size, r, g, b, bold = (int(f[0]), int(f[1]), int(f[2]),
                                             int(f[3]), int(f[4]), int(f[5]), int(f[6]))
                font = ("Helvetica", max(size, 8), "bold" if bold else "normal")
                self.canvas.create_text(x, y, text=body, anchor="nw",
                                        fill="#%02x%02x%02x" % (r, g, b), font=font)
        elif cmd == "A":
            body = rest.split(":", 1)[1] if ":" in rest else ""
            f = rest.split(":", 1)[0].split()
            if len(f) >= 4:
                x, y, w, h = int(f[0]), int(f[1]), int(f[2]), int(f[3])
                self.links.append((x, y, w, h, body))
        elif cmd == "N":
            self.title(rest or "ASM 浏览器内核")
        elif cmd == "E":
            self.status.config(text="错误：" + rest, fg="red")
        elif cmd == "S":
            self.status.config(text=rest, fg="#444")
        elif cmd == "D":
            self.status.config(text="完成（内核渲染结束）", fg="#2e7d32")
            self.loading = False

    # ---------- 导航 ----------
    def _navigate(self, url):
        url = (url or "").strip()
        if not url:
            return
        self.status.config(text="正在导航：" + url, fg="#1565c0")
        self.loading = True
        self.links = []
        self._send("NAV " + url)
        # 记录历史（去重相邻）
        if not self.history or self.history[self.hist_pos] != url:
            del self.history[self.hist_pos + 1:]
            self.history.append(url)
            self.hist_pos = len(self.history) - 1
        self.entry.delete(0, "end")
        self.entry.insert(0, url)
        self._update_btns()

    def _back(self):
        if self.hist_pos > 0:
            self.hist_pos -= 1
            self._navigate(self.history[self.hist_pos])

    def _forward(self):
        if self.hist_pos < len(self.history) - 1:
            self.hist_pos += 1
            self._navigate(self.history[self.hist_pos])

    def _update_btns(self):
        self.btn_back.config(state="normal" if self.hist_pos > 0 else "disabled")
        self.btn_fwd.config(state="normal" if self.hist_pos < len(self.history) - 1 else "disabled")

    def _on_click(self, ev):
        for (x, y, w, h, url) in reversed(self.links):
            if x <= ev.x <= x + w and y <= ev.y <= y + h:
                if url:
                    self._navigate(url)
                return

    def _quit(self):
        try:
            self._send("QUIT")
            self.kernel.stdin.close()
        except Exception:
            pass
        try:
            self.kernel.wait(timeout=2)
        except Exception:
            self.kernel.kill()
        self.destroy()


def main():
    start = sys.argv[1] if len(sys.argv) > 1 else None
    app = AsmBrowser(start)
    app.mainloop()


if __name__ == "__main__":
    main()
