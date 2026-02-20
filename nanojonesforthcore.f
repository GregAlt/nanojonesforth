: INVERT DUP NAND ;
: AND NAND INVERT ;
: 2DROP DROP DROP ;
: RDROP RSP@ @ RSP@ 4 + RSP! RSP@ ! ;
: >R RSP@ @ SWAP RSP@ ! RSP@ 4 - DUP RSP! ! ;
: 4+ 4 + ;
: R> RSP@ 4+ @ RSP@ @ RSP@ 4+ ! RSP@ 4+ RSP! ;
: ROT >R SWAP R> SWAP ;
: -ROT ROT ROT ;
: 2SWAP ROT >R ROT R> ;
: OVER SWAP DUP -ROT ;
: 1- 1 - ;
: 4- 4 - ;
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
: 0<= 0> 0= ;
: 0>= 0< 0= ;
: OR INVERT SWAP INVERT NAND ;
: XOR 2DUP NAND DUP -ROT NAND -ROT NAND NAND ;
: IMMEDIATE LATEST @ 4 + DUP C@ DUP F_IMMED SWAP F_IMMED NAND DUP NAND - SWAP F_IMMED DUP NAND
    NAND DUP NAND + SWAP C! ; IMMEDIATE
: IF IMMEDIATE ' 0BRANCH , HERE @ 0 , ;
: THEN IMMEDIATE DUP HERE @ SWAP - SWAP ! ;
: ?DUP DSP@ @ IF DUP THEN ;
: +! 2DUP @ + SWAP ! DROP ;
: -! DUP -ROT @ - SWAP ! ;
: SYSCALL2 0 SWAP 2SWAP ROT SYSCALL3 ;
: SYSCALL1 0 -ROT SYSCALL2 ;
: SYSCALL0 0 SWAP SYSCALL1 ;
: EMIT 255 AND DSP@ 1 SWAP 1 SYS_WRITE SYSCALL3 2DROP ;
: TELL SWAP 1 SYS_WRITE SYSCALL3 DROP ;
: LITSTRING
        RSP@ @ DUP 2DUP         \ next next next next(top)
        @ 4+ 3 +                \ next next next len+4+3
        -4 AND                  \ next next next (len+4+3)&~3
        +                       \ next next next+(len+4+3)&~3
        RSP@ !                  \ next next [next += (len+4+3)&~3]
        4+ SWAP                 \ next+4 next
        @                       \ next+4 len
;
