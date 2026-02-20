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
	.set JONES_VERSION,47
	.set F_IMMED,0x80
	.set F_HIDDEN,0x20
	.set F_LENMASK,0x1f	// length mask
	.set RETURN_STACK_SIZE,8192
	.set BUFFER_SIZE,4096

//#include <asm-i386/unistd.h>	// you might need this instead
#include <asm/unistd.h>

/* Macro definitions ----------------------------------------------------------------------- */
	.macro NEXT
	lodsl
	jmp *(%eax)
	.endm

	.macro PUSHRSP reg
	lea -4(%ebp),%ebp	// push reg on to return stack
	movl \reg,(%ebp)
	.endm

	.macro POPRSP reg
	mov (%ebp),\reg		// pop top of return stack to reg
	lea 4(%ebp),%ebp
	.endm

	.macro defconst name, namelen, flags=0, label, value
	defcode \name,\namelen,\flags,\label
	push $\value
	NEXT
	.endm

	// Store the chain of links.
	.set link,0

	.macro defword name, namelen, flags=0, label
	.section .rodata
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
	.int code_DOCOL		// codeword - the interpreter
	// list of word pointers follow
	.endm

	.macro defcode name, namelen, flags=0, label
	.section .rodata
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
	.int code_\label	// codeword
	.text
	//.align 4
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

/* defcode assembley word definitions ------------------------------------------------------ */

	defcode "DOCOL",5,,DOCOL // DOCOL - the interpreter! 
	lea -4(%ebp),%ebp	// push %esi on to return stack
	movl %esi,(%ebp)
	addl $4,%eax            // %eax points to codeword, so make
	movl %eax,%esi          // %esi point to first data word
	NEXT

	defcode "start",5,,start // code_start is assembler entry point. 
	cld
	mov $(COLD_START+4),%esi // Initialise interpreter.
	NEXT			// Run interpreter!

	defcode "DROP",4,,DROP
	pop %eax		// drop top of stack
	NEXT

	defcode "SWAP",4,,SWAP
	pop %eax		// swap top two elements on stack
	pop %ebx
	push %eax
	push %ebx
	NEXT

	defcode "DUP",3,,DUP
	mov (%esp),%eax		// duplicate top of stack
	push %eax
	NEXT

	defcode "OVER",4,,OVER
	mov 4(%esp),%eax	// get the second element of stack
	push %eax		// and push it on top
	NEXT

	defcode "ROT",3,,ROT
	pop %eax
	pop %ebx
	pop %ecx
	push %ebx
	push %eax
	push %ecx
	NEXT

	defcode "-ROT",4,,NROT
	pop %eax
	pop %ebx
	pop %ecx
	push %eax
	push %ecx
	push %ebx
	NEXT

	defcode "2DROP",5,,TWODROP // drop top two elements of stack
	pop %eax
	pop %eax
	NEXT

	defcode "2DUP",4,,TWODUP // duplicate top two elements of stack
	mov (%esp),%eax
	mov 4(%esp),%ebx
	push %ebx
	push %eax
	NEXT

	defcode "2SWAP",5,,TWOSWAP // swap top two pairs of elements of stack
	pop %eax
	pop %ebx
	pop %ecx
	pop %edx
	push %ebx
	push %eax
	push %edx
	push %ecx
	NEXT

	defcode "?DUP",4,,QDUP	// duplicate top of stack if non-zero
	movl (%esp),%eax
	test %eax,%eax
	jz 1f
	push %eax
