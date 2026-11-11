	.file	"kernel.c"
	.text
	.section	.rodata
	.align 4
.LC0:
	.string	"Hola desde nuestro primer kernel en C!"
	.text
	.globl	kernel_main
	.type	kernel_main, @function
kernel_main:
	pushl	%ebp
	movl	%esp, %ebp
	subl	$16, %esp
	movl	$.LC0, -8(%ebp)
	movl	$753664, -12(%ebp)
	movl	$0, -4(%ebp)
	jmp	.L2
.L3:
	movl	-8(%ebp), %edx
	movl	-4(%ebp), %eax
	addl	%edx, %eax
	movzbl	(%eax), %eax
	movzbl	%al, %eax
	orb	$15, %ah
	movl	%eax, %ecx
	movl	-4(%ebp), %eax
	leal	(%eax,%eax), %edx
	movl	-12(%ebp), %eax
	addl	%edx, %eax
	movl	%ecx, %edx
	movw	%dx, (%eax)
	addl	$1, -4(%ebp)
.L2:
	movl	-8(%ebp), %edx
	movl	-4(%ebp), %eax
	addl	%edx, %eax
	movzbl	(%eax), %eax
	testb	%al, %al
	jne	.L3
.L4:
/APP
/  11 "kernel/kernel.c" 1
	hlt
/  0 "" 2
/NO_APP
	jmp	.L4
	.size	kernel_main, .-kernel_main
	.ident	"GCC: (GNU) 16.2.0"
