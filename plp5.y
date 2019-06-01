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
const int MAX_VAR = 16000;
const int MAX_TMP = 16384;
int ACTUAL_MEM = 0;
int TEMP_MEM = 16000;
int VAR_MEM = 0;
int ETIQ = 0;
int REL_DIR = 0;
string MAIN_LABEL;
int ASCO;

void deleteScope(TablaSimbolos* root);
TablaSimbolos* createScope(TablaSimbolos* root);

TablaSimbolos *ts = new TablaSimbolos(NULL,ACTUAL_MEM);
TablaTipos* tp = new TablaTipos(); 
TablaMetodos* tm = new TablaMetodos();

Simbolo buscarClase(TablaSimbolos *root, string nombre);
Simbolo buscar(TablaSimbolos *root, string nombre);
bool anyadir(TablaSimbolos *t,Simbolo s);
bool buscarAmbito(TablaSimbolos *root, string nombre);
string nuevoTemporal(int nlin, int ncol, const char *s);
string nuevaEtiq();
string getRelop(string op);
int getRelopIndex(string op);
int NuevoTipoArray(int dim, int tbase);
int getTbase(int tipo);
int getDt(int tipo);
int getTipoSimple(int tipo);
void printTtipos();
int buscarMetodo(string id);
void imprimir_simbolos(TablaSimbolos *root);

%}
%%
S : _class id llavei attributes dosp BDecl 	{
											$$.code = "mov #"+ to_string(REL_DIR) + " B\n";
											ASCO = REL_DIR;
											//cout << "---clase---" << endl;
											//imprimir_simbolos(ts);
											} methods dosp Metodos llaved   {
																				$$.code = $7.code;
																				$$.code += "jmp " + MAIN_LABEL + "\n\n";
																				$$.code += $6.code + $10.code;
																				$$.code += "halt\n";
																				cout << $$.code;
																		   		int tk = yylex();
																		   		if (tk != 0) yyerror("");
																			};

Metodos : _int _main pari pard { REL_DIR = 0; MAIN_LABEL = nuevaEtiq(); } Bloque 	{ 
																		
																		$$.code = MAIN_LABEL + " " + $6.code;
																	};

Tipo 	: _int {$$.tipo = ENTERO; }
	 	| _float {$$.tipo = REAL;};

Bloque : llavei {ts = new TablaSimbolos(ts,REL_DIR); /*cout << ts->temp_dir << endl;*/} BDecl {$$.tipo_metodo = $0.tipo_metodo;} SeqInstr llaved {
																	 		$$.code = $3.code + $5.code;
																	 		deleteScope(ts);
																			//imprimir_simbolos(ts);
																			ts = ts->root;
																			 //REL_DIR = ts->temp_dir;
																		};

BDecl : BDecl DVar {$$.code = "";}
	  | {$$.code = "";};

DVar : Tipo { $$.tipo = $1.tipo; } LIdent pyc {$$.code = "";};

LIdent : LIdent coma {$$.tipo = $0.tipo;} Variable { }
	   | { $$.tipo = $0.tipo; } Variable {};

Variable : id { $$.size = 1; $$.tipo = $0.tipo; if(buscarAmbito(ts,$1.lexema)) 
													msgError(ERRYADECL,$1.nlin,$1.ncol,$1.lexema); } V  {
																											Simbolo s;
																											s.nombre = $1.lexema;
																											s.index_tipo = $3.tipo;
																											s.dir = to_string(REL_DIR);
																											
																											REL_DIR += $3.size;
																											s.size = $3.size;
																											s.exists = false;
																											s.root = 0;
																											anyadir(ts,s);
																											//cout << buscar(ts,s.nombre).nombre;
																											//printTtipos();
																											if (REL_DIR >= MAX_VAR)
																												msgError(ERR_NOCABE,$1.nlin,$1.ncol,$1.lexema);       
																										};

V 	: cori nentero cord { $$.size = $0.size * atoi($2.lexema); $$.tipo = $0.tipo; } V 	{ 
																			$$.size = $5.size;
																			int dt = atoi($2.lexema);

																			if (dt <= 0)
																				msgError(ERRDIM,$2.nlin,$2.ncol,$2.lexema);

																			int index = NuevoTipoArray(dt, $5.tipo);
																			$$.tipo = index;

																		}
	| 	{
			$$.size = $0.size;
			$$.tipo = $0.tipo;
		};

