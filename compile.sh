#!bin/bash
flex plp5.l
bison -d plp5.y
g++ -o code plp5.tab.c lex.yy.c
