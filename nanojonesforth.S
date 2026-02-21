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

	defcode "1+",2,,INCR
	incl (%esp)		// increment top of stack
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

	defcode "<",1,,LT
	pop %eax
	pop %ebx
	cmp %eax,%ebx
	setl %al
	movzbl %al,%eax
	pushl %eax
	NEXT

        defcode "NAND",4,,NAND    // bitwise NAND
        pop %eax
        andl %eax,(%esp)
	notl (%esp)
        NEXT

	defcode "EXIT",4,,EXIT
	POPRSP %esi		// pop return stack into %esi
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

	defcode "RSP@",4,,RSPFETCH
	push %ebp
	NEXT

	defcode "RSP!",4,,RSPSTORE
	pop %ebp
	NEXT

	defcode "DSP@",4,,DSPFETCH
	mov %esp,%eax
	push %eax
	NEXT

	defcode "DSP!",4,,DSPSTORE
	pop %esp
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

/* BUILT-IN VARIABLES ---------------------------------------------------------------------- */

	defvar "STATE",5,,STATE
	defvar "HERE",4,,HERE
	defvar "LATEST",6,,LATEST,name_QUIT // QUIT must be last in built-in dictionary
	defvar "S0",2,,SZ
	defvar "BASE",4,,BASE,10
	defvar "WORD_BUFFER",11,,WORD_BUFFER,,4,32
	defvar "RET_STACK",9,,RETURN_STACK,,4096,8192
	defvar "KEY_BUFFER",2,,KEY_BUFFER,,4096,4096
	defvar "KEY_CURRKEY",11,,KEY_CURRKEY,var_KEY_BUFFER
	defvar "KEY_BUFFTOP",11,,KEY_BUFFTOP,var_KEY_BUFFER
	defvar "KEY_BUFFER_SIZE",15,,KEY_BUFFER_SIZE,BUFFER_SIZE
	defvar "INTERPRET_IS_LIT",16,,INTERPRET_IS_LIT
	defvar "INTERPRET_ERRMSG",16,,INTERPRET_ERRMSG,errmsg
	defvar "INTERPRET_ERRMSGLEN",19,,INTERPRET_ERRMSGLEN,errmsgend-errmsg
	defvar "INTERPRET_ERRMSGNL",18,,INTERPRET_ERRMSGNL,errmsgnl
	defvar "NUMBER_CURLEN",13,,NUMBER_CURLEN
	defvar "NUMBER_CURADDR",14,,NUMBER_CURADDR
	defvar "NUMBER_CURSUM",13,,NUMBER_CURSUM
	defvar "CMPSTRS_LEN",11,,CMPSTRS_LEN
	defvar "FIND_CURDICT",12,,FIND_CURDICT
	defvar "CMOVE_COUNT",11,,CMOVE_COUNT

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

	defword "BRANCH",6,,BRANCH
	.int RSPFETCH, FETCH, DUP, FETCH, ADD, RSPFETCH, STORE, EXIT

	defword "0BRANCH",7,,ZBRANCH
        .int DUP, INCR, ZERO, SWAP, LT, SWAP, ONE, LT, MUL, RSPFETCH, FETCH, DSPFETCH
	.int INCR, INCR, INCR, INCR, FETCH, DSPFETCH, INCR, INCR, INCR, INCR, FETCH
	.int FETCH, TWO, SUB, TWO, SUB, MUL, ADD, INCR, INCR, INCR, INCR, RSPFETCH
	.int STORE, DROP, EXIT

	defword "2DUP",4,,TWODUP // duplicate top two elements of stack
	.int DSPFETCH, INCR, INCR, INCR, INCR, FETCH, DSPFETCH, INCR, INCR, INCR, INCR, FETCH, EXIT

	defword "+",1,,ADD
	.int ZERO, SWAP, SUB, SUB, EXIT

	defword "0=",2,,ZEQU	// top of stack equals 0?
	.int DUP, ZERO, ONE, SUB, SWAP, LT, SWAP, ONE, LT, NAND, DUP, NAND, EXIT

	defword "LIT",3,,LIT
	.int RSPFETCH, FETCH, DUP, INCR, INCR, INCR, INCR, RSPFETCH, STORE, FETCH, EXIT

	defword ",",1,,COMMA
	.int HERE, FETCH, STORE, HERE, FETCH, INCR, INCR, INCR, INCR, HERE, STORE, EXIT

	defword "[",1,F_IMMED,LBRAC
	.int ZERO, STATE, STORE, EXIT

	defword "]",1,,RBRAC
	.int ONE, STATE, STORE, EXIT

	defword "HIDDEN",6,,HIDDEN
	.int INCR, INCR, INCR, INCR, DUP, FETCHBYTE, DUP, __F_HIDDEN, SWAP, __F_HIDDEN, NAND, DUP, NAND
	.int SUB, SWAP, __F_HIDDEN, DUP, NAND, NAND, DUP, NAND, ADD, SWAP, STOREBYTE, EXIT

	defword "'",1,,TICK
	.int RSPFETCH, FETCH, DUP, INCR, INCR, INCR, INCR, RSPFETCH, STORE, FETCH, EXIT

	defword "C@C!",4,,CCOPY
	.int TWODUP, SWAP, FETCHBYTE, SWAP, STOREBYTE, INCR, SWAP, INCR, SWAP, EXIT

	defword "CMOVE",5,,CMOVE
	.int CMOVE_COUNT, STORE, CMOVE_COUNT, FETCH, DUP, ZBRANCH, 36, ONE, SUB, CMOVE_COUNT, STORE, CCOPY
	.int ZERO, ZBRANCH, -48, DROP, DROP, DROP, EXIT

	defword ">CFA",4,,TCFA
	.int LIT, 4, ADD, DUP, FETCHBYTE, SWAP, INCR, SWAP, LIT, F_LENMASK, NAND, DUP, NAND, ADD, INCR, INCR
        .int INCR, LIT, -4, NAND, DUP, NAND, EXIT

	defword "KEY",3,,KEY
	.int KEY_CURRKEY, FETCH, KEY_BUFFTOP, FETCH, SWAP, INCR, LT, ZBRANCH, 132, KEY_BUFFER, KEY_CURRKEY, STORE
	.int KEY_BUFFER_SIZE, FETCH, KEY_BUFFER, ZERO, SYS_READ, SYSCALL3, DUP, ONE, LT, ZBRANCH, 32, DROP
	.int ZERO, ZERO, ZERO, SYS_EXIT, SYSCALL3, EXIT, KEY_BUFFER, DUP, DUP, SUB, SWAP, SUB, SUB, KEY_BUFFTOP, STORE
	.int BRANCH, -160, KEY_CURRKEY, FETCH, FETCHBYTE, KEY_CURRKEY, FETCH, INCR, KEY_CURRKEY, STORE, EXIT

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

	defword "CREATE",6,,CREATE
	.int TWODUP, DUP, LATEST, FETCH, HERE, FETCH, STORE, HERE, FETCH, INCR, INCR, INCR, INCR
	.int STOREBYTE, HERE, FETCH, INCR, INCR, INCR, INCR, INCR, SWAP, CMOVE, SWAP, DROP, HERE
	.int FETCH, INCR, INCR, INCR, INCR, INCR, DUP, DUP, SUB, SWAP, SUB, SUB, INCR, INCR, INCR
	.int ZERO, INCR, INCR, INCR, DUP, NAND, NAND, DUP, NAND, HERE, FETCH, LATEST, STORE, HERE
	.int STORE, EXIT

	defword "CMPSTRS",7,,CMPSTRS
	.int CMPSTRS_LEN, STORE, CMPSTRS_LEN, FETCH, ZBRANCH, 100, TWODUP, FETCHBYTE, SWAP, FETCHBYTE
	.int SWAP, SUB, ZBRANCH, 20, DROP, DROP, ZERO, EXIT, INCR, SWAP, INCR, SWAP, CMPSTRS_LEN, FETCH
	.int ONE, SUB, CMPSTRS_LEN, STORE, BRANCH, -108, DROP, DROP, CMPSTRS_LEN, FETCH, INCR, EXIT

	defword "FIND",4,,FIND
	.int TWODUP, LATEST, FETCH, FIND_CURDICT, STORE, FIND_CURDICT, FETCH, ZBRANCH, 204, DUP
	.int FIND_CURDICT, FETCH, INCR, INCR, INCR, INCR, FETCHBYTE, __F_HIDDEN, __F_LENMASK, DUP, DUP
	.int SUB, SWAP, SUB, SUB, NAND, DUP, NAND, SUB, ZEQU, ZBRANCH, 72, FIND_CURDICT, FETCH, INCR
	.int INCR, INCR, INCR, INCR, SWAP, CMPSTRS,  ZBRANCH, 24, DROP, DROP, FIND_CURDICT, FETCH, EXIT
	.int TWODUP, DROP, DROP, TWODUP, FIND_CURDICT, FETCH, FETCH, FIND_CURDICT, STORE, BRANCH, -212
	.int DROP, DROP, DROP, DROP, ZERO, EXIT

	defword ">DFA",4,,TDFA
	.int TCFA		// >CFA		(get code field address)
	.int INCR, INCR, INCR, INCR // 4+	(add 4 to it to get to next word)
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

	defword "COLD_START",10,,COLD_START
	.int RZ, RSPSTORE, DSPFETCH, SZ, STORE, ZERO, DUP, DUP, DUP, DUP, SYS_BRK, SYSCALL3, DUP, HERE, STORE
	.int INITIAL_DATA_SEGMENT_SIZE, ZERO, SWAP, SUB, SUB, SYS_BRK, SYSCALL3, DROP, QUIT

	defword "INTERPRET",9,,INTERPRET
        .int WORD, TWODUP, ZERO, INTERPRET_IS_LIT, STORE, FIND, DUP, ZBRANCH, 80, SWAP, DROP, SWAP, DROP, DUP
        .int INCR, INCR, INCR, INCR, FETCHBYTE, SWAP, TCFA, SWAP, __F_IMMED, NAND, DUP, NAND, BRANCH, 200
        .int INTERPRET_IS_LIT, FETCH, INCR, INTERPRET_IS_LIT, STORE, DROP, NUMBER, ZBRANCH, 160
        .int INTERPRET_ERRMSGLEN, FETCH, INTERPRET_ERRMSG, FETCH, TWO, SYS_WRITE, SYSCALL3, KEY_CURRKEY, FETCH
        .int KEY_BUFFER, SUB, DUP, KEY_BUFFER, ADD, SWAP, DUP, FORTY, SWAP, FORTY, SWAP, LT, ZBRANCH, 8, SWAP, DROP
        .int TWODUP, SUB, TWO, SYS_WRITE, SYSCALL3, DROP, ONE, INTERPRET_ERRMSGNL, FETCH, TWO, SYS_WRITE, SYSCALL3, DROP
        .int EXIT, ZERO, ZEQU, STATE, FETCH, MUL, ONE, SWAP, SUB, ZBRANCH, 44, INTERPRET_IS_LIT, FETCH, ZEQU, ZBRANCH, 16
        .int EXECUTE, BRANCH, 4, BRANCH, 36, INTERPRET_IS_LIT, FETCH, ZBRANCH, 16, TICK, LIT, COMMA, COMMA, EXIT

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
