KEY \ KEY \ KEY \
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
G_4 DUP *__ DUP *__ *__ 1+_ 1+_ 1+_
LAT @__ HER @__ !__
HER @__ G_4 -__ !__
HER @__ DUP
LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA
LAT !__
SWA G_4 -__ G_4 -__ G_4 -__ HER !__
HER @__ !__ HER @__ G_4 -__ HER !__
KEY K KEY E KEY Y
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
HER @__ !__ HER @__ G_4 -__ HER !__
KEY G KEY _ KEY 4
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
HER @__ !__ HER @__ G_4 -__ HER !__
KEY D KEY U KEY P
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
HER @__ !__ HER @__ G_4 -__ HER !__
KEY * KEY _ KEY _
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
HER @__ !__ HER @__ G_4 -__ HER !__
KEY < KEY _ KEY _
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
HER @__ !__ HER @__ G_4 -__ HER !__
KEY 0 KEY B KEY R
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
HER @__ !__ HER @__ G_4 -__ HER !__
G0_ G_4 G_4 *__ -__ G_4 G0_ SWA -__ -__ G_4 G0_ SWA -__ -__
HER @__ !__ HER @__ G_4 -__ HER !__
KEY E KEY X KEY I
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
HER @__ !__ HER @__ G_4 -__ HER !__

\\\ OK, now we have a way to make comments
\\\ the above is just manually creating this for comments:
\\\    :01 \\\ KEY G_4 DUP *__ <__ 0BR 32o EXI 00;
\\\ equivalent to:
\\\    : \\\ BEGIN 16 KEY < UNTIL ;
\\\ which is just reading/discarding keys until newline (less than or equal 16)

\\\ Some things to note - first the header for a new \\\ word:
\\\   G0 is constant 0, G_4 is constant -4
\\\   otherwise, words are as expected, just forced to 3 characters
\\\   DOCOL is copied from codeword of last word in dict (at 12 byte offset)
\\\
\\\  KEY \ KEY \ KEY \                                    \ '\' '\' '\'(top)
\\\  G_4 DUP *__ DUP *__ *__                              \ '\' '\' '\'*256
\\\              G0_ SWA -__ -__                          \ '\' ('\'+'\'*256)
\\\              G_4 DUP *__ DUP *__ *__                  \ '\' ('\'+'\'*256)*256 
\\\              G0_ SWA -__ -__                          \ name [24-bit value]
\\\  G_4 DUP *__ DUP *__ *__ 1+_ 1+_ 1+_                  \ 3name [length/name]
\\\  LAT @__ HER @__ !__                                  \ 3name [link stored]
\\\  HER @__ G_4 -__ !__                                  \ [3name stored]
\\\  HER @__ DUP                                          \ *HERE *HERE
\\\  LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA          \ *HERE DOCOL *HERE
\\\  LAT !__                                              \ *HERE DOCOL [LAT=*HER]
\\\  SWA G_4 -__ G_4 -__ G_4 -__ HER !__                  \ DOCOL [advance HERE] 
\\\  HER @__ !__ HER @__ G_4 -__ HER !__                  \ [store DOCOL, advance]
\\\
\\\ Note - during bootstrapping, all words have 3 char names and codeword is at offset 12.
\\\  [LINK, 4-bytes][name len=3, 1-byte][name, 3-bytes][padding, 4-bytes][DOCOL, 4 bytes]
\\\
\\\ Then the body follows this pattern:
\\\   Note the same longwinded way to do *256 and +
\\\   Also +12 offset by repeatedly subtracting -4
\\\
\\\  KEY K KEY E KEY Y                                    \ 'K' 'E' 'Y'(top)
\\\  G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__                   
\\\              G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__  \ name [24-bit value]
\\\  DSP                                                  \ name &name 
\\\      FIN                                              \ name dict-entry
\\\      G_4 -__ G_4 -__ G_4 -__                          \ name codeword
\\\      SWA DRO                                          \ codeword
\\\  HER @__ !__ HER @__ G_4 -__ HER !__                  \ [(comma) store codeword, advance]
\\\  
\\\ This repeats for all of the words for the definition, ending with EXI (EXIT)

\\\ jonesforth.S gives us a simple interpreter, based on a small subset of forth:
\\\   (standard jonesforth meaning unless noted)

\\\ defcode words: (asm)
\\\ sta     start       Executable entry point, not used as a forth word
\\\ DOC     DOCOL       Simple "interpreter" from jonesforth
\\\ DRO     DROP
\\\ SWA     SWAP
\\\ DUP     DUP
\\\ 1+_     1+
\\\ -__     -
\\\ *__     *
\\\ /MO     /MOD
\\\ <__     <
\\\ NAN     NAND
\\\ EXI     EXIT
\\\ @__     @
\\\ !__     !
\\\ C@_     C@
\\\ C!_     C!
\\\ RSP     RSP@
\\\ R!P     RSP!
\\\ DSP     DSP@
\\\ D!P     DSP!
\\\ EXE     EXECUTE
\\\ SYS     SYSCALL3

\\\ defvar words: (asm variables)
\\\ HER     HERE
\\\ LAT     LATEST
\\\ S0_     S0
\\\ RET     RET_STA     Return stack (used internally)
\\\ WB_     WB          Word buffer (will be used internally for WORD)

\\\ defconst words: (asm constants)
\\\ R0_     R0          Return stack top
\\\ G0_     G0          Constant 0
\\\ G_4     G_4         Constant -4
\\\ SES     SYS_EXIT
\\\ SOS     SYS_OPEN
\\\ SLS     SYS_CLOSE
\\\ SRS     SYS_READ
\\\ SWS     SYS_WRITE
\\\ SCS     SYS_CREAT
\\\ SBS     SYS_BRK

\\\ defword words: (compiled forth)
\\\ COL     COLD_START -- used internally
\\\ 0BR     0BRANCH
\\\ FIN     FIND -- takes pointer and assumes len==3, crashes if not found
\\\ KEY     KEY -- without buffering for now
\\\ WOR     WORD -- returns only pointer to the name
\\\ QUI     QUIT

\\\ As you see, we have no : word and it's generally tedious to create new
\\\ words manually. Next step is to address that by building up some helpers:

\\\ manually create +__
\\\ : +__ G0_ SWA -__ -__ ;

\\\ first the header:
KEY + KEY _ KEY _
G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
G_4 DUP *__ DUP *__ *__ 1+_ 1+_ 1+_
LAT @__ HER @__ !__
HER @__ G_4 -__ !__
HER @__ DUP
LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA
LAT !__
SWA G_4 -__ G_4 -__ G_4 -__ HER !__
HER @__ !__ HER @__ G_4 -__ HER !__

