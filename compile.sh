#!/bin/bash
flex plp5.l
bison -d plp5.y
g++ -o test plp5.tab.c lex.yy.c