SeqInstr : SeqInstr {$$.tipo_metodo = $0.tipo_metodo;} Instr 	{ $$.code = $1.code + $3.code; }
		 | { $$.code = " ";  };

Instr : pyc { $$.code = " ";  }
	  | Bloque { $$.code = $1.code; }
	  | Ref {if($1.tipo >= ARRAY){ msgError(ERRFALTAN, $1.nlin, $1.ncol, $1.lexema); }} asig Expr pyc { 	
															$$.code = $1.code + $4.code;

															int tipo_izq = getTipoSimple($1.tipo); //getTbase($1.tipo);
															int tipo_der = getTipoSimple($4.tipo); //getTbase($3.tipo);
															if(tipo_izq == ENTERO && tipo_der == REAL){
																$$.code += "mov " + $4.temp + " A\n";
																$$.code += "rtoi\n";
																$$.code += "mov A " + $4.temp + "\n";
															}
															else if(tipo_izq == REAL && tipo_der == ENTERO){
																$$.code += "mov " + $4.temp + " A\n";
																$$.code += "itor\n";
																$$.code += "mov A " + $4.temp + "\n";
															}
															if ($1.arrays == true) {
																$$.code += "mov " + $1.temp + " A\t; empieza arrays en Ref asig de: " + $1.aux_lexema + "\n";	
																$$.code += "muli #1 \n";
																/*if($1.dbase.find("@") != string::npos){
																	string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
																	$$.code += "mov " + $1.dbase + " @B+" + temp1 + "\n";
																	$$.code += "addi @B+" + temp1 + "\n";
																}
																else $$.code += "addi #"+ $1.dbase + "\n";*/
																$$.code += "addi #"+ $1.dbase + "\n";
																$$.code += "mov " + $4.temp + " @A\t; acaba arrays en Ref asig\n";
															}
															else {
																$$.code += "mov " + $4.temp + " " + $1.temp + "\t\t; " + $1.aux_lexema + " = " + $4.temp + "; \n";
															}
														}
	  | _print pari Expr pard pyc 						{
		  													$$.code = "\n;print\n" + $3.code;
															if (getTipoSimple($3.tipo) == ENTERO){
																$$.code += "wri " + $3.temp+ "\t; print valor entero de temporal\n";
															}
															else if(getTipoSimple($3.tipo) == REAL){																
																$$.code += "wrr " + $3.temp +"\t; print valor real de temporal\n";
															}
															$$.code += "wrl\n";
														}
	  | _scan pari Ref {if($3.tipo >= ARRAY){msgError(ERRFALTAN, $3.nlin, $3.ncol, $3.lexema);}} pard pyc {
															int tipo_tres = getTipoSimple($3.tipo);

															if ($3.arrays == true){
																$$.code = $3.code;
																string temporal = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
																$$.code += "\n;scan\n";
																$$.code += "mov " + $3.temp + " A\n";	
																$$.code += "muli #1 \n";
																/*if($3.dbase.find("@") != string::npos){
																	$$.code += "addi "+ $3.dbase + "\n";
																}
																else*/
																 $$.code += "addi #"+ $3.dbase + "\n";

																if (tipo_tres == ENTERO){
																	$$.code += "rdi @B+" + temporal +  "\t; guardar valor entero en temporal\n";
																}
																else if(tipo_tres == REAL){
																	$$.code += "rdr @B+" + temporal + "\t; guardar valor real en temporal\n";
																}

																$$.code += "mov @B+" + temporal + " @A\n";
															}
															else{
																$$.code = $3.code;
																if (tipo_tres == ENTERO){
																	$$.code += "rdi " + $3.temp +  "\t; guardar valor entero en temporal\n";
																}
																else if(tipo_tres == REAL){
																	$$.code += "rdr " + $3.temp + "\t; guardar valor real en temporal\n";
																}
															}
															$$.code += "\n";
	  													}
	  | _if pari Expr pard Instr 						{
															$$.code = $3.code;
															$$.code += "mov " + $3.temp + " A\n";
		  													string etiqueta = nuevaEtiq();
															$$.code += "jz " + etiqueta + " \t ; if \n";
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
															$$.code += "jmp " + etiqueta2 + "\n";
															$$.code += etiqueta1 + " ";
															$$.code += $7.code;
															$$.code += etiqueta2 + " ";
														}
	  | _while pari Expr pard Instr 					{
		  													string etiqueta1 = nuevaEtiq();
															string etiqueta2 = nuevaEtiq();
															$$.code = etiqueta1 + " " + $3.code;
															$$.code += "\t; WHILE\n";
															$$.code += "mov " + $3.temp + " A\n";
															$$.code += "jz " + etiqueta2 + "\t ; if else\n";
															$$.code += $5.code;
															$$.code += "jmp " + etiqueta1 + "\n";
															$$.code += "\t; ENDWHILE\n";
															$$.code += etiqueta2 + " ";
	  													};