1:	NEXT

	defcode "1+",2,,INCR
	incl (%esp)		// increment top of stack
	NEXT

	defcode "1-",2,,DECR
	decl (%esp)		// decrement top of stack
	NEXT

	defcode "4+",2,,INCR4
	addl $4,(%esp)		// add 4 to top of stack
	NEXT

	defcode "4-",2,,DECR4
	subl $4,(%esp)		// subtract 4 from top of stack
	NEXT

	defcode "+",1,,ADD
	pop %eax		// get top of stack
	addl %eax,(%esp)	// and add it to next word on stack
	NEXT

	defcode "-",1,,SUB
	pop %eax		// get top of stack
	subl %eax,(%esp)	// and subtract it from next word on stack
	NEXT

	defcode "*",1,,MUL
	pop %eax
	pop %ebx
	imull %ebx,%eax
	push %eax		// ignore overflow
	NEXT

	defcode "/MOD",4,,DIVMOD
	xor %edx,%edx
	pop %ebx
	pop %eax
	idivl %ebx
	push %edx		// push remainder
	push %eax		// push quotient
	NEXT

	defcode "=",1,,EQU	// top two words are equal?
	pop %eax
	pop %ebx
	cmp %ebx,%eax
	sete %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "<>",2,,NEQU	// top two words are not equal?
	pop %eax
	pop %ebx
	cmp %ebx,%eax
	setne %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "<",1,,LT
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setl %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode ">",1,,GT
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setg %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "<=",2,,LE
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setle %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode ">=",2,,GE
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setge %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0=",2,,ZEQU	// top of stack equals 0?
	pop %eax
	test %eax,%eax
	setz %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0<>",3,,ZNEQU	// top of stack not 0?
	pop %eax
	test %eax,%eax
	setnz %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0<",2,,ZLT	// comparisons with 0
	pop %eax
	test %eax,%eax
	setl %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0>",2,,ZGT
	pop %eax
	test %eax,%eax
	setg %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0<=",3,,ZLE
	pop %eax
	test %eax,%eax
	setle %al
	movzbl %al,%eax
	pushl %eax
	NEXT

	defcode "0>=",3,,ZGE
	pop %eax
	test %eax,%eax
	setge %al
	movzbl %al,%eax
	pushl %eax
	NEXT

        defcode "NAND",4,,NAND    // bitwise NAND
        pop %eax
        andl %eax,(%esp)
	notl (%esp)
        NEXT

	defcode "AND",3,,AND	// bitwise AND
	pop %eax
	andl %eax,(%esp)
	NEXT

	defcode "OR",2,,OR	// bitwise OR
	pop %eax
	orl %eax,(%esp)
	NEXT

	defcode "XOR",3,,XOR	// bitwise XOR
	pop %eax
	xorl %eax,(%esp)
	NEXT

	defcode "INVERT",6,,INVERT // this is the FORTH bitwise "NOT" function (cf. NEGATE and NOT)
	notl (%esp)
	NEXT

	defcode "EXIT",4,,EXIT
	POPRSP %esi		// pop return stack into %esi
	NEXT

	defcode "LIT",3,,LIT
	// %esi points to the next command, but in this case it points to the next
	// literal 32 bit integer.  Get that literal into %eax and increment %esi.
	// On x86, it's a convenient single byte instruction!  (cf. NEXT macro)
	lodsl
	push %eax		// push the literal number on to stack
	NEXT

	defcode "!",1,,STORE
	pop %ebx		// address to store at
	pop %eax		// data to store there
	mov %eax,(%ebx)		// store it
	NEXT

	defcode "@",1,,FETCH
	pop %ebx		// address to fetch
	mov (%ebx),%eax		// fetch it
	push %eax		// push value onto stack
	NEXT

	defcode "+!",2,,ADDSTORE
	pop %ebx		// address
	pop %eax		// the amount to add
	addl %eax,(%ebx)	// add it
	NEXT

	defcode "-!",2,,SUBSTORE
	pop %ebx		// address
	pop %eax		// the amount to subtract
	subl %eax,(%ebx)	// add it
	NEXT

	defcode "C!",2,,STOREBYTE
	pop %ebx		// address to store at
	pop %eax		// data to store there
	movb %al,(%ebx)		// store it
	NEXT

	defcode "C@",2,,FETCHBYTE
	pop %ebx		// address to fetch
	xor %eax,%eax
	movb (%ebx),%al		// fetch it
	push %eax		// push value onto stack
	NEXT

	defcode "C@C!",4,,CCOPY
	movl 4(%esp),%ebx	// source address
	movb (%ebx),%al		// get source character
	pop %edi		// destination address
	stosb			// copy to destination
	push %edi		// increment destination address
	incl 4(%esp)		// increment source address
	NEXT

	defcode "CMOVE",5,,CMOVE
	mov %esi,%edx		// preserve %esi
	pop %ecx		// length
	pop %edi		// destination address
	pop %esi		// source address
	rep movsb		// copy source to destination
	mov %edx,%esi		// restore %esi
	NEXT

	defcode ">R",2,,TOR
	pop %eax		// pop parameter stack into %eax
	PUSHRSP %eax		// push it on to the return stack
	NEXT

	defcode "R>",2,,FROMR
	POPRSP %eax		// pop return stack on to %eax
	push %eax		// and push on to parameter stack
	NEXT

	defcode "RSP@",4,,RSPFETCH
	push %ebp
	NEXT

	defcode "RSP!",4,,RSPSTORE
	pop %ebp
	NEXT

	defcode "RDROP",5,,RDROP
	addl $4,%ebp		// pop return stack and throw away
	NEXT

	defcode "DSP@",4,,DSPFETCH
	mov %esp,%eax
	push %eax
	NEXT

	defcode "DSP!",4,,DSPSTORE
	pop %esp
	NEXT

	defcode "EMIT",4,,EMIT
	pop %eax
	mov $1,%ebx		// 1st param: stdout
	mov %al,var_EMIT_SCRATCH // write needs the address of the byte to write
	mov $var_EMIT_SCRATCH,%ecx // 2nd param: address
	mov $1,%edx		// 3rd param: nbytes = 1
	mov $__NR_write,%eax	// write syscall
	int $0x80
	NEXT

	defcode "FIND",4,,FIND
	pop %ecx		// %ecx = length
	pop %edi		// %edi = address
	push %esi		// Save %esi so we can use it in string comparison.

	// Now we start searching backwards through the dictionary for this word.
	mov var_LATEST,%edx	// LATEST points to name header of the latest word in the dictionary
