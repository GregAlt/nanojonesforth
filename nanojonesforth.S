/* NanoJonesForth is a project to shrink the assembly language from jonesforth,
   moving words into forth source while maintaining compatibility.

   I'm trying to balance a few somewhat conflicting goals:
   - Minimal nanojonesforth.S file size
   - Simple and straightforward nanojonesforth.S file (no obfuscations)
   - Minimal stripped .elf result
   - No assembly language outside of forth definitions
   - Minimal number of defcode words
   - No complex defcode words
   - Minimal number of defvar and defconst words
   - After reducing defcode words, minimal number of defword compiled forth words
   - Good performance is not a goal, but I'll avoid gratuitous bad performance
   - Compatibility with jonesforth, including all tests passing
       (with minor adjustments for specific offsets in exception and stack tests)
   - No handcrafted .elf - the elf will be built with standard tools and stripped
   
*/

/*	A sometimes minimal FORTH compiler and tutorial for Linux / i386 systems. -*- asm -*-
	By Richard W.M. Jones <rich@annexia.org> http://annexia.org/forth
	This is PUBLIC DOMAIN (see public domain release statement below).
	$Id: jonesforth.S,v 1.47 2009-09-11 08:33:13 rich Exp $

	gcc -m32 -nostdlib -static -Wl,-Ttext,0 -Wl,--build-id=none -o jonesforth jonesforth.S
*/

//#include <asm-i386/unistd.h>	// you might need this instead
#include <asm/unistd.h>

/* Macros ---------------------------------------------------------------------- */
	.macro NEXT
	lodsl
	jmp *(%eax)
	.endm

	.set link,0	// initial chain of links
	.macro defheader name, namelen, flags=0, label
	.section .data
	.align 4
 	.globl name_\label
name_\label :
	.int link		// link
	.set link,name_\label
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.align 4		// padding to next 4 byte boundary
	.globl \label
\label :
	.endm

	.macro defword name, namelen, flags=0, label
	defheader "\name", \namelen, \flags, \label
	.int code_DOCOL		// codeword - the interpreter
	.endm			// list of word pointers follow

	.macro defcode name, namelen, flags=0, label
	defheader "\name", \namelen, \flags, \label
	.int code_\label
	.text
	.globl code_\label
code_\label :			// assembler code follows
	.endm

	.macro defvar name, namelen, flags=0, label, initial=0, align=4, size=4
	.set size_\name,\size
	defcode \name,\namelen,\flags,\label
	push $var_\name
	NEXT
	.if \size == 4 ; .data ; .else  ; .bss ; .endif
	.align \align
var_\name : .if \size == 4 ; .int \initial ; .else ; .space \size ; .endif
	.endm

	.macro defconst name, namelen, flags=0, label, value
	.set value_\name,\value
	defcode \name,\namelen,\flags,\label
	push $\value
	NEXT
	.endm

/* defcode assembley word definitions ------------------------------------------------------ */

	defcode "start__",3,,start // code_start is assembler entry point. 
	cld
	mov $(COLD_START+4),%esi // Initialise interpreter.
	NEXT			// Run interpreter!

	defcode "DOCOL__",3,,DOCOL // DOCOL - the interpreter! 
	lea -4(%ebp),%ebp	// push %esi on to return stack
	movl %esi,(%ebp)
	addl $4,%eax            // %eax points to codeword, so make
	movl %eax,%esi          // %esi point to first data word
	NEXT

	defcode "DROP___",3,,DROP  // inlined later
	pop %eax		// drop top of stack
	NEXT

	defcode "SWAP___",3,,SWAP  // inlined later
	pop %eax		// swap top two elements on stack
	pop %ebx
	push %eax
	push %ebx
	NEXT

	defcode "DUP____",3,,DUP    // inlined later
	mov (%esp),%eax		// duplicate top of stack
	push %eax
	NEXT

	defcode "1+_____",3,,INCR    // inlined later
	incl (%esp)             // increment top of stack
	NEXT

	defcode "-______",3,,SUB
	pop %eax		// get top of stack
	subl %eax,(%esp)	// and subtract it from next word on stack
	NEXT

	defcode "*______",3,,MUL
	pop %eax
	pop %ebx
	imull %ebx,%eax
	push %eax		// ignore overflow
	NEXT

	defcode "/MOD___",3,,DIVMOD
	xor %edx,%edx
	pop %ebx
	pop %eax
	idivl %ebx
	push %edx		// push remainder
	push %eax		// push quotient
	NEXT

	defcode "<______",3,,LT
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setl %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "NAND___",3,,NAND    // bitwise NAND
	pop %eax
	andl %eax,(%esp)
	notl (%esp)
	NEXT

	defcode "EXIT___",3,,EXIT
	mov (%ebp),%esi		// pop return stack into %esi	
	lea 4(%ebp),%ebp
	NEXT

	defcode "@______",3,,FETCH
	pop %ebx		// address to fetch
	mov (%ebx),%eax		// fetch it
	push %eax		// push value onto stack
	NEXT

	defcode "!______",3,,STORE
	pop %ebx		// address to store at
	pop %eax		// data to store there
	mov %eax,(%ebx)		// store it
	NEXT

	defcode "C@_____",3,,FETCHBYTE // inlined later
	pop %ebx		// address to fetch
	xor %eax,%eax
	movb (%ebx),%al		// fetch it
	push %eax		// push value onto stack
	NEXT

	defcode "C!_____",3,,STOREBYTE
	pop %ebx		// address to store at
	pop %eax		// data to store there
	movb %al,(%ebx)		// store it
	NEXT

	defcode "RSP@___",3,,RSPFETCH
	push %ebp
	NEXT

	defcode "R!P!___",3,,RSPSTORE
	pop %ebp
	NEXT

	defcode "DSP@___",3,,DSPFETCH
	mov %esp,%eax
	push %eax
	NEXT

	defcode "D!P!___",3,,DSPSTORE
	pop %esp
	NEXT

	defcode "EXECUTE",3,,EXECUTE
	pop %eax		// Get xt into %eax
	jmp *(%eax)		// and jump to it. After xt runs its NEXT will continue w/ current word.

	defcode "SYSCALL",3,,SYSCALL3
	pop %eax		// System call number (see <asm/unistd.h>)
	pop %ebx		// First parameter.
	pop %ecx		// Second parameter
	pop %edx		// Third parameter
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