\\\ then the body:
KEY G KEY 0 KEY _    \\\ G0_
  G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
  DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY S KEY W KEY A    \\\ SWA
  G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
  DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY - KEY _ KEY _    \\\ -__
  G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
  DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY - KEY _ KEY _    \\\ -__
  G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
  DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY E KEY X KEY I    \\\ EXI
  G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__ G_4 DUP *__ DUP *__ *__ G0_ SWA -__ -__
  DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__

\\\ manually create a word to put 256 on the stack
\\\ : 256 4 DUP * DUP * ;

\\\ first the header:
KEY 2 KEY 5 KEY 6
G_4 DUP *__ DUP *__ *__ +__ G_4 DUP *__ DUP *__ *__ +__ 
G_4 DUP *__ DUP *__ *__ 1+_ 1+_ 1+_
LAT @__ HER @__ !__
HER @__ G_4 -__ !__
HER @__ DUP
LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA 
LAT !__
SWA G_4 -__ G_4 -__ G_4 -__ HER !__ 
HER @__ !__ HER @__ G_4 -__ HER !__

\\\ then the body:
KEY G KEY _ KEY 4    \\\ G_4
    G_4 DUP *__ DUP *__ *__ +__ G_4 DUP *__ DUP *__ *__ +__ 
    DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY D KEY U KEY P    \\\ DUP
    G_4 DUP *__ DUP *__ *__ +__ G_4 DUP *__ DUP *__ *__ +__ 
    DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY * KEY _ KEY _    \\\ *__
    G_4 DUP *__ DUP *__ *__ +__ G_4 DUP *__ DUP *__ *__ +__ 
    DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY D KEY U KEY P    \\\ DUP
    G_4 DUP *__ DUP *__ *__ +__ G_4 DUP *__ DUP *__ *__ +__ 
    DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY * KEY _ KEY _    \\\ *__
    G_4 DUP *__ DUP *__ *__ +__ G_4 DUP *__ DUP *__ *__ +__ 
    DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY E KEY X KEY I    \\\ EXI
    G_4 DUP *__ DUP *__ *__ +__ G_4 DUP *__ DUP *__ *__ +__ 
    DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__

\\\ make >CF -- a fixed 12 byte offset for codeword for now
KEY > KEY C KEY F
256 *__ +__ 256 *__ +__ 256 *__ 1+_ 1+_ 1+_
LAT @__ HER @__ !__
HER @__ G_4 -__ !__
HER @__ DUP
LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA
LAT !__
SWA G_4 -__ G_4 -__ G_4 -__ HER !__
HER @__ !__ HER @__ G_4 -__ HER !__
KEY G KEY _ KEY 4 \\\ G_4
  256 *__ +__ 256 *__ +__ DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY - KEY _ KEY _ \\\ -__
  256 *__ +__ 256 *__ +__ DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY G KEY _ KEY 4 \\\ G_4
  256 *__ +__ 256 *__ +__ DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY - KEY _ KEY _ \\\ -__
  256 *__ +__ 256 *__ +__ DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY G KEY _ KEY 4 \\\ G_4
  256 *__ +__ 256 *__ +__ DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY - KEY _ KEY _ \\\ -__
  256 *__ +__ 256 *__ +__ DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__
KEY E KEY X KEY I \\\ EXI
  256 *__ +__ 256 *__ +__ DSP FIN G_4 -__ G_4 -__ G_4 -__ SWA DRO
  HER @__ !__ HER @__ G_4 -__ HER !__

\\\ make ,__ --> : ,__ HER @__ !__ HER @__ G_4 -__ HER !__ EXI
KEY , KEY _ KEY _
256 *__ +__ 256 *__ +__ 256 *__ 1+_ 1+_ 1+_
LAT @__ HER @__ !__
HER @__ G_4 -__ !__
HER @__ DUP
LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA
LAT !__
SWA G_4 -__ G_4 -__ G_4 -__ HER !__
HER @__ !__ HER @__ G_4 -__ HER !__ 
KEY H KEY E KEY R \\\ HER
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY @ KEY _ KEY _ \\\ @__
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY ! KEY _ KEY _ \\\ !__
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY H KEY E KEY R \\\ HER
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY @ KEY _ KEY _ \\\ @__
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY G KEY _ KEY 4 \\\ G_4
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY - KEY _ KEY _ \\\ -__
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY H KEY E KEY R \\\ HER
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY ! KEY _ KEY _ \\\ !__
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__
KEY E KEY X KEY I \\\ EXI
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO 
    HER @__ !__ HER @__ G_4 -__ HER !__

\\\ make __' --> : __' WOR FIN >CF ;
KEY _ KEY _ KEY '
256 *__ +__ 256 *__ +__ 256 *__ 1+_ 1+_ 1+_
LAT @__ HER @__ !__
HER @__ G_4 -__ !__
HER @__ DUP
LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA 
LAT !__
SWA G_4 -__ G_4 -__ G_4 -__ HER !__ 
,__
KEY W KEY O KEY R \\\ WOR
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO ,__
KEY F KEY I KEY N \\\ FIN
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO ,__
KEY > KEY C KEY F \\\ >CF
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO ,__
KEY E KEY X KEY I \\\ EXI
    256 *__ +__ 256 *__ +__ DSP FIN >CF SWA DRO ,__

\\\ make :00 -- creates header--> : :00 WOR DRO @__ 256 *__ 1+_ 1+_ 1+_ LAT @__ ...
\\\  this is big, dozens of words in the body, so tick and comma come in handy
\\\  after defining :00, headers are much simpler, too!
KEY : KEY 0 KEY 0
256 *__ +__ 256 *__ +__ 256 *__ 1+_ 1+_ 1+_
LAT @__ HER @__ !__
HER @__ G_4 -__ !__
HER @__ DUP
LAT @__ @__ G_4 -__ G_4 -__ G_4 -__ @__ SWA
LAT !__
SWA G_4 -__ G_4 -__ G_4 -__ HER !__
,__
__' WOR ,__ __' @__ ,__ __' 256 ,__ __' *__ ,__ __' 1+_ ,__ __' 1+_ ,__ 
__' 1+_ ,__ __' LAT ,__ __' @__ ,__ __' HER ,__ __' @__ ,__ __' !__ ,__ 
__' HER ,__ __' @__ ,__ __' G_4 ,__ __' -__ ,__ __' !__ ,__ __' HER ,__ 
__' @__ ,__ __' DUP ,__ __' LAT ,__ __' @__ ,__ __' @__ ,__ __' >CF ,__ 
__' @__ ,__ __' SWA ,__ __' LAT ,__ __' !__ ,__ __' SWA ,__ __' >CF ,__ 
__' HER ,__ __' !__ ,__ __' ,__ ,__ __' EXI ,__