Expr : 	Expr relop Esimple 							{
														string temp_final = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
														string op = $2.lexema;								
														$$.code = $1.code;
														$$.code += $3.code;
														if($1.tipo == ENTERO && $3.tipo == ENTERO){
															$$.code += "mov " + $1.temp + " A\n";
															$$.code += getRelop(op) + "i " + $3.temp + "\t; Expr relop Esimple\n";
														}
														else if($1.tipo == ENTERO && $3.tipo == REAL){
															string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
															$$.code += "mov " + $1.temp + " A\n";
															$$.code += "itor \n";
															$$.code += getRelop(op) + "r " + $3.temp + "\t; Expr relop Esimple\n";
														}
														else if($1.tipo == REAL && $3.tipo == ENTERO){
															string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
															$$.code += "mov " + $3.temp + " A\n";
															$$.code += "itor \n";
															$$.code += getRelop(op) + "r @B+" + temp1 + "\t; Expr relop Esimple\n";
														}	
														else { //reales
															$$.code += "mov " + $1.temp + " A\n";
															$$.code += getRelop(op) + "r " + $3.temp + "\t; Expr relop Esimple\n";
														}
														$$.code += "mov A @B+" + temp_final + "\t; guardar el resultado en temporal\n";
														$$.temp = "@B+" + temp_final;
													}
	 |  Esimple 									{ 
		 												$$.code = $1.code;
														$$.tipo = $1.tipo;
														$$.temp = $1.temp;	
													};

Esimple : Esimple addop Term  	{   
									string temp_final = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
									$$.temp = "@B+" + temp_final;
									string op = "";
									string aux_impr = $2.lexema;
									if(strcmp($2.lexema,"+")==0){
										op = "add";
									}
									else 
										op = "sub";

									int tipo_izq = getTipoSimple($1.tipo); //getTbase($1.tipo);
									int tipo_der = getTipoSimple($3.tipo); //getTbase($3.tipo);

									if(tipo_izq == ENTERO && tipo_der == ENTERO){
										//$$.code = "; ENTEROS \n";
										$$.code = $1.code;
										$$.tipo = ENTERO;
										$$.code += $3.code; //se mete en la A el resultado de Term
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += op + "i " + $3.temp + "\t; ENTERO "+ aux_impr + " ENTERO\n";
									}
									else if(tipo_izq == ENTERO && tipo_der == REAL){
										$$.code = $1.code;
										$$.tipo = REAL;
										string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += "itor \n";
										$$.code += "mov A @B+" + temp1 + " \n";
										$$.code += $3.code;
										$$.code += "mov @B+" + temp1 + " A\n";
										$$.code += op +"r " + $3.temp + "\t; ENTERO " + aux_impr + " REAL\n";
									}
									else if(tipo_izq == REAL && tipo_der == ENTERO){
										$$.code = $1.code;
										$$.tipo = REAL;
										$$.code += $3.code;
										string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
										$$.code += "mov " + $3.temp + " A\n";
										$$.code += "itor \n";
										$$.code += "mov A @B+" + temp1 + " \n";
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += op +"r @B+" + temp1 + "\t; REAL " + aux_impr + " REAL\n";
									}	
									else { //reales
										//$$.code = "; REALES \n";
										$$.code = $1.code;
										$$.tipo = REAL;
										$$.code += $3.code;
										$$.code += "mov " + $1.temp + " A\n";
										$$.code += op + "r " + $3.temp + "\t; REAL " + aux_impr + " REAL\n";
							  		}
									$$.code += "mov A @B+" + temp_final + "\t; guardar el resultado en temporal\n";
								}
		| Term 					{ 
									$$.code = $1.code;
									$$.tipo = $1.tipo;
									$$.temp = $1.temp;
			   					};

