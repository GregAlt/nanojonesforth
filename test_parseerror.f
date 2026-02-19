( -*- text -*- )

: A 1 2 DUP SWAP FOO 9 10 11 12 ;

: TEST
        1 SWAP                  \ 1 n
        BEGIN
                DUP -ROT        \ n 1 n
                *               \ n 1*n
                SWAMP 1-        \ 1*n n-1
                DUP 0=          \ 1*n n-1 0?
        UNTIL                   \ 1*n n-1
        DROP                    \ n!
;

