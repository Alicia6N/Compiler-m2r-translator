%token _class attributes methods _int
%token _main _print _scan _if
%token _else _while _this id
%token nentero nreal _float
%token  dosp coma pyc punto
%token pari pard relop addop
%token mulop asig cori cord
%token llavei llaved 

%token _return

%{

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <cstdlib>
#include <string>
#include <iostream>
#include <algorithm>
#include <string>
#include "comun.h"
using namespace std;

// Variables y Funciones del Analizador Lexico
extern int ncol, nlin, findefichero;
extern int yylex();
extern char *yytext;
extern FILE *yyin;
int yyerror(char *s);
const int MEM = 16384;
int ACTUAL_MEM = 1;
int ETIQ = 0;
TablaSimbolos *ts = new TablaSimbolos(NULL);
void deleteScope(TablaSimbolos* root);
TablaSimbolos* createScope(TablaSimbolos* root);
TablaTipos* tp = new TablaTipos(); 
Simbolo buscarClase(TablaSimbolos *root, string nombre);
Simbolo buscar(TablaSimbolos *root, string nombre);
bool anyadir(TablaSimbolos *t,Simbolo s);
bool buscarAmbito(TablaSimbolos *root, string nombre);
string nuevoTemporal(int nerror, int nlin, int ncol, const char *s);
string nuevaEtiq();
string getRelop(string op);
int getRelopIndex(string op);

// DONE:  	
//			- 

// TO DO: 
//			- arrays
//			- probar varias condiciones en los ifs (&& --> *)


%}
%%
S : _class id llavei attributes dosp BDecl methods dosp Metodos llaved   	{
																				$$.code = $6.code + $9.code;
																				$$.code += "halt\n";
																				cout << $$.code << endl;
																		   		int tk = yylex();
																		   		if (tk != 0) yyerror("");
																			};

Metodos : _int _main pari pard Bloque { $$.code = $5.code; };

Tipo 	: _int {$$.tipo = ENTERO; }
	 	| _float {$$.tipo = REAL; };

Bloque : llavei {ts = new TablaSimbolos(ts);} BDecl SeqInstr llaved 	{
																	 		$$.code = $3.code + $4.code;
																	 		deleteScope(ts);
																			ts = ts->root;
																		};

BDecl 	: BDecl DVar {$$.code = "";}
	  	| {$$.code = "";};

DVar : Tipo  LIdent pyc {$$.code = "";};

LIdent : LIdent coma {$$.tipo = $0.tipo;} Variable {}
	   | {$$.tipo = $0.tipo;} Variable {};

Variable : 	id { $$.array = 1; } V   	{
											$1.tipo = $0.tipo;
											if ($3.tipo == ARRAY)
												$1.tipo = ARRAY;
											if(!buscarAmbito(ts,$1.lexema))  {
												Simbolo s;
												s.nombre = $1.lexema;
												s.tipo = $1.tipo;
												//var = tp.getDt(s.tipo);
												ACTUAL_MEM += $3.size;
												s.dir = to_string(ACTUAL_MEM);
												s.size = $3.size;
												anyadir(ts,s);

												if (ACTUAL_MEM >= MEM)
													msgError(ERR_NOCABE,$1.nlin,$1.ncol,$1.lexema);
											}    
											else{
												msgError(ERRYADECL,$1.nlin,$1.ncol,$1.lexema);  
											}        
										};

V 	: cori nentero cord { $$.array = $0.array * atoi($2.lexema); } V 	{ 
																			$$.size = $5.size;
																			if ($$.size > 1)
																				$$.tipo = ARRAY;
																		}
	| { $$.size = 1; };

SeqInstr : SeqInstr Instr 								{ $$.code = $1.code + $2.code; }
		 | {  };