\\\ \\\ \\\ \\\ \\\ \\\ \\\ \\\ 
\\\ now we can make things more easily. Example:
\\\           : TST 256 DUP +__ ;
\\\ :00 TST __' 256 __' DUP __' +__ __' EXI

\\\ define a colon operator, :01, but first all that it needs:
\\\ some constants 4, 32, 16, 60, 68, 36, 52, 12, -116
\\\ and some words: CRE NUM 2DU 0= FIN 

:00 G4_     __' G0_ ,__ __' 1+_ ,__ __' 1+_ ,__ __' 1+_ ,__ __' 1+_ ,__ __' EXI ,__
:00 G32     __' G4_ ,__ __' DUP ,__ __' *__ ,__ __' DUP ,__ __' +__ ,__ __' EXI ,__ 
:00 G16     __' G4_ ,__ __' DUP ,__ __' *__ ,__ __' EXI ,__
:00 G60     __' G32 ,__ __' DUP ,__ __' +__ ,__ __' G4_ ,__ __' -__ ,__ __' EXI ,__
:00 G68     __' G32 ,__ __' DUP ,__ __' +__ ,__ __' G4_ ,__ __' +__ ,__ __' EXI ,__
:00 G36     __' G32 ,__ __' G4_ ,__ __' +__ ,__ __' EXI ,__
:00 G52     __' G32 ,__ __' G4_ ,__ __' DUP ,__ __' DUP ,__ __' *__ ,__ __' +__ ,__ 
            __' +__ ,__ __' EXI ,__
:00 G12     __' G4_ ,__ __' DUP ,__ __' *__ ,__ __' G4_ ,__ __' -__ ,__ __' EXI ,__
:00 G_1     __' G0_ ,__ __' G32 ,__ __' DUP ,__ __' DUP ,__ __' +__ ,__ __' +__ ,__ \\\ -116
            __' -__ ,__ __' G4_ ,__ __' DUP ,__ __' *__ ,__ __' -__ ,__ __' G4_ ,__ 
            __' -__ ,__ __' EXI ,__

\\\ Everything defined below assumes WOR returns a pointer and length, and FIN 
\\\ and CRE expect len, even if they just drop it. Above here, the assumption 
\\\ is that WOR just returns the pointer without a length, and FIN doesn't need
\\\ to drop it.

\\\ CREATE
\\\   : CREATE DROP @ 4 4 * DUP * * 1+ 1+ 1+ LATEST @ HERE @ ! HERE @ 4 + ! 
\\\            HERE @ DUP LATEST ! >CFA HERE ! ;
:00 CRE
  __' DRO ,__ __' @__ ,__ __' G4_ ,__ __' G4_ ,__ __' *__ ,__ __' DUP ,__ 
  __' *__ ,__ __' *__ ,__ __' 1+_ ,__ __' 1+_ ,__ __' 1+_ ,__ __' LAT ,__ 
  __' @__ ,__ __' HER ,__ __' @__ ,__ __' !__ ,__ __' HER ,__ __' @__ ,__ 
  __' G4_ ,__ __' +__ ,__ __' !__ ,__ __' HER ,__ __' @__ ,__ __' DUP ,__ 
  __' LAT ,__ __' !__ ,__ __' >CF ,__ __' HER ,__ __' !__ ,__ __' EXI ,__

\\\ reads first two chars of a word as octal, no error checking. For branches
\\\   : NUM DROP DUP C@ 4 DUP + /MOD DROP 4 DUP + * SWAP 1+ C@ 4 DUP + /MOD 
\\\         DROP + 32 - 4 * ;
:00 NUM 
  __' DRO ,__ __' DUP ,__ __' C@_ ,__ __' G4_ ,__ __' DUP ,__ __' +__ ,__ 
  __' /MO ,__ __' DRO ,__ __' G4_ ,__ __' DUP ,__ __' +__ ,__ __' *__ ,__ 
  __' SWA ,__ __' 1+_ ,__ __' C@_ ,__ __' G4_ ,__ __' DUP ,__ __' +__ ,__ 
  __' /MO ,__ __' DRO ,__ __' +__ ,__ __' G32 ,__ __' -__ ,__ __' G4_ ,__ 
  __' *__ ,__ __' EXI ,__ 

\\\ standard 2DUP
\\\   : 2DUP DSP@ 4 + @ DSP@ 4 + @ ;
:00 2DU
  __' DSP ,__ __' G4_ ,__ __' +__ ,__ __' @__ ,__ __' DSP ,__ __' G4_ ,__ 
  __' +__ ,__ __' @__ ,__ __' EXI ,__

\\\ standard 0=
\\\   : 0= DUP 0 0 1+ - SWAP < SWAP 0 1+ < * ;
:00 0=_
  __' DUP ,__ __' G0_ ,__ __' G0_ ,__ __' 1+_ ,__ __' -__ ,__ __' SWA ,__ 
  __' <__ ,__ __' SWA ,__ __' G0_ ,__ __' 1+_ ,__ __' <__ ,__ __' *__ ,__ 
  __' EXI ,__

\\\ a version of WOR that also returns the length
\\\   : WORD 0 DROP KEY DUP -4 DUP * DUP 0 SWAP - - SWAP < 0BRANCH 
\\\          0 60 - 4 + KEY KEY -4 DUP * DUP * * 0 SWAP - - 
\\\          -4 DUP * DUP * * 0 SWAP - - WB ! WB 0 1+ 1+ 1+ KEY DROP ;
:00 WOR
  __' G0_ ,__ __' DRO ,__ __' KEY ,__ __' DUP ,__ __' G_4 ,__ __' DUP ,__ 
  __' *__ ,__ __' DUP ,__ __' G0_ ,__ __' SWA ,__ __' -__ ,__ __' -__ ,__ 
  __' SWA ,__ __' <__ ,__ __' 0BR ,__ G0_ G60 -__ G4_ +__ ,__ __' KEY ,__ 
  __' KEY ,__ __' G_4 ,__ __' DUP ,__ __' *__ ,__ __' DUP ,__ __' *__ ,__ 
  __' *__ ,__ __' G0_ ,__ __' SWA ,__ __' -__ ,__ __' -__ ,__ __' G_4 ,__ 
  __' DUP ,__ __' *__ ,__ __' DUP ,__ __' *__ ,__ __' *__ ,__ __' G0_ ,__ 
  __' SWA ,__ __' -__ ,__ __' -__ ,__ __' WB_ ,__ __' !__ ,__ __' WB_ ,__ 
  __' G0_ ,__ __' 1+_ ,__ __' 1+_ ,__ __' 1+_ ,__ __' KEY ,__ __' DRO ,__ 
  __' EXI ,__