1:	test %edx,%edx		// NULL pointer?  (end of the linked list)
	je 4f

	// Compare the length expected and the length of the word.
	// Note that if the F_HIDDEN flag is set on the word, then by a bit of trickery
	// this won't pick the word (the length will appear to be wrong).
	xor %eax,%eax
	movb 4(%edx),%al	// %al = flags+length field
	andb $(F_HIDDEN|F_LENMASK),%al // %al = name length
	cmpb %cl,%al		// Length is the same?
	jne 2f

	// Compare the strings in detail.
	push %ecx		// Save the length
	push %edi		// Save the address (repe cmpsb will move this pointer)
	lea 5(%edx),%esi	// Dictionary string we are checking against.
	repe cmpsb		// Compare the strings.
	pop %edi
	pop %ecx
	jne 2f			// Not the same.

	// The strings are the same - return the header pointer in %eax
	pop %esi
	mov %edx,%eax
	push %eax		// %eax = address of dictionary entry (or NULL)
	NEXT

2:	mov (%edx),%edx		// Move back through the link field to the previous word
	jmp 1b			// .. and loop.

4:	// Not found.
	pop %esi
	xor %eax,%eax		// Return zero to indicate not found.
	push %eax		// %eax = address of dictionary entry (or NULL)
	NEXT

	defcode ">CFA",4,,TCFA
	pop %edi
	xor %eax,%eax
	add $4,%edi		// Skip link pointer.
	movb (%edi),%al		// Load flags+len into %al.
	inc %edi		// Skip flags+len byte.
	andb $F_LENMASK,%al	// Just the length, not the flags.
	add %eax,%edi		// Skip the name.
	addl $3,%edi		// The codeword is 4-byte aligned.
	andl $~3,%edi
	push %edi
	NEXT

	defcode "CREATE",6,,CREATE
	// Get the name length and address.
	pop %ecx		// %ecx = length
	pop %ebx		// %ebx = address of name
	// Link pointer.
	movl var_HERE,%edi	// %edi is the address of the header
	movl var_LATEST,%eax	// Get link pointer
	stosl			// and store it in the header.
	// Length byte and the word itself.
	mov %cl,%al		// Get the length.
	stosb			// Store the length/flags byte.
	push %esi
	mov %ebx,%esi		// %esi = word
	rep movsb		// Copy the word
	pop %esi
	addl $3,%edi		// Align to next 4 byte boundary.
	andl $~3,%edi
	// Update LATEST and HERE.
	movl var_HERE,%eax
	movl %eax,var_LATEST
	movl %edi,var_HERE
	NEXT

	defcode ",",1,,COMMA
	pop %eax		// Code pointer to store.
	movl var_HERE,%edi	// HERE
	stosl			// Store it.
	movl %edi,var_HERE	// Update HERE (incremented)
	NEXT

	defcode "[",1,F_IMMED,LBRAC
	xor %eax,%eax
	movl %eax,var_STATE	// Set STATE to 0.
	NEXT

	defcode "]",1,,RBRAC
	movl $1,var_STATE	// Set STATE to 1.
	NEXT

	defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE
	movl var_LATEST,%edi	// LATEST word.
	addl $4,%edi		// Point to name/flags byte.
	xorb $F_IMMED,(%edi)	// Toggle the IMMED bit.
	NEXT

	defcode "HIDDEN",6,,HIDDEN
	pop %edi		// Dictionary entry.
	addl $4,%edi		// Point to name/flags byte.
	xorb $F_HIDDEN,(%edi)	// Toggle the HIDDEN bit.
	NEXT

	defcode "'",1,,TICK
	lodsl			// Get the address of the next word and skip it.
	pushl %eax		// Push it on the stack.
	NEXT

	defcode "BRANCH",6,,BRANCH
	add (%esi),%esi		// add the offset to the instruction pointer
	NEXT

	defcode "0BRANCH",7,,ZBRANCH
	pop %eax
	test %eax,%eax		// top of stack is zero?
	jz code_BRANCH		// if so, jump back to the branch function above
	lodsl			// otherwise we need to skip the offset
	NEXT

	defcode "LITSTRING",9,,LITSTRING
	lodsl			// get the length of the string
	push %esi		// push the address of the start of the string
	push %eax		// push it on the stack
	addl %eax,%esi		// skip past the string
 	addl $3,%esi		// but round up to next 4 byte boundary
	andl $~3,%esi
	NEXT

	defcode "TELL",4,,TELL
	mov $1,%ebx		// 1st param: stdout
	pop %edx		// 3rd param: length of string
	pop %ecx		// 2nd param: address of string
	mov $__NR_write,%eax	// write syscall
	int $0x80
	NEXT

	defcode "EXECUTE",7,,EXECUTE
	pop %eax		// Get xt into %eax
	jmp *(%eax)		// and jump to it.
				// After xt runs its NEXT will continue executing the current word.

	defcode "SYSCALL3",8,,SYSCALL3
	pop %eax		// System call number (see <asm/unistd.h>)
	pop %ebx		// First parameter.
	pop %ecx		// Second parameter
	pop %edx		// Third parameter
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

	defcode "SYSCALL2",8,,SYSCALL2
	pop %eax		// System call number (see <asm/unistd.h>)
	pop %ebx		// First parameter.
	pop %ecx		// Second parameter
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

	defcode "SYSCALL1",8,,SYSCALL1
	pop %eax		// System call number (see <asm/unistd.h>)
	pop %ebx		// First parameter.
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

	defcode "SYSCALL0",8,,SYSCALL0
	pop %eax		// System call number (see <asm/unistd.h>)
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

