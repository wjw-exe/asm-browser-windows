#include <windows.h>
#include <stdio.h>
int main(){
  const char* paths[] = {
    "D:/at/asm-browser-windows-main/tests/sample.html",
    "D:\\at\\asm-browser-windows-main\\tests\\sample.html",
    "sample.html",
    NULL
  };
  for(int i=0; paths[i]; i++){
    HANDLE h = CreateFileA(paths[i], GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    printf("path=%s h=%p err=%lu\n", paths[i], (void*)h, GetLastError());
    if(h!=INVALID_HANDLE_VALUE) CloseHandle(h);
  }
  return 0;
}