Term : Term mulop Factor   	{
								string temp_final = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
								$$.temp = "@B+" + temp_final;
								string op = "";
								string aux_impr = $2.lexema;
								if(strcmp($2.lexema,"*")==0){
									op = "mul";
								}
								else
									op = "div";

								int tipo_izq = getTipoSimple($1.tipo); //getTbase($1.tipo);
								int tipo_der = getTipoSimple($3.tipo); //getTbase($3.tipo);

								if(tipo_izq == ENTERO && tipo_der == ENTERO){
									//$$.code = "; ENTEROS \n";
									$$.code = $1.code;
									$$.tipo = ENTERO;
									$$.code += $3.code;
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += op + "i " + $3.temp + "\t; ENTERO " + aux_impr + " ENTERO\n";
								}
								else if(tipo_izq == ENTERO && tipo_der == REAL){
									$$.tipo = REAL;
									//$$.code = "; ENTERO Y REAL \n";
									$$.code = $1.code;
									string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += "itor \n";
									$$.code += "mov A @B+" + temp1 + "\n";
									$$.code += $3.code;
									$$.code += "mov @B+" + temp1 + " A\n";
									$$.code += op + "r " + $3.temp + "\t; ENTERO " + aux_impr + " REAL\n";
								}
								else if(tipo_izq == REAL && tipo_der == ENTERO){
									//$$.code = "; REAL y ENTERO \n";
									$$.code = $1.code;
									$$.tipo = REAL;
									$$.code += $3.code;
									string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
									$$.code += "mov " + $3.temp + " A\n";
									$$.code += "itor\n";
									$$.code += "mov A @B+" + temp1 + "\n";
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += op + "r @B+" + temp1 + "\t; Term : REAL " + aux_impr + " ENTERO\n";
								}	
								else { //reales
									//$$.code = "; REALES \n";
									$$.code = $1.code;
									$$.tipo = REAL;
									$$.code += $3.code;
									$$.code += "mov " + $1.temp + " A\n";
									$$.code += op + "r " + $3.temp + "\t; REAL " + aux_impr + " REAL\n";
								}

								$$.code += "mov A @B+" + temp_final +"\n";// "\t; guardar el resultado en temporal\n";
						   	}
	 | Factor  	{ 
					$$.tipo = $1.tipo;
					$$.code = $1.code;
					$$.temp = $1.temp;
			   	};

Factor :  Ref      		{
							if($1.tipo >= ARRAY){
								msgError(ERRFALTAN, $1.nlin, $1.ncol, $1.lexema);
							}

							if ($1.arrays == true){
								$$.code = $1.code;
								$$.code += "mov #0 " + $1.temp + "\t\t; guarda 0 y empieza en Factor recursivo arrays de " + $$.aux_lexema + "\n";
								string temp = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
								$$.code += "mov " + $1.temp + " @B+" + temp + "\t\t; guarda id " + $$.aux_lexema + "\n";
								$$.code += "muli #1 \n";
								/*if($1.dbase.find("@") != string::npos){
									string temp1 = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
								  	$$.code += "mov " + $1.dbase + " @B+" + temp1 + "\n";
									$$.code += "addi @B+" + temp1 + "\n";
								}
								else $$.code += "addi #"+ $1.dbase + "\n";*/
								$$.code += "addi #"+ $1.dbase + "\n";
								$$.code += "mov @A @B+" + temp + "\t;acaba array en Factor\n";
								$$.temp = "@B+" + temp;
							}
							else{
								string temp = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
								$$.code = "mov " + $1.temp + " @B+" + temp + "\t\t; guarda id " + $$.aux_lexema + "\n"; //Aquí.
								$$.temp = "@B+" + temp;
							}
						}
	   | nentero  		{
							string aux_lex = $1.lexema;
							string temp = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
							$$.tipo = ENTERO;
							$$.temp = "@B+" + temp;
							$$.code = "mov #" + aux_lex + " " + $$.temp + "\t\t; guarda entero " + aux_lex + "\n";
						}
	   | nreal    		{
							string aux_lex = $1.lexema;
							string temp = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
							$$.tipo = REAL;
							$$.temp = "@B+" + temp;
							$$.code = "mov $" + aux_lex + " " + $$.temp + "\t\t; guarda real " + aux_lex + "\n";
						}
	   | pari Expr pard { 
		   					$$.code = "; Factor -> pari Expr pard\n";
							$$.code += $2.code;
							string aux = $2.temp;
							$$.temp = aux;
							$$.tipo = $2.tipo;
						};

