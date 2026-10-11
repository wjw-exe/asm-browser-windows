import pathlib
p = pathlib.Path(r"D:\at\asm-browser-windows-main\win\kernel.S")
src = p.read_text(encoding="utf-8")

# Remove GetLastError debug
old = """.fl_fail:
    push rax
    push rcx
    push rdx
    push r10
    push r11
    call GetLastError
    mov rcx, rax
    call out_int_sp
    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rax
    xor eax, eax
.fl_out:"""
new = """.fl_fail:
    xor eax, eax
.fl_out:"""
src = src.replace(old, new)

# In file_load_drive, before CreateFileA, print the path
old2 = """    mov rcx, rdi                   /* path */
    movabs rdx, 0x80000000         /* GENERIC_READ */"""
new2 = """    mov rcx, rdi                   /* path */
    push rax
    push rcx
    push rdx
    push r10
    push r11
    call out_line
    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rax
    mov rcx, rdi
    movabs rdx, 0x80000000         /* GENERIC_READ */"""
src = src.replace(old2, new2)

p.write_text(src, encoding="utf-8", newline="\n")
print("ok")
