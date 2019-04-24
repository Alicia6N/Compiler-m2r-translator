%token _class attributes methods _int
%token _main _print _scan _if
%token _else _while _this id
%token nentero nreal _float
%token  dosp coma pyc punto
%token pari pard relop addop
%token mulop assig cori cord
%token llavei llaved

%token return

%{

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <iostream>
#include <algorithm>
#include "comun.h"
using namespace std;

// Variables y Funciones del Analizador Lexico
extern int ncol, nlin, findefichero;
extern int yylex();
extern char *yytext;
extern FILE *yyin;
int yyerror(char *s);

%}

S : class id llavei attributes dosp BDecl methods dosp Metodos llaved   {
                                                                            int tk = yylex();
                                                                            if (tk != 0) yyerror("");
                                                                        };

Metodos : int main pari pard Bloque {};

Tipo : int {}
     | float {};

Bloque : llavei BDecl SeqInstr llaved {};

BDecl : BDecl DVar {}
      | {};

DVar : Tipo LIdent pyc {};

LIdent : LIdent coma Variable {}
       | Variable {};

Variable : id V {};

V : cori nentero cord V {}
  | {};

SeqInstr : SeqInstr Instr {};

Instr : pyc {}
      | Bloque {}
      | Ref asig Expr pyc {}
      | print pari Expr pard pyc {}
      | scan pari Ref pard pyc {}
      | if pari Expr pard Instr {}
      | if pari Expr pard Instr else Instr {}
      | while pari Expr pard Instr {};

Expr : Exptr relop Esimple {}
     | Esimple{};

Esimple : Esimple addop Term{}
        | Term{};

Term : Term mulop Factor{}
     | Factor {};

Factor : Ref {}
       | nentero {}
       | nreal {}
       | pari Expr pard {};

Ref : this punto id {}
    | id {}
    | Ref cori Esimple cord {};


Metodos : Met Metodos {};

Met : Tipo id pari Arg pard Bloque {};

Arg : {}
    | CArg {};

CArg : Tipo id CArgp {};

CArgp : coma Tipo id CArgp {}
      | {};

Instr : return Expr pyc {};

Factor : id pari Par pard {};

Par : {}
    | Expr CPar {};

CPar : {}
     | coma Expr CPar {};

%%

%%

void msgError(int nerror, int nlin, int ncol, const char *s){
     switch (nerror) {
         case ERRLEXICO: fprintf(stderr,"Error lexico (%d,%d): caracter '%s' incorrecto\n",nlin,ncol,s);
            break;
         case ERRSINT: fprintf(stderr,"Error sintactico (%d,%d): en '%s'\n",nlin,ncol,s);
            break;
         case ERREOF: fprintf(stderr,"Error sintactico: fin de fichero inesperado\n");
            break;
         case ERRLEXEOF: fprintf(stderr,"Error lexico: fin de fichero inesperado\n");
            break;
         default:
            fprintf(stderr,"Error semantico (%d,%d): ", nlin,ncol);
            switch(nerror) {
             case ERRYADECL: fprintf(stderr,"simbolo '%s' ya declarado\n",s);
               break;
             case ERRNODECL: fprintf(stderr,"identificador '%s' no declarado\n",s);
               break;
             case ERRDIM: fprintf(stderr,"la dimension debe ser mayor que cero\n");
               break;
             case ERRFALTAN: fprintf(stderr,"faltan indices\n");
               break;
             case ERRSOBRAN: fprintf(stderr,"sobran indices\n");
               break;
             case ERR_EXP_ENT: fprintf(stderr,"la expresion entre corchetes debe ser de tipo entero\n");
               break;
             case ERR_NO_ATRIB: fprintf(stderr,"el simbolo despues de 'this' debe ser un atributo\n");
               break;
             case ERR_NOCABE:fprintf(stderr,"la variable '%s' ya no cabe en memoria\n",s);
               break;
             case ERR_MAXVAR:fprintf(stderr,"en la variable '%s', hay demasiadas variables declaradas\n",s);
               break;
             case ERR_MAXTIPOS:fprintf(stderr,"hay demasiados tipos definidos\n");
               break;
             case ERR_MAXTMP:fprintf(stderr,"no hay espacio para variables temporales\n");
               break;
            }
        }
     exit(1);
}

int yyerror(char *s){
    extern int findefichero;
    if (findefichero) {
       msgError(ERREOF,-1,-1,"");
    }
    else{  
       msgError(ERRSINT,nlin,ncol-strlen(yytext),yytext);
    }
}

bool equalsIgnoreCase(string s1, char* lexema){
   string s2 = string(lexema);
   transform(s2.begin(), s2.end(), s2.begin(), ::tolower);

   if (s1 == s2)
      return true;

   return false;
}

int main(int argc, char *argv[]){
   FILE *fent;

   if (argc == 2) {
      fent = fopen(argv[1], "rt");
      if (fent) {
         yyin = fent;
         yyparse();
         fclose(fent);
      }
      else
         fprintf(stderr, "No puedo abrir el fichero\n");
   }
   else
      fprintf(stderr, "Uso: ejemplo <nombre de fichero>\n");
}