Ref : _this punto id  			{
									Simbolo s = buscarClase(ts, $3.lexema);
									if (s.exists) {
										s.exists = false;
										$$.tipo = s.index_tipo;
										$$.temp = s.dir;
										$$.dbase = s.dir;
										string aux = $3.lexema;
										$$.aux_lexema = "this." + aux;

										cout << "; Array " << $$.aux_lexema << " empieza en = " << s.dir << endl;

										if(s.index_tipo >= ARRAY){
											string temp = "@B+"+nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
											$$.code = "mov #0 "  + temp + "\t; guarda 0 y empieza recursivo arrays de 'Ref this' " + $$.aux_lexema + "\n";
											$$.temp = temp;
										}
									}
									else
										msgError(ERR_NO_ATRIB, $3.nlin, $3.ncol, $3.lexema);
								}
	| id 						{ 
									Simbolo s = buscar(ts, $1.lexema);
									
									if (s.exists){
										s.exists = false;
										$$.tipo = s.index_tipo;
										$$.temp = "@B+"+s.dir;
										int var = ASCO + atoi(s.dir.c_str());
										$$.dbase = to_string(var);
										string aux = $1.lexema;
										$$.aux_lexema = aux;

										if (s.root == 1){
											$$.temp = s.dir;
											$$.dbase = s.dir;
											$$.aux_lexema = "this." + aux;
											cout << "; Array " << $$.aux_lexema << " empieza en = " << s.dir << endl;
										}
										else{
											cout << "; Array " << $$.aux_lexema << " empieza en = @B+" << s.dir << endl;
										}

										

										if(s.index_tipo >= ARRAY){
											string temp = "@B+"+nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
											$$.code = "mov #0 "  + temp + "\t; guarda 0 y empieza recursivo arrays de en 'Ref id' " + $$.aux_lexema + "\n";
											$$.temp = temp;
										}
									}
									else
										msgError(ERRNODECL, $1.nlin, $1.ncol, $1.lexema);
								}
	| Ref cori { if ($1.tipo < ARRAY){msgError(ERRSOBRAN, $2.nlin, $2.ncol, $2.lexema);} } Esimple cord {
									if($4.tipo != ENTERO){
										msgError(ERR_EXP_ENT, $5.nlin, $5.ncol, $5.lexema);
									}

									string temporal = nuevoTemporal($1.nlin, $1.ncol, $1.lexema);
									$$.dbase = $1.dbase;
									$$.tipo = getTbase($1.tipo);
									$$.arrays = true;
									$$.temp = "@B+"+temporal;
									$$.code = $1.code;
									$$.code += $4.code;
									$$.code += "mov " + $1.temp + " A \t; hace recursivo de arrays en Ref\n";
									$$.code += "muli #" + to_string(getDt($1.tipo)) +"\n";
									$$.code += "addi " + $4.temp + "\t; fallo en este \n";
									$$.code += "mov A @B+" + temporal + " \n";

									$$.nlin = $5.nlin;
									$$.ncol = $5.ncol;
								};


//1. Guardaremos el método en la tabla de símbolos con la etiqueta para indicar el comienzo del código de la func.
//2. Guardaremos argumentos en la nueva ts local con la dir relativa.
Metodos : Met Metodos { $$.code = $1.code + $2.code;};
//Añadir la función a la tabla símbolos. Creamos un nuevo ámbito. Cerramos ámbito.

Met : Tipo id 	{	
					string aux_lex = $2.lexema;
					ts = new TablaSimbolos(ts,ACTUAL_MEM);
					REL_DIR = 0;
					Metodo m;
					m.tipo = $1.tipo;
					m.id = aux_lex;
					vector<Arg> aux_vector;
					//m.arg = aux_vector;
					tm->metodos.push_back(Metodo{$1.tipo, $2.lexema, aux_vector});
					string etiqueta = nuevaEtiq();
					tm->metodos[tm->metodos.size()-1].etiq = etiqueta;
				} pari Arg pard {$$.tipo_metodo = $1.tipo;} Bloque 	{ 
																		
																		string aux_lex = $2.lexema;
																		//cout << tm->metodos[tm->metodos.size()-1].id << endl;
																		$$.code = "; metodo: '" + tm->metodos[tm->metodos.size()-1].id + "'\n";
																		$$.code += tm->metodos[tm->metodos.size()-1].etiq + $8.code;
																		tm->metodos[tm->metodos.size()-1].dirs = REL_DIR + 1;
																		
																		$$.code += "; DIR USED = " + to_string(tm->metodos[tm->metodos.size()-1].dirs) + "\n";
																		ts = ts->root; //Cerramos ámbito de la función.

																		//poner siempre el return por defecto.
																		if (tm->metodos[tm->metodos.size()-1].tipo == ENTERO)
																			$$.code += "mov #0 @B-3\n";
																		else
																			$$.code += "mov $0.0 @B-3\n";

																		$$.code += "mov @B-2 A\n";
																		$$.code += "jmp @A\n\n";
																	}; 

