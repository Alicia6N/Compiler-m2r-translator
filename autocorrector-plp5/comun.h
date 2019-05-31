#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

const int ENTERO=0;
const int REAL=1;
const int ARRAY=2;

//temp: var. temporal donde se ha guardado un Factor o resultado de operacion
typedef struct {
   char *lexema;
   string code, temp, aux_lexema;
   int nlin, ncol;
   int tipo;
   int size;
   string dbase;
   bool arrays;
   
   int indice_func;
   int indice_args;
} MITIPO;

struct Simbolo {
    string nombre;
    int index_tipo;
    string dir;
    string etiq;
    int size;
    bool exists;
    bool aux;
    string nomtrad;
    int root;
};
struct TablaSimbolos {
    TablaSimbolos *root;
    std::vector<Simbolo> simbolos;
    int temp_dir;
    TablaSimbolos(TablaSimbolos *t,int temp_value){root=t;temp_dir = temp_value;}
};
struct Tipo {
    int tbase;
    int dt; //dimension y tamanyo
    int tipo;
};
struct TablaTipos {
    std::vector<Tipo> tipos;
    TablaTipos(){
        tipos.push_back(Tipo{ENTERO,1,ENTERO});
        tipos.push_back(Tipo{REAL,1,REAL});
    }
};
struct Arg {
    int tipo;
    string id;
};
struct Metodo {
    int tipo;
    string id;
    vector<Arg> args;
    int dirs;
    string etiq;
    int mlin, mcol;
};
struct TablaMetodos {
    std::vector<Metodo> metodos;
    TablaMetodos(){
    }
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
#define ERRFFALTAN     104
#define ERRFSOBRAN     105

void msgError(int nerror, int nlin, int ncol, const char *s);
bool equalsIgnoreCase(string s1, char* lexema);