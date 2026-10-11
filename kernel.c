/* asm-browser-windows kernel in C — bypasses hand-written Win64 ABI bugs.
 * IPC over stdin/stdout:
 *   C 0 0 W H R G B   clear screen
 *   N title            set title
 *   T x y size r g b bold:text   emit text
 *   A x y w h:url       emit link
 *   E message          error
 *   S message          status
 *   D                  done */
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#pragma comment(lib, "ws2_32.lib")

static HANDLE hOut = NULL;
static char docbuf[65536];
static int doclen = 0;

static void out_raw(const char *s, int n) {
    if (!hOut) hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD wr;
    WriteFile(hOut, s, n, &wr, NULL);
}
static void out_line(const char *s) {
    out_raw(s, (int)strlen(s));
    out_raw("\n", 1);
}

static int starts_with(const char *a, const char *b) {
    while (*b) {
        if (*a != *b) return 0;
        a++; b++;
    }
    return 1;
}

static const char *skip_tag(const char *p, int *len) {
    while (*len > 0 && *p != '>') { p++; (*len)--; }
    if (*len > 0) { p++; (*len)--; }
    return p;
}

static void render_doc(const char *html, int len) {
    out_line("C 0 0 820 600 255 255 255");
    out_line("N ASM Browser");
    int x = 10, y = 26;
    const char *p = html;
    int rem = len;
    while (rem > 0) {
        if (*p == '<') { p = skip_tag(p, &rem); continue; }
        const char *start = p;
        int run = 0;
        while (rem > 0 && *p != '<') { p++; rem--; run++; }
        if (run == 0) continue;
        char line[1100];
        snprintf(line, sizeof(line), "T %d %d 16 40 40 40 0 :%.*s",
                 x, y, run, start);
        out_line(line);
        y += 22;
    }
    out_line("D");
}

static int file_load(const char *path) {
    HANDLE h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return 0;
    int size = (int)GetFileSize(h, NULL);
    if (size > 65000) size = 65000;
    DWORD got = 0;
    BOOL ok = ReadFile(h, docbuf, size, &got, NULL);
    CloseHandle(h);
    if (!ok) return 0;
    docbuf[got] = 0;
    doclen = (int)got;
    return 1;
}

/* http://host:port/path  -> fetch, strip headers, put body in docbuf */
static int http_load(const char *url) {
    /* url starts with "http://" */
    const char *host = url + 7;
    const char *path = strchr(host, '/');
    char hostbuf[256];
    int hostlen;
    if (path) {
        hostlen = (int)(path - host);
    } else {
        hostlen = (int)strlen(host);
        path = "/";
    }
    if (hostlen >= (int)sizeof(hostbuf)) return 0;
    memcpy(hostbuf, host, hostlen);
    hostbuf[hostlen] = 0;

    /* split host:port */
    char *portstr = strchr(hostbuf, ':');
    int port = 80;
    if (portstr) {
        *portstr = 0;
        port = atoi(portstr + 1);
        if (port <= 0) port = 80;
    }

    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    char portstr2[16];
    snprintf(portstr2, sizeof(portstr2), "%d", port);
    if (getaddrinfo(hostbuf, portstr2, &hints, &res) != 0 || !res) return 0;

    SOCKET s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (s == INVALID_SOCKET) { freeaddrinfo(res); return 0; }
    if (connect(s, res->ai_addr, (int)res->ai_addrlen) == SOCKET_ERROR) {
        closesocket(s); freeaddrinfo(res); return 0;
    }
    freeaddrinfo(res);

    char req[1024];
    int rl = snprintf(req, sizeof(req),
        "GET %s HTTP/1.1\r\nHost: %s\r\nUser-Agent: AsmBrowser/0.1\r\nConnection: close\r\n\r\n",
        path, hostbuf);
    send(s, req, rl, 0);

    /* read whole response into a temp buffer */
    static char resp[131072];
    int total = 0;
    int n;
    while (total < (int)sizeof(resp) - 1 &&
           (n = recv(s, resp + total, sizeof(resp) - 1 - total, 0)) > 0) {
        total += n;
    }
    closesocket(s);
    resp[total] = 0;

    /* find end of headers: \r\n\r\n */
    char *body = strstr(resp, "\r\n\r\n");
    if (!body) {
        body = resp;
    } else {
        body += 4;
    }
    int blen = (int)strlen(body);
    if (blen > 65000) blen = 65000;
    memcpy(docbuf, body, blen);
    docbuf[blen] = 0;
    doclen = blen;
    return 1;
}

int main(void) {
    WSADATA wsa;
    WSAStartup(MAKEWORD(2, 2), &wsa);

    hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
    char cmd[2048];
    out_line("S ready");
    for (;;) {
        int n = 0;
        for (;;) {
            DWORD got = 0;
            if (!ReadFile(hIn, cmd + n, 1, &got, NULL) || got == 0) {
                WSACleanup();
                return 0;
            }
            char c = cmd[n];
            n++;
            if (c == '\n' || c == '\r') break;
            if (n >= (int)sizeof(cmd) - 1) break;
        }
        cmd[n] = 0;
        while (n > 0 && (cmd[n-1]=='\n' || cmd[n-1]=='\r' || cmd[n-1]==' ')) cmd[--n] = 0;

        if (strncmp(cmd, "QUIT", 4) == 0) { WSACleanup(); return 0; }
        if (strncmp(cmd, "NAV ", 4) != 0) continue;
        const char *url = cmd + 4;
        while (*url == ' ') url++;

        if (starts_with(url, "file://")) {
            const char *path = url + 7;
            if (path[0] == '/') path++;
            if (!file_load(path)) {
                out_line("E 无法打开本地文件");
                continue;
            }
            render_doc(docbuf, doclen);
        } else if (starts_with(url, "http://")) {
            out_line("S 正在连接...");
            if (!http_load(url)) {
                out_line("E http 请求失败");
                continue;
            }
            render_doc(docbuf, doclen);
        } else {
            out_line("E 未知协议");
        }
    }
}
