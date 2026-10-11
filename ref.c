#include <windows.h>
int main(){
  HANDLE h = CreateFileA("D:\\at\\asm-browser-windows-main\\tests\\sample.html",
    GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
  if(h==INVALID_HANDLE_VALUE) return 1;
  CloseHandle(h);
  return 0;
}
