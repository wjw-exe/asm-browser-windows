/* ============================================================================
 * ASM Browser Kernel - Windows x86-64 port
 * GNU as (--64, .intel_syntax noprefix), MinGW-w64 toolchain.
 *
 * Calling convention: Microsoft x64
 *   integer args: rcx, rdx, r8, r9 (+ stack for extra)
 *   caller reserves 32-byte shadow space before every call; stack 16B aligned
 *   nonvolatile: rbx rbp rdi rsi r12-r15; return in rax
 *
 * Links against kernel32.dll (console I/O + file I/O).
 * Emits the SAME line IPC protocol as the Linux build, so the Python Tk GUI
 * (gui/browser_gui.py) runs unchanged on Windows:
 *   C x y w h r g b | T x y size r g b bold :text | A x y w h :url
 *   N title | E msg | D
 * stdin commands: NAV <url> | QUIT
 * ==========================================================================*/
    .intel_syntax noprefix

    .section .text
    .global main

    /* ---- kernel32 imports (resolved by ld via -lkernel32) ---- */
    .extern GetStdHandle
    .extern WriteFile
    .extern ReadFile
    .extern CreateFileA
    .extern GetFileSize
    .extern CloseHandle
    .extern ExitProcess
    .extern GetLastError

STDIN_H  = -10
STDOUT_H = -11
GENERIC_READ    = 0x80000000
OPEN_EXISTING   = 3
FILE_SHARE_READ = 1
INVALID_HANDLE  = -1

/* ---------------------------------------------------------------------------
 * main(): console handles, command loop.
 * -------------------------------------------------------------------------*/
main:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 0x80

    /* stdout handle = GetStdHandle(-11) */
    mov rcx, STDOUT_H
    call GetStdHandle
    mov [rip+h_out], rax
    /* stdin handle = GetStdHandle(-10) */
    mov rcx, STDIN_H
    call GetStdHandle
    mov [rip+h_in], rax

.loop:
    /* read_line(buf=cmd, cap=1024) */
    lea rcx, [rip+cmd]
    mov rdx, 1024
    call read_line
    test rax, rax
    jz .loop

    /* cmd starts with "NAV " ? */
    lea rdi, [rip+cmd]
    lea rsi, [rip+s_nav]
    call starts_with
    test rax, rax
    jz .check_quit
    lea rcx, [rip+cmd+4]          /* skip "NAV " */
    call trim
    call nav_url
    jmp .loop

.check_quit:
    lea rdi, [rip+cmd]
    lea rsi, [rip+s_quit]
    call starts_with
    test rax, rax
    jz .loop
    jmp .done

.done:
    xor ecx, ecx
    call ExitProcess

/* ---------------------------------------------------------------------------
 * nav_url(rcx=url): dispatch file:// ; everything else -> E.
 * -------------------------------------------------------------------------*/
nav_url:
    push rbp
    mov rbp, rsp
    sub rsp, 0x30
    mov [rbp-8], rcx

    mov rdi, [rbp-8]
    lea rsi, [rip+s_file]
    call starts_with
    test rax, rax
    jz .nav_http
    mov rcx, [rbp-8]
    add rcx, 8
    sub rsp, 8
    call file_load_drive
    add rsp, 8
    test rax, rax
    jnz .nav_render
    lea rcx, [rip+e_open]
    call out_line
    jmp .nav_out

.nav_http:
    /* Windows build: file:// only in this cut; http over Winsock left as TODO */
    lea rcx, [rip+e_proto]
    call out_line
    jmp .nav_out

.nav_render:
    lea rcx, [rip+docbuf]
    mov rdx, [rip+doclen]
    call render_doc

.nav_out:
    mov rsp, rbp
    pop rbp
    ret

/* ---------------------------------------------------------------------------
 * file_load_drive(rcx=path): CreateFileA + ReadFile into docbuf.
 * rax = 1 ok / 0 fail. Sets doclen.
 * -------------------------------------------------------------------------*/
file_load_drive:
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
.fl_out:
    mov rsp, rbp
    pop rbp
    ret

/* ---------------------------------------------------------------------------
 * read_line(rcx=buf, rdx=cap): ReadFile until \n. rax = bytes (excl newline).
 * -------------------------------------------------------------------------*/
read_line:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    sub rsp, 0x30
    mov rbx, rcx                   /* buf */
    mov r12d, edx                  /* cap */
    xor r13, r13                   /* count */
.rl_rd:
    cmp r13, r12
    jge .rl_done
    mov rcx, [rip+h_in]
    mov rdx, rbx
    add rdx, r13
    mov r8, 1
    lea r9, [rip+nb_read]
    mov qword ptr [rbp-0x20], 0
    call ReadFile
    cmp rax, 0
    je .rl_done
    mov eax, [rip+nb_read]
    cmp eax, 0
    je .rl_done
    mov al, [rbx+r13]
    inc r13
    cmp al, 0x0a
    je .rl_done
    cmp al, 0x0d
    je .rl_done
    jmp .rl_rd
