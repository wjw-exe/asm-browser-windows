/* utils.S — 手写 x86-64 汇编工具函数，纯教学点缀。
 * 这些函数都是纯计算、不碰 Windows API，所以没有 ABI 坑。
 * Win64 调用约定：rcx/rdx/r8/r9 传前 4 个参数，rax 返回值。 */
    .intel_syntax noprefix
    .text

/* size_t asm_strlen(const char *s) — rdi 不被调用者保护，用 rcx 当入参。
 * 但 Win64 下第一个整型参数在 rcx，所以这里用 rcx。 */
    .globl asm_strlen
asm_strlen:
    push rbx
    mov rbx, rcx          /* s */
    xor eax, eax
.l:
    cmp byte ptr [rcx], 0
    je .done
    inc rax
    inc rcx
    jmp .l
.done:
    pop rbx
    ret

/* int asm_is_space(char c) — rcx = c，返回 1/0 */
    .globl asm_is_space
asm_is_space:
    cmp cl, ' '
    je .yes
    cmp cl, 9
    je .yes
    cmp cl, 10
    je .yes
    cmp cl, 13
    je .yes
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

/* void asm_upperc(char *s) — 原地把 ASCII 转大写，不碰 API */
    .globl asm_upperc
asm_upperc:
    push rbx
    push r12
    mov rbx, rcx          /* s */
.u:
    mov al, [rbx]
    test al, al
    jz .udone
    cmp al, 'a'
    jb .unext
    cmp al, 'z'
    ja .unext
    sub al, 32
    mov [rbx], al
.unext:
    inc rbx
    jmp .u
.udone:
    pop r12
    pop rbx
    ret