Arg : { $$.code = ""; $$.tipo = $0.tipo; tm->metodos[tm->metodos.size()-1].args.push_back(Arg{-1,""}); }
	| { $$.tipo = $0.tipo; } CArg { $$.code = $2.code; };

CArg : Tipo id 	{	
					string aux_lex = $2.lexema;
					Simbolo s; 
					s.nombre = aux_lex; 
					s.index_tipo = $1.tipo;
					s.dir = to_string(REL_DIR++); //Primer argumento será pos 0 relativa de B
					VAR_MEM += 1; 
					s.size = 1; 
					anyadir(ts,s);
					tm->metodos[tm->metodos.size()-1].args.push_back(Arg{$1.tipo,aux_lex});
				} CArgp { $$.code = ""; };

CArgp : coma Tipo id 	{
							string aux_lex = $3.lexema;
							Simbolo s; 
							s.nombre = $3.lexema; 
							s.index_tipo = $2.tipo;
							s.dir = to_string(REL_DIR++); 
							VAR_MEM += 1;
							s.size = 1; 
							anyadir(ts,s);
							tm->metodos[tm->metodos.size()-1].args.push_back(Arg{$2.tipo,aux_lex});
						} CArgp {$$.code = "";}
	  | { $$.code = ""; tm->metodos[tm->metodos.size()-1].args.push_back(Arg{-1,""}); };

Instr : _return Expr pyc {
							if(MAIN_LABEL!="") msgError(ERRFMAIN, $1.nlin, $1.ncol, $1.lexema);
							//cout << "Codigo del método en return = " << $0.tipo_metodo << endl;
							$$.code = $2.code;
						 	$$.code += "; Secuencia de retorno\n";
							if($0.tipo_metodo == ENTERO && $2.tipo == REAL){
								$$.code += "mov " + $2.temp + " A\n";
								$$.code += "rtoi\n";
								$$.code += "mov A " + $2.temp + "\n";
							}
							else if($0.tipo_metodo == REAL && $2.tipo == ENTERO){
								$$.code += "mov " + $2.temp + " A\n";
								$$.code += "itor\n";
								$$.code += "mov A " + $2.temp + "\n";
							}
							$$.code += "mov " + $2.temp + " @B-3\n";
							$$.code += "mov @B-2 A\n";
							$$.code += "jmp @A\n";
						 };

Factor : id pari 	{ 
						int index_func = buscarMetodo($1.lexema);
						$$.indice_func = index_func;
						if($$.indice_func == -1){msgError(ERRNODECL, $1.nlin, $1.ncol, $1.lexema);} 
						
						tm->metodos[index_func].mlin = $1.nlin;
						tm->metodos[index_func].mcol = $1.ncol;
						$$.temp = to_string(REL_DIR + 3 + tm->metodos[index_func].args.size() - 1);

						cout << ";Guarda desde: " << REL_DIR << endl;
						ACTUAL_MEM = REL_DIR + 3;
						cout << ";Actual empieza: " << ACTUAL_MEM << endl;
						REL_DIR = REL_DIR + 3 + tm->metodos[index_func].args.size() - 1;
						cout << ";Hasta: " << REL_DIR << endl;

					} Par pard { //el error
							int index_func = buscarMetodo($1.lexema);
							string prueba =  tm->metodos[index_func].etiq;
							$$.code = $4.code;
							$$.code += "; Secuencia de llamada\n";
							int op = ACTUAL_MEM;
							int op2 = ACTUAL_MEM + 1;
							$$.code += "mov B @B+" + to_string(op) +"\n"; 
							$$.code += "mov B A\n"; //B+0... B+1(Valor), B+2(Direccion), B+3(b atnerior), B+4(Primer parámetro)						
							$$.code += "addi #" + to_string(op2) + "\n"; //valor a calcular
							$$.code += "mov A B\n"; // Nueva B apunta al primer nuevo arg.
							string etiq = nuevaEtiq();
							$$.code += "mvetq " + etiq + " @B-2\n";
							$$.code += "jmp " + prueba + "\n";
							$$.code += etiq + " mov @B-1 B\n";
							$$.temp = "@B+" + to_string(ACTUAL_MEM-2);
							$$.tipo = tm->metodos[index_func].tipo;
						  }; 