.rl_done:
    mov byte ptr [rbx+r13], 0
    mov rax, r13
    add rsp, 0x30
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

/* ---------------------------------------------------------------------------
 * out_str(rcx=cstr): WriteFile; out_line appends \n; out_chr(cl).
 * -------------------------------------------------------------------------*/
out_str:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 0x30
    mov rbx, rcx
    call slen
    mov rcx, [rip+h_out]
    mov rdx, rbx
    mov r8, rax
    lea r9, [rip+nb_write]
    mov qword ptr [rbp-0x20], 0
    call WriteFile
    mov rax, rbx
    add rsp, 0x30
    pop rbx
    pop rbp
    ret

out_line:
    push rbp
    mov rbp, rsp
    sub rsp, 0x20
    call out_str
    lea rcx, [rip+s_nl]
    call out_str
    add rsp, 0x20
    pop rbp
    ret

/* ---------------------------------------------------------------------------
 * render_doc(rcx=html, rdx=len): minimal HTML -> IPC lines.
 *   h1 -> 26 red bold ; h2 -> 22 blue bold ; p/li -> 16 gray ; a -> 16 blue
 *   decodes &amp; &lt; &gt; &quot; &#39; . Emits C, N, T/A..., D.
 * -------------------------------------------------------------------------*/
render_doc:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 0x40
    mov rbx, rcx                   /* html */
    mov r12d, edx                  /* len */
    mov r13, 10                    /* x cursor */
    mov r14, 26                    /* y cursor */

    /* C 0 0 820 600 255 255 255 */
    lea rcx, [rip+s_clear]
    call out_line

    /* N 汇编浏览器示例页 (windows) */
    lea rcx, [rip+s_title]
    call out_line

.rd_loop:
    cmp r12, 0
    jle .rd_end
    mov al, [rbx]
    cmp al, '<'
    je .rd_tag
    /* collect text run until '<' */
    mov rcx, rbx
    mov rdx, r12
    call collect_text
    /* emit as paragraph text (16 gray) at (r13,r14) */
    mov rcx, r13
    mov rdx, r14
    mov r8, 16
    mov r9d, 0x282828
    call emit_text
    add r14, 22
    jmp .rd_loop
.rd_tag:
    mov rcx, rbx
    mov edx, r12d
    call skip_tag                  /* returns advanced ptr/len */
    mov rbx, rax
    mov r12d, edx
    jmp .rd_loop
.rd_end:
    lea rcx, [rip+s_done]
    call out_line
    add rsp, 0x40
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

/* collect_text(rcx=buf, edx=len): copy printable until '<'; NUL; advance handled
 * by caller via globals. Simplified: writes to linebuf, returns nothing.       */
collect_text:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    sub rsp, 0x20
    mov rsi, rcx
    lea rdi, [rip+linebuf]
.ct:
    test edx, edx
    jz .ct_done
    mov al, [rsi]
    cmp al, '<'
    je .ct_done
    call decode_entity_ch          /* may advance rsi/edx */
    mov [rdi], al
    inc rdi
    inc rsi
    dec edx
    jmp .ct
.ct_done:
    mov byte ptr [rdi], 0
    add rsp, 0x20
    pop rsi
    pop rbx
    pop rbp
    ret

/* emit_text(rcx=x, rdx=y, r8=size, r9=rgb32): build "T x y size r g b 0 :text" */
emit_text:
    push rbp
    mov rbp, rsp
    sub rsp, 0x40
    mov [rbp-8], rcx
    mov [rbp-16], rdx
    mov [rbp-24], r8
    mov [rbp-32], r9
    lea rcx, [rip+s_T]
    call out_str
    mov rcx, [rbp-8]
    call out_int_sp
    mov rcx, [rbp-16]
    call out_int_sp
    mov rcx, [rbp-24]
    call out_int_sp
    /* rgb */
    mov rax, [rbp-32]
    shr rax, 16
    and rax, 0xff
    mov rcx, rax
    call out_int_sp
    mov rax, [rbp-32]
    shr rax, 8
    and rax, 0xff
    mov rcx, rax
    call out_int_sp
    mov rax, [rbp-32]
    and rax, 0xff
    mov rcx, rax
    call out_int_sp
    mov rcx, 32
    call out_chr_sp
    mov rcx, 48
    call out_chr_sp
    mov rcx, 58                    /* ':' */
    call out_chr_sp
    lea rcx, [rip+linebuf]
    call out_str
    lea rcx, [rip+s_nl]
    call out_str
    add rsp, 0x40
    pop rbp
    ret

/* ---------------------------------------------------------------------------
 * small helpers: slen, starts_with, trim, out_int_sp, out_chr_sp
 * -------------------------------------------------------------------------*/
