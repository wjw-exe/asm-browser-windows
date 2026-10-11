import re, pathlib
p = pathlib.Path(r"D:\at\asm-browser-windows-main\win\kernel.S")
src = pathlib.Path(r"D:\at\asm-browser-windows-main\test_orig.S").read_text(encoding="utf-8")

# 1. starts_with: swap args (rdi=url, rsi=prefix)
src = src.replace(
    "    lea rdi, [rip+s_file]          /* \"file://\" */\n    call starts_with",
    "    mov rdi, [rbp-8]\n    lea rsi, [rip+s_file]\n    call starts_with",
)

# 2. file:/// offset: add rcx, 7 -> add rcx, 8
src = src.replace("    add rcx, 7                     /* skip \"file://\" */",
                  "    add rcx, 8")

# 3. docbuf: pass address not content
src = src.replace("    mov rcx, [rip+docbuf]", "    lea rcx, [rip+docbuf]")

# 4. Rewrite file_load_drive entirely
new_func = '''file_load_drive:
    push rbp
    mov rbp, rsp
    sub rsp, 0x50
    mov [rbp-0x08], rcx
    mov rcx, [rbp-0x08]
    movabs rdx, 0x80000000
    mov r8d, 1
    xor r9d, r9d
    mov dword ptr [rsp+0x20], 3
    mov qword ptr [rsp+0x28], 0
    mov qword ptr [rsp+0x30], 0
    call CreateFileA
    mov [rbp-0x10], rax
    cmp rax, -1
    je .fl_fail
    mov rcx, rax
    xor edx, edx
    call GetFileSize
    mov [rbp-0x14], eax
    cmp eax, 65000
    jb 1f
    mov eax, 65000
1:
    mov rcx, [rbp-0x10]
    lea rdx, [rip+docbuf]
    mov r8d, eax
    lea r9, [rip+nb_read]
    mov qword ptr [rsp+0x20], 0
    call ReadFile
    test rax, rax
    jz .fl_close
    mov eax, [rbp-0x14]
    mov [rip+doclen], eax
    mov rax, 1
.fl_close:
    mov rcx, [rbp-0x10]
    call CloseHandle
    jmp .fl_out
.fl_fail:
    xor eax, eax
.fl_out:
    mov rsp, rbp
    pop rbp
    ret
'''

# Replace from "file_load_drive:" up to (not including) the comment block before read_line
# Find start
start = src.index("file_load_drive:")
# Find the comment block that precedes read_line: it starts with "/* ---" before read_line
read_line_idx = src.index("read_line:")
# Walk back to find the comment opener
comment_start = src.rindex("/* ---", 0, read_line_idx)
src = src[:start] + new_func + "\n" + src[comment_start:]

p.write_text(src, encoding="utf-8", newline="\n")
print("done, lines:", src.count("\n"))
