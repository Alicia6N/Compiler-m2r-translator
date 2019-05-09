#!/bin/bash
flex plp5.l
bison -d plp5.y
g++ -o test plp5.tab.c lex.yy.c
./test test_mult.txt > m2rcode
gcc -o m2r m2r.c
./m2r m2rcode