\\\ we need a version of FIN that returns 0 if it fails to find the word
\\\   : FIND DROP @ 4 DUP * DUP * * 1+ 1+ 1+ LATEST * 2DUP DUP 0BRANCH 
\\\          60 4 + @ - 0= 0BRANCH 16 SWAP DROP EXIT @ 0 0BRANCH 
\\\          0 68 - DROP DROP DROP DROP 0 ;
:00 FIN
  __' DRO ,__ __' @__ ,__ __' G4_ ,__ __' DUP ,__ __' *__ ,__ __' DUP ,__ 
  __' *__ ,__ __' *__ ,__ __' 1+_ ,__ __' 1+_ ,__ __' 1+_ ,__ __' LAT ,__ 
  __' @__ ,__ __' 2DU ,__ __' DUP ,__ __' 0BR ,__ G60 ,__ __' G4_ ,__ __' +__ ,__ 
  __' @__ ,__ __' -__ ,__ __' 0=_ ,__ __' 0BR ,__ G16 ,__ __' SWA ,__ __' DRO ,__ 
  __' EXI ,__ __' @__ ,__ __' G0_ ,__ __' 0BR ,__ G0_ G68 -__ ,__ __' DRO ,__ 
  __' DRO ,__ __' DRO ,__ __' DRO ,__ __' G0_ ,__ __' EXI ,__

\\\ now we can define :01 and use it to define more functions without __'
:00 :01 
  __' WOR ,__ __' CRE ,__ __' LAT ,__ __' @__ ,__ __' @__ ,__ __' >CF ,__ 
  __' @__ ,__ __' ,__ ,__ __' WOR ,__ __' 2DU ,__ __' FIN ,__ __' DUP ,__ 
  __' 0BR ,__ G36 ,__ __' SWA ,__ __' DRO ,__ __' SWA ,__ __' DRO ,__ 
  __' >CF ,__ __' G0_ ,__ __' 0BR ,__ G52 ,__ __' DRO ,__ __' NUM ,__ 
  __' DUP ,__ __' G32 ,__ __' G4_ ,__ __' *__ ,__ __' +__ ,__ __' 0=_ ,__ 
  __' 0BR ,__ G12 ,__ __' DRO ,__ __' EXI ,__ __' ,__ ,__ __' G0_ ,__ 
  __' 0BR ,__ G_1 ,__ __' EXI ,__

\\\ \\\ \\\ \\\ \\\ \\\ \\\ \\\ \\\ \\\ 
\\\ now add some missing things we'll need

\\\ G1_     G1 (constant 1)
:01 G1_ G0_ 1+_ EXI 00;

\\\ F_H     F_HIDDEN (constant 32)
:01 F_H G4_ DUP DUP +__ *__ EXI 00;

\\\ F_L     F_LENMASK (constant 31)
:01 F_L F_H G1_ -__ EXI 00;

\\\ RDR     RDROP
:01 RDR RSP @__ RSP G4_ +__ R!P RSP !__ EXI 00;

\\\ >R_     >R
:01 >R_ RSP @__ SWA RSP !__ RSP G4_ -__ DUP R!P !__ EXI 00;

\\\ R>      R>
:01 R>_ RSP 1+_ 1+_ 1+_ 1+_ @__ RSP @__ RSP 1+_ 1+_ 1+_ 1+_ !__ RSP 1+_ 
    1+_ 1+_ 1+_ R!P EXI 00;

\\\ CMP     CMPSTRS (compare strings, useful for FIND)
:01 CMP >R_ RSP @__ 0BR 73o 2DU C@_ SWA C@_ SWA -__ 0BR 46o DRO DRO G0_ 
    RDR EXI 1+_ SWA 1+_ SWA RSP @__ G1_ -__ RSP !__ G0_ 0BR 03o DRO DRO 
    G1_ RDR EXI 00;

\\\ replace FIND with a version that allows for names > 3 chars
\\\ INN is for the inner loop, to keep jumps within the +/- 128 limit
:01 INN >R_ DUP RSP @__ G4_ +__ C@_ F_H F_L +__ NAN DUP NAN -__ 0=_ 0BR
    60o 2DU RSP @__ G4_ +__ 1+_ SWA CMP 0BR 46o DRO DRO R>_ G1_ EXI RSP 
    @__ @__ RSP !__ R>_ G0_ EXI 00;
:01 FIN LAT @__ >R_ RSP @__ 0BR 52o R>_ INN 0BR 42o EXI >R_ G0_ 0BR 24o
    DRO DRO G0_ RDR EXI 00;

\\\ C@C     C@C! (copy and increment pointers)
:01 C@C 2DU SWA C@_ SWA C!_ 1+_ SWA 1+_ SWA EXI 00;

\\\ CMO     CMOVE (copy string given src, dest, and length)
:01 CMO >R_ RSP @__ DUP 0BR 51o G1_ -__ RSP !__ C@C G0_ 0BR 24o DRO DRO
    DRO RDR EXI 00;

\\\ CRE     CREATE (allows > 3 char names)
:01 CRE DUP LAT @__ HER @__ !__ HER @__ G4_ +__ C!_ HER @__ G4_ +__ 1+_
    SWA CMO HER @__ DUP LAT !__ G4_ DUP DUP +__ +__ +__ HER !__ EXI 00;

\\\ WOR     WORD (allows > 3 char names)
:01 WOR G0_ DRO KEY DUP G32 SWA <__ 0BR 31o WB_ SWA WB_ SWA SWA C!_ 1+_
    DUP KEY DUP G32 1+_ <__ 0BR 26o DRO DRO WB_ -__ WB_ SWA EXI 00;

\\\ :02     new : word that allows > 3 char names
:01 :02 WOR CRE LAT @__ @__ >CF @__ ,__ WOR 2DU FIN DUP 0BR 51o SWA DRO
    SWA DRO >CF G0_ 0BR 55o DRO NUM DUP G32 G4_ *__ +__ 0=_ 0BR 43o DRO 
    EXI ,__ G0_ 0BR 03o EXI 00;

\\\ and redo the QUIT interpreter to use the new FIND to support > 3 char names
:02 QUI R0_ R!P WOR FIN >CF EXE G0_ 0BR 32o EXI 00;
QUI

\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\

\\\ at this point, all defcode, defvar, and defconst name strings are 7 
\\\ chars long, but the namelen byte is set to 3.
\\\ since asm code is stored separately from dict entries, each of these 
\\\ entries is 16 characters long, with the codeword pointer at offset 12 

\\\ all defword words are 4-7 chars long, with the codeword at offset 12 
\\\ but the definitions follow immediately, so the total entry length is
\\\ variable

\\\ this big block of code serves to fix up the defcode, defvar, and defconst
\\\ words to be the appropriate variable length, 1-7, and also fixes hacks to
\\\ names that were required to have a unique initial first 3 chars. This 
\\\ had to be done in-place to allow later words to call the intial asm words
\\\ directly.