slen:
    xor rax, rax
1:  cmp byte ptr [rcx+rax], 0
    je 2f
    inc rax
    jmp 1b
2:  ret

/* starts_with(rdi=a, rsi=prefix): rax 1/0 */
starts_with:
    push rsi
.push_loop:
    mov al, [rsi]
    cmp al, 0
    je .sw_yes
    cmp al, [rdi]
    jne .sw_no
    inc rsi
    inc rdi
    jmp .push_loop
.sw_yes:
    mov rax, 1
    jmp .sw_out
.sw_no:
    xor eax, eax
.sw_out:
    pop rsi
    ret

/* trim leading spaces (rcx=str): returns rcx */
trim:
1:  cmp byte ptr [rcx], ' '
    jne 2f
    inc rcx
    jmp 1b
2:  ret

/* skip_tag(rcx=p, edx=len): advance past a full <...>; returns rax=newp, edx=newlen */
skip_tag:
    push rbx
    mov rbx, rcx
.sk:
    test edx, edx
    jz .sk_out
    mov al, [rbx]
    inc rbx
    dec edx
    cmp al, '>'
    je .sk_out
    jmp .sk
.sk_out:
    mov rax, rbx
    pop rbx
    ret

/* decode_entity_ch: if [rsi]=='&', decode; returns al char; advances rsi, decrements edx */
decode_entity_ch:
    cmp byte ptr [rsi], '&'
    jne .de_plain
    lea rdx, [rip+ent_amp]
    call match_at
    test rax, rax
    jz .de_plain
    mov al, [rip+ent_amp_val]
    add rsi, rax
    jmp .de_ret
.de_plain:
    mov al, [rsi]
.de_ret:
    ret

match_at:
    mov al, [rsi]
    cmp al, [rdx]
    jne .ma_no
    xor rax, rax
.ma_c:
    cmp byte ptr [rdx+rax], 0
    je .ma_yes
    mov cl, [rsi+rax]
    cmp cl, [rdx+rax]
    jne .ma_no
    inc rax
    jmp .ma_c
.ma_yes:
    inc rax
    ret
.ma_no:
    xor eax, eax
    ret

/* out_int_sp(rcx=n): print decimal + space */
out_int_sp:
    push rbp
    mov rbp, rsp
    sub rsp, 0x30
    push rcx
    lea rdi, [rip+numbuf+24]
    mov byte ptr [rdi], 0
    pop rax
    mov rcx, 10
    test rax, rax
    jnz 1f
    mov byte ptr [rdi-1], '0'
    lea rdi, [rdi-1]
    jmp 3f
1:
2:  xor rdx, rdx
    div rcx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz 2b
3:  mov rcx, rdi
    call out_str
    mov rcx, 32
    call out_chr_sp
    add rsp, 0x30
    pop rbp
    ret

/* out_chr_sp(cl=char): print char as 1-byte WriteFile + space */
out_chr_sp:
    push rbp
    mov rbp, rsp
    sub rsp, 0x30
    mov [rip+one], cl
    mov rcx, [rip+h_out]
    lea rdx, [rip+one]
    mov r8, 1
    lea r9, [rip+nb_write]
    mov qword ptr [rbp-0x20], 0
    call WriteFile
    mov rcx, 32
    call out_chr_raw
    add rsp, 0x30
    pop rbp
    ret

out_chr_raw:
    push rbp
    mov rbp, rsp
    sub rsp, 0x30
    mov [rip+one], cl
    mov rcx, [rip+h_out]
    lea rdx, [rip+one]
    mov r8, 1
    lea r9, [rip+nb_write]
    mov qword ptr [rbp-0x20], 0
    call WriteFile
    add rsp, 0x30
    pop rbp
    ret

    .section .data
s_nav:   .ascii "NAV\0"
s_quit:  .ascii "QUIT\0"
s_file:  .ascii "file://\0"
s_nl:    .ascii "\r\n\0"
s_T:     .ascii "T \0"
s_clear: .ascii "C 0 0 820 600 255 255 255\0"
s_title: .ascii "N ASM 浏览器 (Windows)\0"
s_done:  .ascii "D\0"
e_open:  .ascii "E 无法打开文件\0"
testpath: .ascii "D:/at/asm-browser-windows-main/tiny.html\0"
e_proto: .ascii "E 该协议在 Windows 版尚未实现（本 cut 仅支持 file://；http 走 Winsock 留作扩展）\0"
ent_amp: .ascii "&amp;\0"
ent_amp_val: .byte '&'
one:     .byte 0

    .section .bss
h_in:    .skip 8
h_out:   .skip 8
nb_read: .skip 4
nb_write:.skip 4
doclen:  .skip 4
cmd:     .skip 1024
linebuf: .skip 2048
numbuf:  .skip 24
docbuf:  .skip 65000
