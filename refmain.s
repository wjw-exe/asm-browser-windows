	.file	"refmain.c"
	.text
	.globl	docbuf
	.bss
	.align 32
docbuf:
	.space 65000
	.globl	doclen
	.align 4
doclen:
	.space 4
	.section .rdata,"dr"
.LC0:
	.ascii "QUIT\0"
.LC1:
	.ascii "NAV \0"
.LC2:
	.ascii "file://\0"
.LC3:
	.ascii "E open err=%lu path=%s\12\0"
.LC4:
	.ascii "C 0 0 820 600 255 255 255\0"
.LC5:
	.ascii "N test\0"
.LC6:
	.ascii "T 10 40 16 0 0 0 :%s\12\0"
.LC7:
	.ascii "D\0"
	.text
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	pushq	%rbp
	.seh_pushreg	%rbp
	subq	$1168, %rsp
	.seh_stackalloc	1168
	leaq	128(%rsp), %rbp
	.seh_setframe	%rbp, 128
	.seh_endprologue
	call	__main
	movl	$-11, %ecx
	movq	__imp_GetStdHandle(%rip), %rax
	call	*%rax
	movq	%rax, 1008(%rbp)
	movl	$-10, %ecx
	movq	__imp_GetStdHandle(%rip), %rax
	call	*%rax
	movq	%rax, 1000(%rbp)
.L16:
	movl	$0, 1036(%rbp)
	jmp	.L2
.L6:
	movl	1036(%rbp), %eax
	cltq
	leaq	-48(%rbp), %rdx
	addq	%rax, %rdx
	leaq	-52(%rbp), %rcx
	movq	1000(%rbp), %rax
	movq	$0, 32(%rsp)
	movq	%rcx, %r9
	movl	$1, %r8d
	movq	%rax, %rcx
	movq	__imp_ReadFile(%rip), %rax
	call	*%rax
	movl	-52(%rbp), %eax
	testl	%eax, %eax
	je	.L19
	movl	1036(%rbp), %eax
	cltq
	movzbl	-48(%rbp,%rax), %eax
	cmpb	$10, %al
	je	.L20
	movl	1036(%rbp), %eax
	cltq
	movzbl	-48(%rbp,%rax), %eax
	cmpb	$13, %al
	je	.L20
	addl	$1, 1036(%rbp)
.L2:
	cmpl	$1022, 1036(%rbp)
	jle	.L6
	jmp	.L5
.L19:
	nop
	jmp	.L5
.L20:
	nop
.L5:
	movl	1036(%rbp), %eax
	cltq
	movb	$0, -48(%rbp,%rax)
	cmpl	$0, 1036(%rbp)
	je	.L21
	leaq	.LC0(%rip), %rdx
	leaq	-48(%rbp), %rax
	movl	$4, %r8d
	movq	%rax, %rcx
	call	memcmp
	testl	%eax, %eax
	je	.L22
	leaq	.LC1(%rip), %rdx
	leaq	-48(%rbp), %rax
	movl	$4, %r8d
	movq	%rax, %rcx
	call	memcmp
	testl	%eax, %eax
	jne	.L23
	leaq	-48(%rbp), %rax
	addq	$4, %rax
	movq	%rax, 1024(%rbp)
	jmp	.L12
.L13:
	addq	$1, 1024(%rbp)
.L12:
	movq	1024(%rbp), %rax
	movzbl	(%rax), %eax
	cmpb	$32, %al
	je	.L13
	leaq	.LC2(%rip), %rdx
	movq	1024(%rbp), %rax
	movl	$7, %r8d
	movq	%rax, %rcx
	call	memcmp
	testl	%eax, %eax
	jne	.L16
	movq	1024(%rbp), %rax
	addq	$8, %rax
	movq	%rax, 992(%rbp)
	movq	992(%rbp), %rax
	movq	$0, 48(%rsp)
	movl	$0, 40(%rsp)
	movl	$3, 32(%rsp)
	movl	$0, %r9d
	movl	$1, %r8d
	movl	$-2147483648, %edx
	movq	%rax, %rcx
	movq	__imp_CreateFileA(%rip), %rax
	call	*%rax
	movq	%rax, 984(%rbp)
	cmpq	$-1, 984(%rbp)
	jne	.L14
	movq	__imp_GetLastError(%rip), %rax
	call	*%rax
	movl	%eax, 980(%rbp)
	movq	992(%rbp), %rcx
	movl	980(%rbp), %edx
	leaq	.LC3(%rip), %rax
	movq	%rcx, %r8
	movq	%rax, %rcx
	call	printf
	jmp	.L16
.L14:
	movq	984(%rbp), %rax
	movl	$0, %edx
	movq	%rax, %rcx
	movq	__imp_GetFileSize(%rip), %rax
	call	*%rax
	movl	%eax, 1020(%rbp)
	cmpl	$65000, 1020(%rbp)
	jbe	.L15
	movl	$65000, 1020(%rbp)
.L15:
	leaq	-56(%rbp), %rcx
	movl	1020(%rbp), %r8d
	leaq	docbuf(%rip), %rdx
	movq	984(%rbp), %rax
	movq	$0, 32(%rsp)
	movq	%rcx, %r9
	movq	%rax, %rcx
	movq	__imp_ReadFile(%rip), %rax
	call	*%rax
	movq	984(%rbp), %rax
	movq	%rax, %rcx
	movq	__imp_CloseHandle(%rip), %rax
	call	*%rax
	movl	1020(%rbp), %eax
	movl	%eax, doclen(%rip)
	movl	doclen(%rip), %eax
	cltq
	leaq	docbuf(%rip), %rdx
	movb	$0, (%rax,%rdx)
	leaq	.LC4(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	.LC5(%rip), %rax
	movq	%rax, %rcx
	call	puts
	leaq	docbuf(%rip), %rdx
	leaq	.LC6(%rip), %rax
	movq	%rax, %rcx
	call	printf
	leaq	.LC7(%rip), %rax
	movq	%rax, %rcx
	call	puts
	jmp	.L16
.L21:
	nop
	jmp	.L16
.L23:
	nop
	jmp	.L16
.L22:
	nop
	movl	$0, %eax
	addq	$1168, %rsp
	popq	%rbp
	ret
	.seh_endproc
	.def	__main;	.scl	2;	.type	32;	.endef
	.ident	"GCC: (x86_64-mcf-seh-rev1, Built by MinGW-Builds project) 16.2.0"
	.def	memcmp;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
	.def	puts;	.scl	2;	.type	32;	.endef