/* BUILT-IN VARIABLES ---------------------------------------------------------------------- */

	defvar "STATE",5,,STATE
	defvar "HERE",4,,HERE
	defvar "LATEST",6,,LATEST,name_QUIT // QUIT must be last in built-in dictionary
	defvar "S0",2,,SZ
	defvar "BASE",4,,BASE,10
	defvar "WORD_BUFFER",11,,WORD_BUFFER,,4,32
	defvar "RET_STACK",9,,RETURN_STACK,,4096,8192
	defvar "KB",2,,KB,,4096,4096
	defvar "KEY_CURRKEY",11,,KEY_CURRKEY,var_KB
	defvar "KEY_BUFFTOP",11,,KEY_BUFFTOP,var_KB
	defvar "KEY_BUFFER",10,,KEY_BUFFER,var_KB
	defvar "KEY_BUFFER_SIZE",15,,KEY_BUFFER_SIZE,BUFFER_SIZE
	defvar "INTERPRET_IS_LIT",16,,INTERPRET_IS_LIT
	defvar "INTERPRET_ERRMSG",16,,INTERPRET_ERRMSG,errmsg
	defvar "INTERPRET_ERRMSGLEN",19,,INTERPRET_ERRMSGLEN,errmsgend-errmsg
	defvar "INTERPRET_ERRMSGNL",18,,INTERPRET_ERRMSGNL,errmsgnl
	defvar "NUMBER_CURLEN",13,,NUMBER_CURLEN
	defvar "NUMBER_CURADDR",14,,NUMBER_CURADDR
	defvar "NUMBER_CURSUM",13,,NUMBER_CURSUM
	defvar "EMIT_SCRATCH",12,,EMIT_SCRATCH