\\\ SHT overwrites namelen of the specified word with value from stack, 4-7
\\\ expects a 7 char name string, with unused chars marked with '_' 
:02 SHT WOR FIN G4_ +__ C!_ EXI 00;

\\\ overwrites namelen (1-3) but also copies codeword since its going to < 4 chars,
:02 S<4 WOR FIN G4_ +__ 2DU C!_ SWA DRO G4_ DUP +__ +__ DUP @__ SWA G4_ -__ !__ EXI 00;

\\\ shorten and lengthen a bunch of word names from jonesforth.S

\\\ Set to 1-3 char name length
G1_ 1+_ S<4 1+_    \\\ 1+
G1_ 1+ S<4 G0_     \\\ G0
G1_ 1+ 1+ S<4 DUP  \\\ DUP
G1_ S<4 -__        \\\ -

\\\ Set to 4 char name length
G4_ SHT DRO \\\ DROP
G4_ SHT SWA \\\ SWAP
G4_ SHT /MO \\\ /MOD
G4_ SHT NAN \\\ NAND
G4_ SHT EXI \\\ EXIT
G4_ SHT RSP \\\ RSP@
G4_ SHT R!P \\\ R!P!
G4_ SHT DSP \\\ DSP@
G4_ SHT D!P \\\ D!P!
G4_ SHT HER \\\ HERE

\\\ Set to 6-7 char name length
G4_ 1+ 1+ SHT LAT    \\\ LATEST
G4_ 1+ 1+ 1+ SHT SYS \\\ SYSCALL
G4_ 1+ 1+ 1+ SHT EXE \\\ EXECUTE
G4_ 1+ 1+ 1+ SHT SES \\\ SES_EXI
G4_ 1+ 1+ 1+ SHT SOS \\\ SES_OPE
G4_ 1+ 1+ 1+ SHT SLS \\\ SLS_CLO
G4_ 1+ 1+ 1+ SHT SRS \\\ SRS_REA
G4_ 1+ 1+ 1+ SHT SWS \\\ SWS_WRI
G4_ 1+ 1+ 1+ SHT SCS \\\ SCS_CRE
G4_ 1+ 1+ 1+ SHT SBS \\\ SBS_BRK

\\\ Set to 1-2 char name length
G1_ S<4 *__        \\\ *
G1_ S<4 <__        \\\ <
G1_ S<4 !__        \\\ !
G1_ S<4 @__        \\\ @
G1_ 1+ S<4 C@_     \\\ C@
G1_ 1+ S<4 C!_     \\\ C!
G1_ 1+ S<4 S0_     \\\ S0
G1_ 1+ S<4 R0_     \\\ R0
G1_ 1+ S<4 WB_     \\\ WB

\\\ redefine these forth words since they can't be altered in-place
:02 F_HIDDE F_H EXIT 00; \\\ 0x20
:02 F_LENMA F_L EXIT 00; \\\ 0x1f

\\\ overwrites 2nd char in name with value on stack
:02 FIX2 WOR FIN G4_ +__ 1+ 1+ C! EXIT 00;

\\\ char values for 'S' and 'Y'
:02 SCHR G32 DUP +__ G4_ DUP +__ DUP +__ +__ 1+ 1+ 1+ EXIT 00;
:02 YCHR SCHR 1+ 1+ 1+ 1+ 1+ 1+ EXIT 00;

\\\ DSP! and RSP! were changed to have unique first 3 chars, change them back
SCHR FIX2 D!P!  \\\ D!P! becomes DSP!
SCHR FIX2 R!P!  \\\ R!P! becomes RSP!

\\\ SYS_??? had to change to have unique first 3 chars, change back to SYS_
YCHR FIX2 SBS_BRK  \\\ SBS_BRK becomes SYS_BRK
YCHR FIX2 SLS_CLO  \\\ SLS_CLO becomes SYS_CLO
YCHR FIX2 SCS_CRE  \\\ SCS_CRE becomes SYS_CRE
YCHR FIX2 SES_EXI  \\\ SES_EXI becomes SYS_EXI
YCHR FIX2 SOS_OPE  \\\ SOS_OPE becomes SYS_OPE
YCHR FIX2 SRS_REA  \\\ SRS_REA becomes SYS_REA
YCHR FIX2 SWS_WRI  \\\ SWS_WRI becomes SYS_WRI

\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\

\\\ replace all defwords to have full 4+ name lengths: 0BRANCH, 2DUP, RDROP, C@C!, CMOVE
:02 0BRANCH 0=_ RSP@ @ @ G4_ - * RSP@ @ G4_ +__ +__ RSP@ ! EXIT 00;
:02 2DUP DSP@ G4_ +__ @ DSP@ G4_ +__ @ EXIT 00;
:02 RDROP RSP@ @ RSP@ G4_ +__ RSP! RSP@ ! EXIT 00;
:02 C@C! 2DUP SWAP C@ SWAP C! 1+ SWAP 1+ SWAP EXIT 00;
:02 CMOVE >R_ RSP@ @ DUP 0BRANCH 51o G1_ - RSP@ ! C@C! G0 0BRANCH 24o DROP DROP DROP RDROP EXIT 00;

\\\ update to use correct codeword offset, so 8 bytes if 1-3 name len, 12 bytes if 4-7
\\\ FINNER is inner loop for FIND
\\\ Note: R>__ and :03_ defined with 4 char name to ensure correct codeword offset
:02 CREATE 2DUP DUP LATEST @ HERE @ ! HERE @ G4_ +__ C! HERE @ G4_ +__ 1+ SWAP CMOVE SWAP
      DROP HERE @ G4_ DUP +__ +__ +__ G0 G4_ - NAND DUP NAND HERE @ LATEST ! HERE ! EXIT 00;
:02 R>__ RSP@ 1+ 1+ 1+ 1+ @ RSP@ @ RSP@ 1+ 1+ 1+ 1+ ! RSP@ 1+ 1+ 1+ 1+ RSP! EXIT 00;
:02 FINNER >R_ DUP RSP@ @ G4_ +__ C@ F_HIDDE F_LENMA +__ NAND DUP NAND - 0=_ 0BRANCH 60o 2DUP RSP@ 
    @ G4_ +__ 1+ SWAP CMP 0BRANCH 46o DROP DROP R>__ G1_ EXIT RSP@ @ @ RSP@ ! R>__ G0 EXIT 00;
:02 FIND LATEST @ >R_ RSP@ @ 0BRANCH 52o R>__ FINNER 0BRANCH 42o EXIT >R_ G0 0BRANCH 24o DROP DROP 
    G0 RDROP EXIT 00;