Instr : pyc {  }
	  | Bloque { $$.code = $1.code; }
	  | Ref asig Expr pyc  								{ 	
															$$.code = $3.code;
															$$.code += "mov " + $3.temp + " " + $1.temp + "\t; Instr : Ref asig Expr pyc \n";
														}
	  | _print pari Expr pard pyc 						{
		  													$$.code = $3.code;
															if ($3.tipo == ENTERO){
																$$.code += "wri " + $3.temp + "\t print valor entero de temporal\n";
															}
															else if($3.tipo == REAL){
																$$.code += "wrr " + $3.temp + "\t print valor real de temporal\n";
															}
															$$.code += "wrl\n";
														}
	  | _scan pari Ref pard pyc 						{
															$$.code = $3.code;
															if ($3.tipo == ENTERO){
																$$.code += "rdi " + $3.temp + "\t guardar valor entero en temporal\n";
															}
															else if($3.tipo == REAL){
																$$.code += "rdr " + $3.temp + "\t guardar valor real en temporal\n";
															}
	  													}
	  | _if pari Expr pard Instr 						{
															$$.code = $3.code;
															$$.code += "mov " + $3.temp + " A\n";
		  													string etiqueta = nuevaEtiq();
															$$.code += "jz " + etiqueta + "\n";
															$$.code += $5.code;
															$$.code += etiqueta + " ";
	  													}
	  | _if pari Expr pard Instr _else Instr 			{
		  													$$.code = $3.code;
															string etiqueta1 = nuevaEtiq();
															string etiqueta2 = nuevaEtiq();
															$$.code += "mov " + $3.temp + " A\n";
															$$.code += "jz " + etiqueta1 + "\n";
															$$.code += $5.code;
															$$.code += "jmp " + etiqueta2 +"\n";
															$$.code += etiqueta1 + " ";
															$$.code += $7.code;
															$$.code += etiqueta2 + " ";
														}
	  | _while pari Expr pard Instr 					{
		  													string etiqueta1 = nuevaEtiq();
															string etiqueta2 = nuevaEtiq();
															$$.code += etiqueta1 + " ";
															$$.code += $3.code;
															$$.code += "mov " + $3.temp + " A\n";
															$$.code += "jz " + etiqueta2 + "\n";
															$$.code += $5.code;
															$$.code += "jmp " + etiqueta1 +"\n";
															$$.code += etiqueta2 + " ";
	  													};

Expr : 	Expr relop Esimple 							{
														string temp_final = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
														if(($1.tipo == ARRAY || $3.tipo == ARRAY)){
															msgError(ERR_NO_ATRIB,$2.nlin,$2.ncol,$2.lexema);
														}			
														string op = $2.lexema;								
														$$.code += $1.code;
														$$.code += $3.code;
														if($1.tipo == ENTERO && $3.tipo == ENTERO){
															$$.code += "mov " + $1.temp + " A\n";
															$$.code += getRelop(op) + "i " + $3.temp + "\t; Expr relop Esimple\n";
															
														}
														else if($1.tipo == ENTERO && $3.tipo == REAL){
															string temp1 = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
															$$.code += "mov " + $1.temp + " A\n";
															$$.code += "itor \n";
															$$.code += getRelop(op) + "r " + $3.temp + "\t; Expr relop Esimple\n";
														}
														else if($1.tipo == REAL && $3.tipo == ENTERO){
															string temp1 = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
															$$.code += "mov " + $3.temp + " A\n";
															$$.code += "itor \n";
															$$.code += getRelop(op) + "r " + temp1 + "\t; Expr relop Esimple\n";
														}	
														else { //reales
															$$.code += "mov " + $1.temp + " A\n";
															$$.code += getRelop(op) + "r " + $3.temp + "\t; Expr relop Esimple\n";
														}
														$$.code += "mov A " + temp_final + "\t; guardar el resultado en temporal\n";
														$$.temp = temp_final;
													}
	 |  Esimple 									{ 
		 												$$.code = $1.code;
														$$.tipo = $1.tipo;	
													};