Par : 			{
					$$.code = "";
					$$.temp = $0.temp;
					int tipo_arg = tm->metodos[$0.indice_func].args[$0.indice_args].tipo;
					const char *id = tm->metodos[$0.indice_func].id.c_str();
					if (tipo_arg != -1){msgError(ERRFFALTAN, tm->metodos[$0.indice_func].mlin, tm->metodos[$0.indice_func].mcol, id); }
				}
	| Expr 		{ 
					int pos_args;
					pos_args = ACTUAL_MEM + $0.indice_args+1; //1 2
					//cout << ";--> pos_args = " << pos_args << endl;
					int tipo_arg = tm->metodos[$0.indice_func].args[$0.indice_args].tipo;

					const char *id = tm->metodos[$0.indice_func].id.c_str();

					if(tipo_arg == -1){msgError(ERRFSOBRAN,  tm->metodos[$0.indice_func].mlin, tm->metodos[$0.indice_func].mcol,id); }
					int tipo_expr = getTipoSimple($1.tipo);

					if (tipo_arg == ENTERO && tipo_expr == REAL){
						$$.code = $1.code;
						$$.code += "mov " + $1.temp + " A\n";
						$$.code += "rtoi \n";
						$$.code += "mov A @B+" + to_string(pos_args) + "\t; asigna un param Par | entero != real\n";
					} 
					else if(tipo_arg == REAL && tipo_expr == ENTERO){
						$$.code = $1.code;
						$$.code += "mov " + $1.temp + " A\n";
						$$.code += "itor \n";
						$$.code += "mov A @B+" + to_string(pos_args) + "\t; asigna un param Par | real != entero\n";
					}
					else{
						$$.code = $1.code;
						$$.code += "mov " + $1.temp + " @B+" + to_string(pos_args) + "\t; asigna un param Par\n";
					}

					$$.indice_args = $0.indice_args + 1;
					$$.indice_func = $0.indice_func;

				} CPar 	{
							$$.code = $2.code + $3.code;
							$$.temp = $0.temp;
						};