:02 KEY0 G1_ G0 >R_ RSP@ G0 SYS_REA SYSCALL DROP RSP@ C@ RDROP EXIT 00;
:02 NUM0 DROP DUP C@ G4_ DUP +__ /MOD DROP G4_ DUP +__ * SWAP 1+ C@ G4_ DUP +__ /MOD DROP +__ G32 
    - G4_ * EXIT 00;
:02 WORD0 G0 DROP KEY0 DUP G32 SWAP < 0BRANCH 31o WB SWAP WB SWAP SWAP C! 1+ DUP KEY0 DUP G32 1+ < 
    0BRANCH 26o DROP DROP WB - WB SWAP EXIT 00;
:02 :03_ WORD0 CREATE LATEST @ @ >CF @ ,__ WORD0 2DUP FIND DUP 0BRANCH 51o SWAP DROP SWAP DROP >CF 
    G0 0BRANCH 55o DROP NUM0 DUP G32 G4_ * +__ 0=_ 0BRANCH 43o DROP EXIT ,__ G0 0BRANCH 03o EXIT 00;

\\\ define comment word with 4 char name, as well
:02 \\\_ KEY0 G4_ 1+ DUP +__ - 0=_ 0BRANCH 30o EXIT 00;

\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\

\\\ redefine >CFA, QUIT0, and :03_ because jonesforth.S assumes all word names 
\\\ are <= 7 bytes and that there is always a codeword offset 12 bytes from the 
\\\ link. Going forward, QUIT0 and :04_ support more flexible name lengths with 
\\\ the codeword offset taking into account name length
:03_ >CFA G4_ +__ DUP C@ SWAP 1+ SWAP F_LENMA NAND DUP NAND +__ 1+ 1+ 1+ G0 G4_ - NAND DUP NAND 
     EXIT 00;
:03_ QUIT0 R0 RSP! WORD0 FIND >CFA EXECUTE G0 0BRANCH 32o EXIT 00;
:03_ :04 WORD0 CREATE LATEST @ @ >CFA @ ,__ WORD0 2DUP FIND DUP 0BRANCH 51o SWAP DROP SWAP DROP 
     >CFA G0 0BRANCH 55o DROP NUM0 DUP G32 G4_ * +__ 0=_ 0BRANCH 43o DROP EXIT ,__ G0 0BRANCH 03o 
     EXIT 00;
QUIT0

\\\_ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\

\\\_ allow comments with just one \
:04 \ \\\_ EXIT 00;

\ also, jonesforth.S assumes defword words have >= 4 byte names, so need to redefine a
\ few standard ones that are expected to be shorter: + G1 0= , >R
:04 + G0 SWAP - - EXIT 00;
:04 G1 G0 1+ EXIT 00;
:04 G4 G0 1+ 1+ 1+ 1+ EXIT 00;
:04 0= DUP G0 G1 - SWAP < SWAP G1 < NAND DUP NAND EXIT 00;
:04 , HERE @ ! HERE @ G4 + HERE ! EXIT 00;
:04 >R RSP@ @ SWAP RSP@ ! RSP@ G4 - DUP RSP! ! EXIT 00;
:04 G32 G4 DUP * DUP + EXIT 00;

\ now implement a proper forth interpreter

\ start with defining some needed numbers
:04 G2 G1 1+ EXIT 00;
:04 G3 G1 1+ 1+ EXIT 00;
:04 G10 G3 DUP * 1+ EXIT 00;
:04 G16 G4 DUP * EXIT 00;
:04 G40 G32 G4 G4 + + EXIT 00;
:04 G45 G16 G1 - G3 * EXIT 00;
:04 G48 G16 G3 * EXIT 00;
:04 G55 G45 G10 + EXIT 00;
:04 G58 G45 G10 G3 + + EXIT 00;
:04 G64 G32 G2 * EXIT 00;
:04 G92 G45 G2 * 1+ 1+ EXIT 00;

\ define some things needed to make variables: +! ALLOT CELLS ' LIT
:04 +! 2DUP @ + SWAP ! DROP EXIT 00;
:04 ALLOT HERE @ SWAP HERE +! EXIT 00;
:04 CELLS G4 * EXIT 00;
:04 ' RSP@ @ DUP G4 + RSP@ ! @ EXIT 00;
:04 LIT RSP@ @ DUP G4 + RSP@ ! @ EXIT 00;

\ define needed constants
:04 CONSTANT WORD0 CREATE LATEST @ @ >CFA @ , ' LIT , , ' EXIT , EXIT 00; 

\ we've been using this for all compiled forth words so far, so read from latest
LATEST @ @ >CFA @ CONSTANT DOCOL

\ F_IMMED flag == 0x80
G64 G64 + CONSTANT F_IMMED

\ redefine these standard constants that were forced to <=7 byte names in jonesforth.S 
F_HIDDE CONSTANT F_HIDDEN
F_LENMA CONSTANT F_LENMASK
SYS_EXI CONSTANT SYS_EXIT
SYS_OPE CONSTANT SYS_OPEN
SYS_CLO CONSTANT SYS_CLOSE
SYS_REA CONSTANT SYS_READ
SYS_WRI CONSTANT SYS_WRITE
SYS_CRE CONSTANT SYS_CREAT

\ add support for creating variables
:04 VARIABLE G1 CELLS ALLOT WORD0 CREATE DOCOL , ' LIT , , ' EXIT , EXIT 00;

\ create KEY_BUFFER, 4096 bytes
:04 VARIABLE_BIG CELLS ALLOT WORD0 CREATE DOCOL , ' LIT , , ' EXIT , EXIT 00;
G32 G32 * DUP G4 * CONSTANT KEY_BUFFER_SIZE
VARIABLE_BIG KEY_BUFFER

\ define variables needed to implement NUMBER, INTERPRET, and KEY
VARIABLE STATE
VARIABLE NUMBER_CURLEN
VARIABLE NUMBER_CURADDR
VARIABLE NUMBER_CURSUM
VARIABLE INTERPRET_IS_LIT
VARIABLE BASE G10 BASE !
:04 GRAB_WORD_AS_NUM WORD0 DROP @ EXIT 00; \ used to temporarily store "ERR?" in a 4-byte variable
VARIABLE INTERPRET_ERR GRAB_WORD_AS_NUM ERR? INTERPRET_ERR !
VARIABLE INTERPRET_ERRMSG INTERPRET_ERR INTERPRET_ERRMSG !
VARIABLE INTERPRET_ERRMSGLEN G2 DUP * INTERPRET_ERRMSGLEN !
VARIABLE INTERPRET_ERRNL G10 INTERPRET_ERRNL !
VARIABLE INTERPRET_ERRMSGNL INTERPRET_ERRNL INTERPRET_ERRMSGNL !
VARIABLE KEY_BUFFTOP KEY_BUFFER KEY_BUFFTOP !
VARIABLE KEY_CURRKEY KEY_BUFFER KEY_CURRKEY !