Esimple : Esimple addop Term  	{   
									string temp_final = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
									$$.temp = temp_final;
									string op = "";
									if(strcmp($2.lexema,"+")==0){
										op = "add";
									}
									else 
										op = "sub";

									cout << "Tipo 1 y 3: " << $1.tipo << " " << $3.tipo << endl;

									if($1.tipo == ENTERO && $3.tipo == ENTERO){
										$$.code = "; ENTEROS \n";
										$$.code += $1.code;
										$$.tipo = ENTERO;
										$$.code += $3.code; //se mete en la A el resultado de Term
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += op + "i " + $3.temp + " \n";
									}
									else if($1.tipo == ENTERO && $3.tipo == REAL){
										$$.code += $1.code;
										$$.tipo = REAL;
										string temp1 = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += "itor \n";
										$$.code += "mov A " + temp1 + " \n";
										$$.code += $3.code;
										$$.code += "mov " + temp1 + " A\n";
										$$.code += op +"r " + $3.temp + " \n";
										//ACTUAL_MEM--;
									}
									else if($1.tipo == REAL && $3.tipo == ENTERO){
										$$.code += $1.code;
										$$.tipo = REAL;
										$$.code += $3.code;
										string temp1 = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
										$$.code += "mov " + $3.temp + " A\n";
										$$.code += "itor \n";
										$$.code += "mov A " + temp1 + " \n";
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += op +"r " + temp1 + " \n";
										//ACTUAL_MEM--;
									}	
									else { //reales
										$$.code = "; REALES \n";
										$$.code += $1.code;
										$$.tipo = REAL;
										$$.code += $3.code;
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += op + "r " + $3.temp + "\n";
							  		}
									$$.code += "mov A " + temp_final + "\t; guardar el resultado en temporal\n";
								}
		| Term 					{ 
									$$.code = $1.code;
									$$.tipo = $1.tipo;
									$$.temp = $1.temp;
			   					};

Term : Term mulop Factor   	{
								string temp_final = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
								$$.temp = temp_final;
								string op = "";
								if(strcmp($2.lexema,"*")==0){
									op = "mul";
								}
								else
									op = "div";

								if($1.tipo == ENTERO && $3.tipo == ENTERO){
									$$.code = "; ENTEROS \n";
									$$.code += $1.code;
									$$.tipo = ENTERO;
									$$.code += $3.code;
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += op + "i " + $3.temp + "\t; Term : Term mulop Factor\n";
								}
								else if($1.tipo == ENTERO && $3.tipo == REAL){
									$$.tipo = REAL;
									$$.code = "; ENTERO Y REAL \n";
									$$.code += $1.code;
									string temp1 = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += "itor \n";
									$$.code += "mov A " + temp1 + "\n";
									$$.code += $3.code;
									$$.code += "mov " + temp1 + " A\n";
									$$.code += op + "r " + $3.temp + "\t; Term : Term mulop Factor\n";
									//ACTUAL_MEM--;
								}
								else if($1.tipo == REAL && $3.tipo == ENTERO){
									$$.code = "; REAL y ENTERO \n";
									$$.code += $1.code;
									$$.tipo = REAL;
									$$.code += $3.code;
									string temp1 = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
									$$.code += "mov " + $3.temp + " A\n";
									$$.code += "itor\n";
									$$.code += "mov A " + temp1 + "\n";
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += op + "r " + temp1 + "\t; Term : Term mulop Factor\n";
									//ACTUAL_MEM--;
								}	
								else { //reales
									$$.code = "; REALES \n";
									$$.code += $1.code;
									$$.tipo = REAL;
									$$.code += $3.code;
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += op + "r " + $3.temp + "\t; Term : Term mulop Factor\n";
								}

								$$.code += "mov A " + temp_final + "\t; guardar el resultado en temporal\n";
						   	}
	 | Factor  	{ 
					$$.tipo = $1.tipo;
					$$.code = $1.code;
					$$.temp = $1.temp;
			   	};

Factor :  Ref      		{ 
							string temp = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
							$$.tipo = $1.tipo;
							$$.temp = temp;
							$$.code += "mov " + $1.temp + " " + temp + "\t; guarda " + $$.aux_lexema + "\n";
						}
	   | nentero  		{
							string aux_lex = $1.lexema;
							string temp = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
							$$.tipo = ENTERO;
							$$.temp = temp;
							$$.code = "mov #" + aux_lex + " " + temp + "\n";
						}
	   | nreal    		{
							string aux_lex = $1.lexema;
							string temp = nuevoTemporal(ERR_MAXTMP, $1.nlin, $1.ncol, $1.lexema);
							$$.tipo = REAL;
							$$.temp = temp;
							$$.code = "mov $" + aux_lex + " " + temp + "\n";
						}
	   | pari Expr pard { 
							$$.code = $2.code + "\t; Factor -> pari Expr pard\n";
						};

