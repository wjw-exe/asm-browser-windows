#include <windows.h>
#include <stdio.h>
#include <string.h>

char docbuf[65000];
int doclen;

int main() {
    HANDLE hOut = GetStdHandle(-11);
    HANDLE hIn = GetStdHandle(-10);

    char cmd[1024];
    while (1) {
        int len = 0;
        while (len < 1023) {
            DWORD nr;
            ReadFile(hIn, cmd+len, 1, &nr, NULL);
            if (!nr) break;
            if (cmd[len]=='\n' || cmd[len]=='\r') break;
            len++;
        }
        cmd[len] = 0;
        if (len == 0) continue;
        if (memcmp(cmd, "QUIT", 4)==0) break;
        if (memcmp(cmd, "NAV ", 4)!=0) continue;
        char *url = cmd+4;
        while (*url==' ') url++;
        if (memcmp(url, "file://", 7)==0) {
            char *path = url+8;
            HANDLE h = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL,
                                   OPEN_EXISTING, 0, NULL);
            if (h == INVALID_HANDLE_VALUE) {
                DWORD e = GetLastError();
                printf("E open err=%lu path=%s\n", e, path);
            } else {
                DWORD sz = GetFileSize(h, NULL);
                if (sz > 65000) sz = 65000;
                DWORD nr;
                ReadFile(h, docbuf, sz, &nr, NULL);
                CloseHandle(h);
                doclen = sz;
                docbuf[doclen] = 0;
                printf("C 0 0 820 600 255 255 255\n");
                printf("N test\n");
                printf("T 10 40 16 0 0 0 :%s\n", docbuf);
                printf("D\n");
            }
        }
    }
    return 0;
}