/* BUILT-IN CONSTANTS ---------------------------------------------------------------------- */

	defconst "INITIAL_DATA_SEGMENT_SIZE",25,,INITIAL_DATA_SEGMENT_SIZE,65536
	defconst "VERSION",7,,VERSION,JONES_VERSION
	defconst "R0",2,,RZ,var_RET_STACK+size_RET_STACK
	defconst "DOCOL",5,,__DOCOL,code_DOCOL
	defconst "F_IMMED",7,,__F_IMMED,F_IMMED
	defconst "F_HIDDEN",8,,__F_HIDDEN,F_HIDDEN
	defconst "F_LENMASK",9,,__F_LENMASK,F_LENMASK
	defconst "ZERO",4,,ZERO,0
	defconst "ONE",3,,ONE,1
	defconst "TWO",3,,TWO,2
	defconst "TEN",3,,TEN,10
	defconst "THIRTYTWO",9,,THIRTYTWO,32
	defconst "FORTY",5,,FORTY,40
	defconst "FORTYFIVE",9,,FORTYFIVE,45
	defconst "FORTYEIGHT",10,,FORTYEIGHT,48
	defconst "FIFTYFIVE",9,,FIFTYFIVE,55
	defconst "FIFTYEIGHT",10,,FIFTYEIGHT,58
	defconst "SIXTYFOUR",9,,SIXTYFOUR,64
	defconst "NINETYTWO",9,,NINETYTWO,92

	defconst "SYS_EXIT",8,,SYS_EXIT,__NR_exit
	defconst "SYS_OPEN",8,,SYS_OPEN,__NR_open
	defconst "SYS_CLOSE",9,,SYS_CLOSE,__NR_close
	defconst "SYS_READ",8,,SYS_READ,__NR_read
	defconst "SYS_WRITE",9,,SYS_WRITE,__NR_write
	defconst "SYS_CREAT",9,,SYS_CREAT,__NR_creat
	defconst "SYS_BRK",7,,SYS_BRK,__NR_brk

	defconst "O_RDONLY",8,,__O_RDONLY,0
	defconst "O_WRONLY",8,,__O_WRONLY,1
	defconst "O_RDWR",6,,__O_RDWR,2
	defconst "O_CREAT",7,,__O_CREAT,0100
	defconst "O_EXCL",6,,__O_EXCL,0200
	defconst "O_TRUNC",7,,__O_TRUNC,01000
	defconst "O_APPEND",8,,__O_APPEND,02000
	defconst "O_NONBLOCK",10,,__O_NONBLOCK,04000