/*  built-in variables and constants ------------------------------------------- */

	defvar "HERE___",3,,HERE
	defvar "LATEST_",3,,LATEST,name_QUIT0 // QUIT0 must be last in built-in dictionary
	defvar "S0_____",3,,SZ
	defvar "RET_STA",3,,RETURN_STACK,,4096,8192
	defvar "WB_____",3,,WB,,4,32
	defconst "INIT_SZ",3,,INITIAL_DATA_SEGMENT_SIZE,65536
	defconst "R0_____",3,,RZ,var_RET_STA+size_RET_STA  // initial return stack top
	defconst "G0_____",3,,G0,0 // useful constant 0
	defconst "G_4____",3,,G_4,-4 // useful constant -4
	defconst "SES_EXI",3,,SYS_EXIT,__NR_exit
	defconst "SOS_OPE",3,,SYS_OPEN,__NR_open
	defconst "SLS_CLO",3,,SYS_CLOSE,__NR_close
	defconst "SRS_REA",3,,SYS_READ,__NR_read
	defconst "SWS_WRI",3,,SYS_WRITE,__NR_write
	defconst "SCS_CRE",3,,SYS_CREAT,__NR_creat
	defconst "SBS_BRK",3,,SYS_BRK,__NR_brk

/* defword compiled forth word definitions ------------------------------------------------- */

	defword "COLD_ST",3,,COLD_START
	.int RZ, RSPSTORE, DSPFETCH, SZ, STORE, G0, DUP, DUP, DUP, DUP, SYS_BRK, SYSCALL3, DUP, HERE, STORE
	.int G0, INITIAL_DATA_SEGMENT_SIZE, SUB, SUB, SYS_BRK, SYSCALL3, DROP, QUIT0

	defword "0BRANCH",3,,ZBRANCH
	.int DUP, INCR, G0, SWAP, LT, SWAP, G0, INCR, LT, MUL, RSPFETCH, FETCH, DSPFETCH, G_4, SUB, FETCH
	.int DSPFETCH, G_4, SUB, FETCH, FETCH, G0, G_4, SUB, SUB, MUL, G0, SWAP, SUB, SUB, G_4, SUB
	.int RSPFETCH, STORE, DROP, EXIT

	defword "FIND0",3,,FIND // doesn't handle failure!
	.int FETCH, G_4, DUP, MUL, DUP, MUL, MUL, INCR, INCR, INCR, LATEST, FETCH, DSPFETCH, G_4, SUB, FETCH
	.int DSPFETCH, G_4, SUB, FETCH, G_4, SUB, FETCH, SUB, DUP, INCR, G0, SWAP, LT, SWAP,  G0, INCR, LT
	.int MUL, ZBRANCH, -96, SWAP, DROP, EXIT

	defword "KEY0",3,,KEY0
	.int G0, DSPFETCH, G0, INCR, SWAP, G0, SYS_READ, SYSCALL3, DROP, EXIT

	defword "WORD0",3,,WORD0
	.int G0, DSPFETCH, G0, DROP, KEY0, DUP, G_4, DUP, MUL, SUB, G_4, DUP, MUL, SWAP, LT, ZBRANCH, -52 
	.int SWAP, STOREBYTE, DSPFETCH, INCR, KEY0, SWAP, STOREBYTE, DSPFETCH, INCR, INCR, KEY0, SWAP
	.int STOREBYTE, WB, STORE, WB, KEY0, DROP, EXIT

	defword "QUIT0",3,,QUIT0  // QUIT0 must be last! (clear ret stack, interpret word, repeat)
	.int RZ, RSPSTORE, WORD0, FIND, G_4, SUB, G_4, SUB, G_4, SUB, EXECUTE, G0, ZBRANCH, -44  
/* END OF jonesforth.S */