CPar : 	{
			$$.code = "";
			int tipo_arg = tm->metodos[$0.indice_func].args[$0.indice_args].tipo;
			const char *id = tm->metodos[$0.indice_func].id.c_str();
			if (tipo_arg != -1){ msgError(ERRFFALTAN,  tm->metodos[$0.indice_func].mlin, tm->metodos[$0.indice_func].mcol, id); }
		}
	 	| coma Expr 	{ 

			 				int pos_args=0;
							pos_args = ACTUAL_MEM + $0.indice_args+1; //1 2
			 				int tipo_arg = tm->metodos[$0.indice_func].args[$0.indice_args].tipo; 
							const char *id = tm->metodos[$0.indice_func].id.c_str();
							if(tipo_arg == -1){
								msgError(ERRFSOBRAN,  tm->metodos[$0.indice_func].mlin, tm->metodos[$0.indice_func].mcol, id); 
							}
							int tipo_expr = getTipoSimple($2.tipo);

							if (tipo_arg == ENTERO && tipo_expr == REAL) {
								$$.code = $2.code;
								$$.code += "mov " + $2.temp + " A\n";
								$$.code += "rtoi \n";
								$$.code += "mov A @B+" + to_string(pos_args) + "\t; asigna un param CPar | entero != real\n";
							} 
							else if(tipo_arg == REAL && tipo_expr == ENTERO) {
								$$.code = $2.code;
								$$.code += "mov " + $2.temp + " A\n";
								$$.code += "itor \n";
								$$.code += "mov A @B+" + to_string(pos_args) + "\t; asigna un param CPar | real != entero\n";
							}
							else {
								$$.code = $2.code;
								$$.code += "mov " + $2.temp + " @B+" + to_string(pos_args) + "\t; asigna un param CPar\n";
							}
							$$.indice_args = $0.indice_args + 1;
							$$.indice_func = $0.indice_func;
						//	cout << pos_args << " " << REL_DIR << " " <<$0.indice_args;
						} CPar	{ 
									$$.code = $3.code + $4.code;
								};

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
			 case ERRFFALTAN: fprintf(stderr,"faltan parámetros en la llamada a la función '%s'",s);
			 	break;
			 case ERRFSOBRAN: fprintf(stderr,"sobran parámetros en la llamada a la función '%s'",s);
			 	break;
			 case ERRFMAIN: fprintf(stderr,"no se puede utilizar 'return' dentro de 'main'");
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
string nuevoTemporal(int nlin, int ncol, const char *s){
	REL_DIR++; // int 
	string aux_s = s;
	//cout << "Error en: " << s << " con: " <<  << endl;
	if ((REL_DIR + 1) >= MAX_TMP)
		msgError(ERR_MAXTMP, nlin, ncol, s);
	return to_string(REL_DIR);
}
string nuevaEtiq(){
	ETIQ++;
	//cout << "index etiqueta = " << ETIQ << endl;
	return "L"+to_string(ETIQ);
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
/*****TABLA TIPOS******/
int NuevoTipoArray(int dim, int tbase){
	tp->tipos.push_back(Tipo{tbase,dim,ARRAY});
	return tp->tipos.size()-1;
}
int buscarMetodo(string id){
	for(size_t i=0;i<tm->metodos.size();i++){
		if(!tm->metodos[i].id.compare(id)){
			return i;
		}
	}
	return -1;
}

int getTbase(int tipo){ return tp->tipos[tipo].tbase; } //$3.tipo ==> ENTERO = 1 --> REAL
int getArg(int tipo){ return tp->tipos[tipo].tipo;}
int getTipoSimple(int tipo){
	if (tipo == ENTERO || tipo == REAL){
		return tipo;
	}

	int i = tipo;

	while(i < tp->tipos.size()){
		if (tp->tipos[i].tipo == 0 || tp->tipos[i].tipo == 1){
			return tp->tipos[i].tipo;
		}

		i = tp->tipos[i].tbase;
	}
	
	/*for (int i = tipo; i < tp->tipos.size(); --i){
		if (tp->tipos[i].tipo == 0 || tp->tipos[i].tipo == 1){
			return tp->tipos[i].tipo;
		}
	}*/
}
void printTtipos(){
	cout << "Tipo Dim Tbase" << endl;
	for (int i = 0; i < tp->tipos.size(); ++i){
		cout << "- " << i <<" : " <<  to_string(tp->tipos[i].tipo) + " " + to_string(tp->tipos[i].dt) + " " + to_string(tp->tipos[i].tbase) << endl;
	}
	cout << endl;
}
//int getTipo(int tipo){ return tp->tipos[tipo].tipo; }
int getDt(int tipo){ return tp->tipos[tipo].dt; }
/*****TABLA SIMBOLOS*********/
bool buscarAmbito(TablaSimbolos *root,string nombre){
  for(size_t i=0;i<root->simbolos.size();i++){
		if(!root->simbolos[i].nombre.compare(nombre)){
			return true;
		}
	}
	return false;
}
bool anyadir(TablaSimbolos *t,Simbolo s){
	for(size_t i=0; i<t->simbolos.size();i++){
		if(!t->simbolos[i].nombre.compare(s.nombre)){
			return false;
		}
	}
	t->simbolos.push_back(s);
	return true;

}
void imprimir_simbolos(TablaSimbolos *root){
	cout << "---------------------------" << endl;
	 for(size_t i = 0; i < root->simbolos.size(); i++){
		cout << root->simbolos[i].nombre << " " << root->simbolos[i].index_tipo << endl; 
	  }
}
Simbolo buscar(TablaSimbolos *root,string nombre){
   for(size_t i = 0; i < root->simbolos.size(); i++){
	  if(!root->simbolos[i].nombre.compare(nombre)){
		  root->simbolos[i].exists = true;
		  if(root->root == NULL){
			  root->simbolos[i].root = 1;
		  }
		  return root->simbolos[i];
	  }
   }
   if(root->root != NULL){ 
	  return buscar(root->root, nombre);
   }
}
Simbolo asignar_tipo(TablaSimbolos *root,string nombre,int tipo){
   for(size_t i = 0; i < root->simbolos.size(); i++){
	  if(!root->simbolos[i].nombre.compare(nombre)){
		  root->simbolos[i].exists = true;
		  root->simbolos[i].index_tipo = tipo;
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
	  if(!root->simbolos[i].nombre.compare(nombre)){
		 root->simbolos[i].exists = true;
		 return root->simbolos[i];
	  }
   }
}
TablaSimbolos* createScope(TablaSimbolos* root){
	TablaSimbolos* child = new TablaSimbolos(root,ACTUAL_MEM);
	child->root = root;
	return child;
}
void deleteScope(TablaSimbolos* root){
	for(size_t i = 0; i < root->simbolos.size(); i++){
		REL_DIR-=root->simbolos[i].size;
	}
}