\ define some new words needed for a full forth interpreter

:04 ] G1 STATE ! EXIT 00;

:04 HIDDEN G4 + DUP C@ DUP F_HIDDEN SWAP F_HIDDEN NAND DUP NAND - SWAP F_HIDDEN DUP NAND NAND 
    DUP NAND + SWAP C! EXIT 00;

\ define 8-char name SYSCALL3
:04 SYSCALL3 SYSCALL EXIT 00;

:04 CALL_SYS_EXIT G0 G0 G0 SYS_EXIT SYSCALL3 EXIT 00;

\ start hiding early versions of words to be replaced
:04 HIDE WORD0 FIND HIDDEN EXIT 00;

HIDE KEY
:04 KEY KEY_CURRKEY @ KEY_BUFFTOP @ SWAP 1+ < 0BRANCH 70 KEY_BUFFER KEY_CURRKEY ! KEY_BUFFER_SIZE 
    KEY_BUFFER G0 SYS_READ SYSCALL3 DUP G1 < 0BRANCH 44 DROP CALL_SYS_EXIT EXIT KEY_BUFFER + 
    KEY_BUFFTOP ! G0 0BRANCH 01 KEY_CURRKEY @ C@ KEY_CURRKEY @ 1+ KEY_CURRKEY ! EXIT 00;

:04 WORD G0 DROP KEY DUP G92 - 0= 0BRANCH 51 DROP KEY DUP G10 - 0= 0BRANCH 31 DUP G32 SWAP < 
    0BRANCH 13 WB SWAP WB SWAP SWAP C! 1+ DUP KEY DUP G32 1+ < 0BRANCH 26 DROP DROP WB - WB SWAP 
    EXIT 00;

\ finally, the proper : word we want
:04 : WORD CREATE DOCOL , LATEST @ HIDDEN ] EXIT 00;

:04 IMMEDIATE LATEST @ G4 + DUP C@ DUP F_IMMED SWAP F_IMMED NAND DUP NAND - SWAP F_IMMED DUP NAND 
    NAND DUP NAND + SWAP C! EXIT 00; IMMEDIATE
