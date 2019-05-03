#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

typedef struct {
   char *lexema;
   string code, ftemp; //ftemp = dirección del valor.
   int nlin, ncol;
   int tipo;
   string valor;
   int size, array;
} MITIPO;

struct Simbolo {
    string nombre;
    int tipo;
    int dir;
    int size;
    string nomtrad;
};
struct TablaSimbolos {
    TablaSimbolos *root;
    std::vector<Simbolo> simbolos;
    TablaSimbolos(TablaSimbolos *t){root=t;}
};

#define YYSTYPE MITIPO

#define ERRLEXICO    1
#define ERRSINT      2
#define ERREOF       3
#define ERRLEXEOF    4

#define ERRYADECL       10
#define ERRNODECL       11
#define ERRDIM          12
#define ERRFALTAN       13
#define ERRSOBRAN       14
#define ERR_EXP_ENT     15
#define ERR_NO_ATRIB    16

#define ERR_NOCABE     100
#define ERR_MAXVAR     101
#define ERR_MAXTIPOS   102
#define ERR_MAXTMP     103

void msgError(int nerror, int nlin, int ncol, const char *s);
bool equalsIgnoreCase(string s1, char* lexema);