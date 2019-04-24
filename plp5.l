/*------------------------------ plp5.l -------------------------------*/
D [0-9]
L [a-zA-Z]
LD [0-9a-zA-Z]

%{
#include <string.h>
#include <string>
#include <iostream>
using namespace std;
#include "comun.h"
#include "plp5.tab.h"
int ncol = 1, nlin = 1;
int findefichero = 0;
int ret(int token); // funcion que actualiza ’nlin’ y ’ncol’ y devuelve el token
void msgError(int nerror, int nlin,int ncol,const char *s); // funcion para producir mensajes de error
%}

%x COMENTARIO

%%
%{
/* codigo local */
%}

" "                 {ncol++;}
[\t]                {ncol++;}
[\n]                {nlin++;ncol=1;}
"//"(.)*            {; /* comentarios de una linea, no hacer nada */}

"class"             {return ret(_class);}
"attributes"        {return ret(attributes);}
"methods"           {return ret(methods);}
"int"               {return ret(_int);}
"float"             {return ret(_float);}
"main"              {return ret(_main);}
"print"             {return ret(_print);}
"scan"              {return ret(_scan);}
"if"                {return ret(_if);}
"else"              {return ret(_else);}
"while"             {return ret(_while);}
"this"              {return ret(_this);}


"return"            {return ret(_return);}


{L}({LD})*          {return ret(id);}
{D}+                {return ret(nentero);}
{D}+(\.){D}+        {return ret(nreal);}

":"                 {return ret(dosp);}
","                 {return ret(coma);}
";"                 {return ret(pyc);}
"."                 {return ret(punto);}
"("                 {return ret(pari);}
")"                 {return ret(pard);}
"=="                {return ret(relop);}
"!="                {return ret(relop);}
"<"                 {return ret(relop);}
"<="                {return ret(relop);}
">"                 {return ret(relop);}
">="                {return ret(relop);}
"+"                 {return ret(addop);}
"-"                 {return ret(addop);}
"*"                 {return ret(mulop);}
"/"                 {return ret(mulop);}
"="                 {return ret(asig);}
"["                 {return ret(cori);}
"]"                 {return ret(cord);}
"{"                 {return ret(llavei);}
"}"                 {return ret(llaved);}

.                   {msgError(ERRLEXICO,nlin,ncol,yytext);}

%%

int yywrap(void) {findefichero=1; return 1;} /* para no tener que linkar con la libreria del lex */
int ret(int token){
   yylval.lexema=strdup(yytext);
   yylval.nlin=nlin;
   yylval.ncol=ncol;
   ncol+=(strlen(yytext));
   return(token);
}