/* defword compiled forth word definitions ------------------------------------------------- */

	defword "KEY",3,,KEY
	.int KEY_CURRKEY, FETCH, KEY_BUFFTOP, FETCH, SWAP, INCR, LT, ZBRANCH, 144, KEY_BUFFER, FETCH, KEY_CURRKEY, STORE
	.int KEY_BUFFER_SIZE, FETCH, KEY_BUFFER, FETCH, ZERO, SYS_READ, SYSCALL3, DUP, ONE, LT, ZBRANCH, 32, DROP
	.int ZERO, ZERO, ZERO, SYS_EXIT, SYSCALL3, EXIT, KEY_BUFFER, FETCH, DUP, DUP, SUB, SWAP, SUB, SUB, KEY_BUFFTOP, STORE
	.int BRANCH, -172, KEY_CURRKEY, FETCH, FETCHBYTE, KEY_CURRKEY, FETCH, INCR, KEY_CURRKEY, STORE, EXIT

	defword "WORD",4,,WORD
	.int ZERO, DROP, KEY, DUP, NINETYTWO, SUB, ZEQU, ZBRANCH, 36, DROP, KEY, DUP, TEN, SUB, ZEQU
	.int ZBRANCH, -28, DUP, THIRTYTWO, SWAP, LT, ZBRANCH, -84, WORD_BUFFER, SWAP
	.int WORD_BUFFER, SWAP, SWAP, STOREBYTE, INCR, DUP, KEY, DUP, THIRTYTWO, INCR
	.int LT, ZBRANCH, -40, DROP, DROP, WORD_BUFFER, SUB, WORD_BUFFER, SWAP, EXIT

	defword "NUMBER",6,,NUMBER
	.int NUMBER_CURLEN, STORE, NUMBER_CURADDR, STORE, ZERO, NUMBER_CURSUM, STORE, ZERO 
	.int NUMBER_CURLEN, FETCH, ZBRANCH, 84, NUMBER_CURADDR, FETCH, FETCHBYTE, FORTYFIVE, SUB 
	.int ZEQU, ZBRANCH, 52, INCR, NUMBER_CURADDR, FETCH, INCR, NUMBER_CURADDR, STORE 
	.int NUMBER_CURLEN, FETCH, ONE, SUB, NUMBER_CURLEN, STORE, NUMBER_CURLEN, FETCH, ZBRANCH, 268 
	.int NUMBER_CURSUM, FETCH, BASE, FETCH, MUL, NUMBER_CURSUM, STORE, NUMBER_CURADDR, FETCH, FETCHBYTE  
	.int NUMBER_CURADDR, FETCH, INCR, NUMBER_CURADDR, STORE, NUMBER_CURLEN, FETCH, ONE, SUB, NUMBER_CURLEN, STORE 
	.int DUP, FIFTYEIGHT, LT, ZBRANCH, 12, FORTYEIGHT, SUB, DUP, SIXTYFOUR, SWAP, LT, ZBRANCH, 12  
	.int FIFTYFIVE, SUB, DUP, DUP, BASE, FETCH, SWAP, SUB, SWAP, INCR, MUL, ONE, LT, SWAP, DUP, DUP, SUB, SWAP, SUB 
	.int NUMBER_CURSUM, FETCH, SWAP, SUB, NUMBER_CURSUM, STORE, ZEQU, NUMBER_CURLEN, FETCH, MUL 
	.int ZEQU, ZBRANCH, -260, ZBRANCH, 40, NUMBER_CURSUM, FETCH, DUP, DUP, SUB, SWAP, SUB 
	.int NUMBER_CURSUM, STORE, NUMBER_CURSUM, FETCH, NUMBER_CURLEN, FETCH, EXIT

	defword ">DFA",4,,TDFA
	.int TCFA		// >CFA		(get code field address)
	.int INCR4		// 4+		(add 4 to it to get to next word)
	.int EXIT		// EXIT		(return from FORTH word)

	defword ":",1,,COLON
	.int WORD		// Get the name of the new word
	.int CREATE		// CREATE the dictionary entry / header
	.int LIT, code_DOCOL, COMMA	// Append DOCOL  (the codeword).
	.int LATEST, FETCH, HIDDEN // Make the word hidden (see below for definition).
	.int RBRAC		// Go into compile mode.
	.int EXIT		// Return from the function.

	defword ";",1,F_IMMED,SEMICOLON
	.int LIT, EXIT, COMMA	// Append EXIT (so the word will return).
	.int LATEST, FETCH, HIDDEN // Toggle hidden flag -- unhide the word (see below for definition).
	.int LBRAC		// Go back to IMMEDIATE mode.
	.int EXIT		// Return from the function.

	defword "HIDE",4,,HIDE
	.int WORD		// Get the word (after HIDE).
	.int FIND		// Look up in the dictionary.
	.int HIDDEN		// Set F_HIDDEN flag.
	.int EXIT		// Return.

	defword "COLD_START",10,,COLD_START
	.int RZ, RSPSTORE, DSPFETCH, SZ, STORE, ZERO, DUP, DUP, DUP, DUP, SYS_BRK, SYSCALL3, DUP, HERE, STORE
	.int INITIAL_DATA_SEGMENT_SIZE, ZERO, SWAP, SUB, SUB, SYS_BRK, SYSCALL3, DROP, QUIT

	defword "INTERPRET",9,,INTERPRET
        .int WORD, TWODUP, ZERO, INTERPRET_IS_LIT, STORE, FIND, DUP, ZBRANCH, 80, SWAP, DROP, SWAP, DROP, DUP
        .int INCR, INCR, INCR, INCR, FETCHBYTE, SWAP, TCFA, SWAP, __F_IMMED, NAND, DUP, NAND, BRANCH, 208
        .int INTERPRET_IS_LIT, FETCH, INCR, INTERPRET_IS_LIT, STORE, DROP, NUMBER, ZBRANCH, 168
        .int INTERPRET_ERRMSGLEN, FETCH, INTERPRET_ERRMSG, FETCH, TWO, SYS_WRITE, SYSCALL3, KEY_CURRKEY, FETCH
        .int KEY_BUFFER, FETCH, SUB, DUP, KEY_BUFFER, FETCH, ADD, SWAP, DUP, FORTY, SWAP, FORTY, SWAP, LT, ZBRANCH, 8, SWAP, DROP
        .int TWODUP, SUB, TWO, SYS_WRITE, SYSCALL3, DROP, ONE, INTERPRET_ERRMSGNL, FETCH, TWO, SYS_WRITE, SYSCALL3, DROP
        .int EXIT, ZERO, ZEQU, STATE, FETCH, MUL, ONE, SWAP, SUB, ZBRANCH, 44, INTERPRET_IS_LIT, FETCH, ZEQU, ZBRANCH, 16
        .int EXECUTE, BRANCH, 4, BRANCH, 36, INTERPRET_IS_LIT, FETCH, ZBRANCH, 16, TICK, LIT, COMMA, COMMA, EXIT

	defword "CHAR",4,,CHAR
	.int WORD, DROP, FETCH, LIT, 255, AND, EXIT ;

	// QUIT must not return (ie. must not call EXIT).
	defword "QUIT",4,,QUIT
	.int RZ,RSPSTORE	// R0 RSP!, clear the return stack
	.int INTERPRET		// interpret the next word
	.int BRANCH,-8		// and loop (indefinitely)

	.section .rodata
errmsg: .ascii "PARSE ERROR: "
errmsgend:
errmsgnl: .ascii "\n"

/* END OF jonesforth.S */