Ref : _this punto id  			{
									Simbolo s = buscarClase(ts, $3.lexema);
									if (s.nombre != ""){
										if ($$.tipo != 3){
											$$.tipo = s.tipo;
											$$.temp = s.dir;
										}
									}
									else
										msgError(ERR_NO_ATRIB, $1.nlin, $1.ncol, $1.lexema);
								}
	| id 						{ 
									Simbolo s = buscar(ts, $1.lexema);
									if (s.nombre != ""){
										if ($$.tipo != 3){
											$$.tipo = s.tipo;
											$$.temp = s.dir;
											string aux = $1.lexema;
											$$.aux_lexema = aux;
										}
									}
									else
										msgError(ERRNODECL, $1.nlin, $1.ncol, $1.lexema);
								}
	| Ref cori Esimple cord 	{};

Metodos : Met Metodos {};

Met : Tipo id pari Arg pard Bloque {};

Arg : {}
	| CArg {};

CArg : Tipo id CArgp {};

CArgp : coma Tipo id CArgp {}
	  | {};

Instr : _return Expr pyc {};

Factor : id pari Par pard {};

Par : {}
	| Expr CPar {};

CPar : {}
	 | coma Expr CPar {};

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
string getRelop(string op){
	int op_index = getRelopIndex(op);

	switch(op_index){
		case 1:
			return "eql";
		case 2:
			return "neq";
		case 3:
			return "lss";
		case 4:
			return "leq";
		case 5:
			return "gtr";
		case 6:
			return "geq";
	}
}
int getRelopIndex(string op){
	if (op == "==")
		return 1;
	if (op == "!=")
		return 2;
	if (op == "<")
		return 3;
	if (op == "<=")
		return 4;
	if (op == ">")
		return 5;
	if (op == ">=")
		return 6;
}
bool equalsIgnoreCase(string s1, char* lexema){
	string s2 = string(lexema);
	transform(s2.begin(), s2.end(), s2.begin(), ::tolower);

	if (s1 == s2)
		return true;

	return false;
}
string nuevoTemporal(int nerror, int nlin, int ncol, const char *s){
	ACTUAL_MEM++;
	if ((ACTUAL_MEM + 1) >= MEM)
		msgError(nerror, nlin, ncol, s);
	return to_string(ACTUAL_MEM);
}
string nuevaEtiq(){
	ETIQ++;
	string etiqueta = "L"+to_string(ETIQ);
	return etiqueta;
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
/*****TABLA SIMBOLOS*********/
bool buscarAmbito(TablaSimbolos *root,string nombre){
	for(size_t i=0;i<root->simbolos.size();i++){
		if(root->simbolos[i].nombre == nombre){
			return true;
		}
	}
	return false;
}
bool anyadir(TablaSimbolos *t,Simbolo s){
	for(size_t i=0; i<t->simbolos.size();i++){
		if(t->simbolos[i].nombre==s.nombre){
			return false;
		}

	}
	t->simbolos.push_back(s);
	return true;
}
Simbolo buscar(TablaSimbolos *root,string nombre){
	for(size_t i = 0; i < root->simbolos.size(); i++){
		if(root->simbolos[i].nombre == nombre){
			return root->simbolos[i];
		}
	}
	if(root->root != NULL){ 
		return buscar(root->root, nombre);
	}
}
Simbolo buscarClase(TablaSimbolos *root, string nombre){
	if (root->root != NULL)
		return buscarClase(root->root, nombre);
	
	for(size_t i = 0; i < root->simbolos.size(); i++){
		if(root->simbolos[i].nombre == nombre){
			return root->simbolos[i];
		}
	}
}
TablaSimbolos* createScope(TablaSimbolos* root){
	TablaSimbolos* child = new TablaSimbolos(root);
	child->root = root;
	return child;
}
void deleteScope(TablaSimbolos* root){
	for(size_t i = 0; i < root->simbolos.size(); i++){
		ACTUAL_MEM-=root->simbolos[i].size;
	}
}