:04 [ G0 STATE ! EXIT 00; IMMEDIATE 

:04 ; LIT EXIT , LATEST @ HIDDEN [ EXIT 00; IMMEDIATE

\ a helper for NUMBER
:04 DIGIT_FROM_CHAR DUP G58 < 0BRANCH 43 G48 - DUP G64 SWAP < 0BRANCH 43 G55 - DUP DUP BASE @ 
    SWAP - SWAP 1+ * G1 < 0= SWAP EXIT 00;

\ NUMBER for actual number parsing
:04 NUMBER NUMBER_CURLEN ! NUMBER_CURADDR ! G0 NUMBER_CURSUM ! G0 NUMBER_CURLEN @ 0BRANCH 65 
    NUMBER_CURADDR @ C@ G45 - 0= 0BRANCH 55 1+ NUMBER_CURADDR @ 1+ NUMBER_CURADDR ! NUMBER_CURLEN 
    @ G1 - NUMBER_CURLEN ! NUMBER_CURLEN @ 0BRANCH 77 NUMBER_CURSUM @ BASE @ * NUMBER_CURSUM ! 
    NUMBER_CURADDR @ C@ G1 NUMBER_CURADDR +! DIGIT_FROM_CHAR NUMBER_CURSUM @ + NUMBER_CURSUM ! 
    NUMBER_CURLEN @ G1 - DUP NUMBER_CURLEN ! * 0= 0BRANCH 03 0BRANCH 47 G0 NUMBER_CURSUM @ - 
    NUMBER_CURSUM ! NUMBER_CURSUM @ NUMBER_CURLEN @ EXIT 00;

\ a helper to display parse error
\ :04 INTERPRET_ERROR INTERPRET_ERRMSGLEN @ INTERPRET_ERRMSG @ G2 SYS_WRITE SYSCALL3 DROP 
\     KEY_CURRKEY @ KEY_BUFFER - DUP G40 SWAP G40 SWAP < 0BRANCH 42 SWAP DROP KEY_BUFFER G2 
\     SYS_WRITE SYSCALL3 DROP G1 INTERPRET_ERRMSGNL @ G2 SYS_WRITE SYSCALL3 DROP EXIT 00;
:04 INTERPRET_ERROR INTERPRET_ERRMSGLEN @ INTERPRET_ERRMSG @ G2 SYS_WRITE SYSCALL3 DROP
    KEY_CURRKEY @ KEY_BUFFER - DUP KEY_BUFFER + SWAP DUP G40 SWAP G40 SWAP < 0BRANCH 42
    SWAP DROP 2DUP - G2 SYS_WRITE SYSCALL3 DROP G1 INTERPRET_ERRMSGNL @ G2 SYS_WRITE 
    SYSCALL3 DROP EXIT 00;

:04 INTERPRET WORD 2DUP G0 INTERPRET_IS_LIT ! FIND DUP 0BRANCH 65 SWAP DROP SWAP DROP DUP 1+ 1+ 
    1+ 1+ C@ SWAP >CFA SWAP F_IMMED NAND DUP NAND G0 0BRANCH 56 INTERPRET_IS_LIT @ 1+ 
    INTERPRET_IS_LIT ! DROP NUMBER 0BRANCH 44 DROP INTERPRET_ERROR EXIT G0 0= STATE @ * G1 SWAP 
    - 0BRANCH 55 INTERPRET_IS_LIT @ 0= 0BRANCH 45 EXECUTE G0 0BRANCH 41 G0 0BRANCH 51 
    INTERPRET_IS_LIT @ 0BRANCH 44 ' LIT , , EXIT 00;

\ redefine VARIABLE using the new WORD
:04 VARIABLE G1 CELLS ALLOT WORD CREATE DOCOL , ' LIT , , ' EXIT , EXIT 00;

\ now switch to using the new QUIT, INTERPRET, NUMBER, WORD, and KEY
\ everything after is written in forth, not the simplistic psudeo-forth needed to bootstrap
\ but first, HIDE the comment words since we won't need them
HIDE \\\
HIDE \\\_
HIDE \
HIDE HIDE
:04 QUIT R0 RSP! INTERPRET G0 0BRANCH 35 00;
QUIT

\ replace HIDE with a version using WORD vs WORD0
: HIDE WORD FIND HIDDEN ;

\ hide a lot of words used internally above
HIDE DOC	HIDE sta	HIDE SYSCALL	HIDE INI
HIDE WB		HIDE RET	HIDE YCHR	HIDE SCHR
HIDE FIX2	HIDE F_LENMA	HIDE F_HIDDE	HIDE S<4
HIDE SHT	HIDE QUI	HIDE :04	HIDE CRE 
HIDE CMO 	HIDE C@C 	HIDE FIN 	HIDE INN 
HIDE CMP 	HIDE R>_ 	HIDE >R_ 	HIDE RDR 
HIDE F_L 	HIDE F_H 	HIDE QUI	HIDE :01
HIDE NUM 	HIDE WOR 	HIDE WOR 	HIDE ,__
HIDE 0=_ 	HIDE CRE 	HIDE >CF 	HIDE FIN
HIDE COL 	HIDE 2DU 	HIDE 0BR	HIDE +__
HIDE G32 	HIDE G4 	HIDE G0 	HIDE G1_
HIDE G_1 	HIDE G12 	HIDE G52 	HIDE G36 
HIDE G68 	HIDE G60 	HIDE G16 	HIDE G32 
HIDE G4_ 	HIDE :00 	HIDE __' 	HIDE 256 
HIDE WOR 	HIDE FIN 	HIDE G_4	HIDE SYS_CRE
HIDE SYS_WRI 	HIDE SYS_REA 	HIDE SYS_CLO 	HIDE SYS_OPE
HIDE SYS_EXI 	HIDE G92 	HIDE G64 	HIDE G58 
HIDE G55 	HIDE G48 	HIDE G45 	HIDE G40 
HIDE G16 	HIDE G10 	HIDE G3 	HIDE G2 
HIDE G1 	HIDE :02 	HIDE QUIT0 	HIDE :03_ 
HIDE WORD0 	HIDE NUM0 	HIDE KEY0 	HIDE FINNER 
HIDE R>__ 
HIDE INTERPRET_ERROR 		HIDE DIGIT_FROM_CHAR 
HIDE CALL_SYS_EXIT 		HIDE KEY_CURRKEY 
HIDE KEY_BUFFTOP 		HIDE INTERPRET_ERRMSGNL 
HIDE INTERPRET_ERRNL 		HIDE INTERPRET_ERR 
HIDE GRAB_WORD_AS_NUM 		HIDE INTERPRET_IS_LIT 
HIDE NUMBER_CURSUM 		HIDE NUMBER_CURADDR 
HIDE NUMBER_CURLEN 		HIDE KEY_BUFFER 
HIDE KEY_BUFFER_SIZE 		HIDE VARIABLE_BIG 

\ hide some more that are redefined later in jonesforth.f
HIDE VARIABLE 	HIDE VARIABLE 	HIDE CELLS 	HIDE CONSTANT

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\ now running forth and not the simpler pseudo-forth, so can't use KEY0, WORD0, NUM0, or :0x anymore
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ implement some of jonesforth's original asm core words in forth
: 2DROP DROP DROP ;
: INVERT DUP NAND ;
: AND NAND INVERT ;
: 1- 1 - ;
: 4- 4 - ;
: 4+ 4 + ;
: R> RSP@ 4+ @ RSP@ @ RSP@ 4+ ! RSP@ 4+ RSP! ;
: ROT >R SWAP R> SWAP ;
: -ROT ROT ROT ;
: = - 0= ;
: <> = 0= ;
: > SWAP < ;
: <= > 0= ;
: >= < 0= ;
: 0<> 0= 0= ;
: 0< 0 < ;
: 0> 0 > ;
: 0<= 0> 0= ;
: 0>= 0< 0= ;
: 2SWAP ROT >R ROT R> ;
: SYSCALL2 0 SWAP 2SWAP ROT SYSCALL3 ;
: SYSCALL1 0 -ROT SYSCALL2 ;
: SYSCALL0 0 SWAP SYSCALL1 ;
: OVER SWAP DUP -ROT ;
: OR INVERT SWAP INVERT NAND ;
: XOR 2DUP NAND DUP -ROT NAND -ROT NAND NAND ;
: -! DUP -ROT @ - SWAP ! ;
: >DFA >CFA 4+ ;
: TELL SWAP 1 SYS_WRITE SYSCALL3 DROP ;
: EMIT 255 AND DSP@ 1 SWAP 1 SYS_WRITE SYSCALL3 2DROP ;
: CHAR WORD DROP @ 255 AND ;
: IF IMMEDIATE ' 0BRANCH , HERE @ 0 , ;
: THEN IMMEDIATE DUP HERE @ SWAP - SWAP ! ;
: ?DUP DSP@ @ IF DUP THEN ;
: BRANCH RSP@ @ DUP @ + RSP@ ! ;

: LITSTRING
	RSP@ @ DUP 2DUP 	\ next next next next(top)
	@ 4+ 3 +		\ next next next len+4+3
	-4 AND			\ next next next (len+4+3)&~3
	+			\ next next next+(len+4+3)&~3
	RSP@ !			\ next next [next += (len+4+3)&~3]
	4+ SWAP			\ next+4 next
	@			\ next+4 len
;

\ some file read/write constants
: CONSTANT WORD CREATE DOCOL , ' LIT , , ' EXIT , ; 
0 CONSTANT O_RDONLY
1 CONSTANT O_WRONLY
2 CONSTANT O_RDWR
64 CONSTANT O_CREAT
128 CONSTANT O_EXCL
512 CONSTANT O_TRUNC
1024 CONSTANT O_APPEND
2048 CONSTANT O_NONBLOCK

\ Set based on the version of the original jonesforth.S used
47 CONSTANT VERSION 

\ we don't have an easy way to grab a string, so make some helpers
: COPY_WORD		\ buff(top)
	DUP WORD	\ buff buff word len
	ROT SWAP	\ buff word buff len
	DUP >R		\ buff word buff len
	CMOVE
	R> +		\ buff+len
;
: ADD_SPACE		\ buff(top)
	DUP 32 SWAP	\ buff 32 buff
	C! 1+		\ buff+1
;
: GRAB_ERROR_STRING_AND_COPY 		\ buff(top)
	COPY_WORD ADD_SPACE		\ buff+len+1
	COPY_WORD ADD_SPACE	 	\ buff+len+1+len+1
	DROP
;

\ set error message to full message. 13 should be enough, 16 to align
16 ALLOT CONSTANT ERRORBUFFER
ERRORBUFFER GRAB_ERROR_STRING_AND_COPY PARSE ERROR:
13 INTERPRET_ERRMSGLEN !
ERRORBUFFER INTERPRET_ERRMSG !

\ hide some more things not needed (some redefined in jonesforth.f)
\ HIDE ERRORBUFFER 
HIDE GRAB_ERROR_STRING_AND_COPY 
HIDE ADD_SPACE 
HIDE COPY_WORD 
HIDE INTERPRET_ERRMSGLEN 
HIDE INTERPRET_ERRMSG 
HIDE ALLOT 
HIDE CONSTANT
HIDE THEN
HIDE IF
