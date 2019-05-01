
/*

  Intérprete de 'm2r'

  (c) Francisco Moreno Seco (fmorenoseco@gmail.com)
      Dept. de Lenguajes y Sistemas Informáticos
      Universidad de Alicante
  
   El lenguaje 'm2r' fue diseñado por Mikel L. Forcada y
  Francisco Moreno para la asignatura de Compiladores II, a
  finales de los años 90.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define MAXCOD            10000
#define MAXMEM           16384

#define MOV     0
#define ADDI    1
#define ADDR    2
#define SUBI    3
#define SUBR    4
#define MULI    5
#define MULR    6
#define DIVI    7
#define DIVR    8
#define ANDI    9
#define ANDR   10
#define ORI    11
#define ORR    12
#define NOTI   13
#define NOTR   14
#define ITOR   15
#define RTOI   16
#define HALT   17
#define WRI    18
#define WRR    19
#define WRC    20
#define WRL    21
#define RDI    22
#define RDR    23
#define RDC    24
#define JMP    25
#define EQLI   26
#define EQLR   27
#define NEQI   28
#define NEQR   29
#define GTRI   30
#define GTRR   31
#define GEQI   32
#define GEQR   33
#define LSSI   34
#define LSSR   35
#define LEQI   36
#define LEQR   37
#define JZ     38
#define JNZ    39
#define MODI   40
#define MVETQ 41

typedef struct {
    char tipo;
    int num;
    double numr;
} Argumento; /* puede ser 'fuente', 'destino' o 'posprog' */

/* tipos de argumentos */
#define A_N        0        /* n       */
#define A_DIRA     1        /* @A      */
#define A_DIRB_N   2        /* @B+n    */
#define A_A        3        /* A       */
#define A_B        4        /* B       */
#define A__N       5        /* #n      */
#define A_ETIQ     6        /* etiqueta (temporal) */
#define A__R       7        /* $r      */

typedef struct instr {
   int codinstr;
   Argumento fuente;     /* a veces es 'posprog' */
   Argumento destino;
} instr;

#define NUMINSTR 42

char *pr[NUMINSTR] = {
  "mov", "addi", "addr", "subi", "subr", "muli", "mulr", "divi", "divr",
  "andi", "andr", "ori", "orr", "noti", "notr", "itor", "rtoi",
  "halt", "wri", "wrr", "wrc", "wrl", "rdi", "rdr", "rdc", 
  "jmp", "eqli", "eqlr", "neqi", "neqr", "gtri", "gtrr",
  "geqi" , "geqr", "lssi", "lssr", "leqi", "leqr",
  "jz",  "jnz", "modi", "mvetq"
};

char nargs[NUMINSTR] = {
   2,   1,   1,   1,   1,  1, 1, 1, 1,
   1,   1,   1,   1,   0,  0, 0, 0,
   0,   1,   1,  1,  0,     1, 1, 1,
   1,     1,   1,   1,   1,   1,   1,
   1,   1,    1,   1,  1, 1,
   1,     1, 1, 2
};


static instr codigo[MAXCOD];
static int  ninst;
static char *codfuente[MAXCOD]; /* para debug */
static int breakpoint[MAXCOD];  /* obvio */

typedef struct {
        int tipo;      /* 0 entero, 1 real */
        int valint;
        double valreal;
 } MEMO;

static MEMO memoria[MAXMEM];
static double   Acumulador, Base;
static int  tipoAcum = 0, tipoBase = 0;
static int   pc;

/*----------------------------------------------------------------------*/
/* PARA DEPURAR */
/*----------------------------------------------------------------------*/
static long npasos = 0;
static int debug = 0;
/*----------------------------------------------------------------------*/
void PrintfArgumento(Argumento a)
{
    switch (a.tipo)
    {
        case A_N: printf("%d ",a.num);
                break;
        case A_DIRA: printf("@A");
                break;
        case A_DIRB_N: printf("@B+%d ",a.num);
                break;
        case A_A: printf("A ");
                break;
        case A_B: printf("B ");
                break;
        case A__N: printf("#%d ",a.num);
                break;
        case A__R: printf("$%g ",a.numr);
                break;
    }
}
/*----------------------------------------------------------------------*/
void PrintfInstruccion(instr i)
{
    int na;

    printf("%s ",pr[i.codinstr-MOV]);
    na = nargs[i.codinstr-MOV];
    if (na == 2)
    {
        PrintfArgumento(i.fuente);
        PrintfArgumento(i.destino);
    }
    else if (na == 1)
        PrintfArgumento(i.fuente);

    printf("\n");
}
/*----------------------------------------------------------------------*/

static int limpia_bufEntrada(int c)
{
   while (c == ' ' || c == '\t')
     c = getchar();
   if (c != '\n')
      ungetc(c,stdin);
}

static int lee_valor(void)
{
    int l;
    int negativo;
    int c;
    
    negativo = 0;
    c = getchar();
    if (c == '-')
    {
        negativo = 1;
    	c = getchar();
    }
    l = 0;
    while ((c>='0') && (c<='9'))
    {
    	l = 10*l+c-'0';
    	c = getchar();
    }
    if (negativo)
    	l = -l;
   
    limpia_bufEntrada(c);
    return(l);
}
static double lee_valorReal(void)
{
    double l;
    int negativo;
    int c;
    
    negativo = 0;
    c = getchar();
    if (c == '-')
    {
        negativo = 1;
    	c = getchar();
    }
    l = 0.0;
    while ((c>='0') && (c<='9'))
    {
    	l = 10*l+c-'0';
    	c = getchar();
    }
    if (c == '.')
    {
       int dec;
    
       c = getchar();
       dec = 0;
       while ((c>='0') && (c<='9'))
       {
    	l = 10*l+c-'0';
    	c = getchar();
    	dec++;
       }
       while (dec)
       {
          l = l / 10.0;
          dec--;
       }
    }
    
    
    if (negativo)
    	l = -l;
   
    limpia_bufEntrada(c);
    return(l);
}
/*----------------------------------------------------------------------*/
void errorFatal(char *s,int i,int j)
{
    printf(s,i,j);
    exit(1);
}
/*----------------------------------------------------------------------*/
void ComprobarAccesoMem(int dir)
{
    if ((dir<0) || (dir>=MAXMEM))
        errorFatal("\nERROR(m2r): Acceso incorrecto a memoria en la instrucción %d (dir %d)\n",
            pc,dir);
}
/*----------------------------------------------------------------------*/
void ComprobarLecturaMem(int dir)
{
    if (memoria[dir].tipo == -1)
        errorFatal("\nERROR(m2r) al leer un valor de la posicion de memoria %d sin haberlo\ninicializado, en la instrucción %d\n",
          dir,pc);
}
/*----------------------------------------------------------------------*/
int ValorPosProg(Argumento posprog)
{
     switch (posprog.tipo)
     {
         case A_N:
                 return(posprog.num);
                 break;
         case A_DIRA:
                 return(Acumulador);
                 break;
         case A_DIRB_N:
                 return((int)Base + posprog.num);
                 break;
     }
}
/*----------------------------------------------------------------------*/
int ValorArgumento(Argumento fuente,int *vifuente,double *vrfuente)
{
     int posmem;

     switch (fuente.tipo)
     {
         case A_N:
                 ComprobarAccesoMem(fuente.num);
                 posmem = fuente.num;
                 ComprobarLecturaMem(posmem);
                 *vifuente = memoria[posmem].valint;
                 *vrfuente = memoria[posmem].valreal;
                 return(memoria[posmem].tipo);
                 break;
         case A_DIRA:
                 ComprobarAccesoMem(Acumulador);
                 posmem = (int)Acumulador;
                 ComprobarLecturaMem(posmem);
                 *vifuente = memoria[posmem].valint;
                 *vrfuente = memoria[posmem].valreal;
                 return(memoria[posmem].tipo);
                 break;
         case A_DIRB_N:
                 ComprobarAccesoMem(Base + fuente.num);
                 posmem = (int)Base + fuente.num;
                 ComprobarLecturaMem(posmem);
                 *vifuente = memoria[posmem].valint;
                 *vrfuente = memoria[posmem].valreal;
                 return(memoria[posmem].tipo);
                 break;
         case A_A:
                 if (tipoAcum)
                 {
                   *vrfuente = Acumulador;
                   *vifuente = 0;
                 }
                 else
                 {
                   *vrfuente = 0.0;
                   *vifuente = (int)Acumulador;
                 }
                 return(tipoAcum);
                 break;
         case A_B:
                 if (tipoBase)
                 {
                   *vrfuente = Base;
                   *vifuente = 0;
                 }
                 else
                 {
                   *vrfuente = 0.0;
                   *vifuente = (int)Base;
                 }
                 return(tipoBase);
                 break;
         case A__N:
                 *vrfuente = 0.0;
                 *vifuente = fuente.num;
                 return(0);
                 break;
         case A__R:
                 *vrfuente = fuente.numr;
                 *vifuente = 0;
                 return(1);
                 break;
     }
}
/*----------------------------------------------------------------------*/
void AsignarDestino(Argumento destino,int tipo,int valint,double valreal)
{
     int posmem;

     switch (destino.tipo)
     {
         case A_N:
                 ComprobarAccesoMem(destino.num);
                 posmem = destino.num;
                 memoria[posmem].tipo = tipo;
                 memoria[posmem].valint = valint;
                 memoria[posmem].valreal = valreal;
                 break;
         case A_DIRA:
                 ComprobarAccesoMem(Acumulador);
                 posmem = (int)Acumulador;
                 memoria[posmem].tipo = tipo;
                 memoria[posmem].valint = valint;
                 memoria[posmem].valreal = valreal;
                 break;
         case A_DIRB_N:
                 ComprobarAccesoMem(Base + destino.num);
                 posmem = (int)Base + destino.num;
                 memoria[posmem].tipo = tipo;
                 memoria[posmem].valint = valint;
                 memoria[posmem].valreal = valreal;
                 break;
         case A_A:
                 Acumulador = tipo ? valreal : valint;
                 tipoAcum = tipo;
                 break;
         case A_B:
                 Base = tipo ? valreal : valint;
                 tipoBase = tipo;
                 break;
     }
}
/*----------------------------------------------------------------------*/
void SaltoPosProg(int direccion)
{
    if ((direccion <0) || (direccion > MAXCOD))
        errorFatal("\nERROR(m2r): Puntero al codigo incorrecto en la instrucción %d (%d)\n",
            pc,direccion+1);

    pc = direccion;
}
/*----------------------------------------------------------------------*/
void errorTipos(int tipo,int arg,int inst,int pc)
{
   printf("ERROR(m2r) en instruccion %d: el %s operando de '%s' debe ser %s.\n",
          pc, (arg==1? "primer" : "segundo") , pr[inst],
              (tipo? "real" : "entero"));
   exit(1);
}

/*----------------------------------------------------------------------*/
static void ChequearTipos(int t1,int t2,int inst,int pc)
{
   switch (inst)
   {
      case ADDI:
      case SUBI:
      case MULI:
      case DIVI:
      case MODI:
      case ANDI:
      case ORI:
      case EQLI:
      case NEQI:
      case GTRI:
      case GEQI:
      case LSSI:
      case LEQI:
                if (t1)
                    errorTipos(0,1,inst,pc);
                if (t2)
                    errorTipos(0,2,inst,pc);
                break;
      case ADDR:
      case SUBR:
      case MULR:
      case DIVR:
      case ANDR:
      case ORR:
      case EQLR:
      case NEQR:
      case GTRR:
      case GEQR:
      case LSSR:
      case LEQR:
                if (!t1)
                    errorTipos(1,1,inst,pc);
                if (!t2)
                    errorTipos(1,2,inst,pc);
                break;
      case WRI:
      case WRC:
      case RDI:
      case RDR:
      case RDC:
      case ITOR:
      case NOTI:
                if (t1)
                    errorTipos(0,1,inst,pc);
                break;
      case WRR:
      case RTOI:
      case NOTR:
                if (!t1)
                    errorTipos(1,1,inst,pc);
                break;
   }
}

/*----------------------------------------------------------------------*/
#define miabs(i)  ( (i)<0 ? (-(i)) : (i) )

#define EPSILONCOMP  0.000001                 
int IgualReales(double d1,double d2)
{
   double resta;
   
   resta = d1-d2;
   if (miabs(resta) < EPSILONCOMP)
       return 1;
   else
       return 0;
}
/*----------------------------------------------------------------------*/
#define MDB_STEP 1
#define MDB_CONT 2
int MODODEB = MDB_STEP;

int lee_valorDBG(int *oc)
{
    int l;
    int c;
    
    c = *oc;
    l = 0;
    while ((c>='0') && (c<='9'))
    {
    	l = 10*l+c-'0';
	c = getchar();
    }
    *oc = c;
    return(l);
}

/*-----------------------------------------------------------*/

#define EsLineaBP(i)  (breakpoint[i])

void Listar(int desde,int hasta,int marcar)
{
   int l,j,k;
   
   if (desde > hasta)
      return;
              
   j = desde ;
   if (j<0) j = 0;
   
   k = hasta ;
   if (k>=ninst) k = ninst-1;
                    
   for (l=j;l<=k;l++)
   {
     if (EsLineaBP(l))
        printf("\tb\t%d",l+1);
     else
        printf("\t\t%d",l+1);
     if (l == marcar)
         printf("> %s",codfuente[l]);
     else
         printf("  %s",codfuente[l]);
   }
}

static void printfDir(int dir)
{
  printf("\t direccion: %d  -> ",dir);
  if ((dir<0) || (dir>=MAXMEM))
     printf(" direccion fuera de rango [%d-%d]\n",0,MAXMEM-1);
  else if (memoria[dir].tipo == -1)
     printf(" (vacia)\n");
  else
  {
     if (memoria[dir].tipo == 0) printf("[entero] %d\n",memoria[dir].valint);
     else                        printf("[real] %8.3f\n",memoria[dir].valreal);
  }
}

static int depurar(void)
{
  int nc,i;
  int desde,hasta,lindeb;
  static int c = 's';

  if (MODODEB == MDB_CONT)
    if (!breakpoint[pc]) return 0;

  printf("\n");
  Listar(pc,pc,pc);
  lindeb = pc;
  
  do
  {
     printf("m2r[debug]> ");
     nc = getchar();
     if (nc != '\n') {
       c = nc;
       if (c == 'q' || c == '?' || c == 's' || c == 'c' || c == 'r')
	     while (getchar() != '\n') ;
     }
     else if (c != 's' && c != 'c')
     {
       c = 's';
       continue;
     }
  
     switch(c)
     {
       case 'q': return 2;
                 break;
       case 'l': if (nc != '\n')
       		   {
       		      int oc;
       		      do
       		      {
			oc = getchar();
       		      } while (oc == ' ');
       		      if (oc == '\n')
       		      {
       		         desde = pc-2;
       		         hasta = pc+2;
       		      }
       		      else if (oc >= '0' && oc <= '9')
       		      {
       		          desde = lee_valorDBG(&oc);
			  while (oc == ' ') oc = getchar();
       		          if (oc == '\n')
       		          {
       		            /* listar alrededor de 'desde' */
       		            hasta = desde + 2;
       		            desde = desde - 2;
       		          }
       		          else if (oc >= '0' && oc <= '9')
       		          {
       		            hasta = lee_valorDBG(&oc);
			    while (oc != '\n') oc = getchar();
                          }
                          else
                          {
                             printf("Error: '%c' incorrecto\n",oc);
                             if (oc != '\n') while (getchar() != '\n') ;
                             break;
                          }
       		      }
       		      else
       		      {
       		          printf("Error: '%c' incorrecto\n",oc);
                          if (oc != '\n') while (getchar() != '\n') ;
       		          break;
       		      }
       		   }
       
                 Listar(desde-1, hasta-1,lindeb);
                 break;
       case 's': MODODEB = MDB_STEP;
                 return 0;
                 break;
       case 'c': MODODEB = MDB_CONT;
                 return 0;
                 break;
       case 'b': if (nc != '\n')
       		   {
       		      int oc;
       		      do
       		      {
			oc = getchar();
       		      } while (oc == ' ');
       		      if (oc >= '0' && oc <= '9')
       		      {
       		          desde = lee_valorDBG(&oc);
			  while (oc == ' ') oc = getchar();
       		          if (oc == '\n')
       		          {
       		             if (desde > 0 && desde <= ninst)
       		                breakpoint[desde-1] = 
       		                  (breakpoint[desde-1] ? 0 : 1);
       		             
       		          }
       		          else 
       	                  {
       		            printf("Error: '%c' incorrecto\n",oc);
                            if (oc != '\n') while (getchar() != '\n') ;
       		            break;
       		          }
       		      }
       		      else
       		      {
       		          printf("Error: '%c' incorrecto\n",oc);
                          if (oc != '\n') while (getchar() != '\n') ;
       		          break;
       		      }
       		   }
                 break;
           case 'r': 
                 c = 's';
                 return 1;
                 break;
           case 'p':
                 {
                    int nc;
                    
                    do
		      nc = getchar();
                    while (nc == ' ');
                    if (nc >= '0' && nc <= '9')
                    {
                       char buf[500];
                       int i = 0;
                       int dir;
                     
                       do 
                       {
                          buf[i] = nc;
                          i++;
                          nc = getchar();                       
                       } while (nc >= '0' && nc <= '9');
                       
                       buf[i] = '\0';
                       dir = atoi(buf);

                       printfDir(dir);
                       if (nc != '\n') while (getchar() != '\n') ;
                    }
                    else if (nc == 'A' || nc == 'a')
                    {
                       if (tipoAcum)
                          printf("\tAcumulador: [real] %8.3f\n",Acumulador);
                       else
                          printf("\tAcumulador: [entero] %d\n",(int)Acumulador);
                       while (getchar() != '\n') ;
                    }
                    else if (nc == 'B' || nc == 'b')
                    {
                       if (tipoBase)
                          printf("\tReg. Base: [real] %8.3f\n",Base);
                       else
                          printf("\tReg. Base: [entero] %d\n",(int)Base);
                       while (getchar() != '\n') ;
                    }
                    else
                    {
                       printf("Error: '%c' incorrecto\n",nc);
                       if (nc != '\n') while (getchar() != '\n') ;
                    }
                 }
                 break;      
       default: printf("? - ayuda\nq - salir\ns - step\nl - listar linea actual\n"
                        "l <num> - listar linea <num>\nl <num1> <num2> - listar desde <num1> hasta <num2>\n"
                        "c - ejecucion continua hasta breakpoint\nb <num> - poner breakpoint en linea <num>\n"
                        "r - empezar desde el principio\n"
                        "p <direccion> - imprime el contenido de esa direccion\n"
                        "p A - imprime el contenido del registro A\n"
                        "p B - imprime el contenido del registro B\n");
                 if (c != '?' && nc != '\n') while (getchar() != '\n') ;
                 break;
                 
     }
  } while (1);
  
  return 0;
}

/*----------------------------------------------------------------------*/
static void Inicializar(int quitarbp)
{
  int j;

  for (j=0;j<MAXMEM;j++) memoria[j].tipo = -1;
  
  if (quitarbp)
     for (j=0;j<MAXCOD;j++) breakpoint[j] = 0;
     
  pc = 0;
  Acumulador = 0;
  tipoAcum = 0; /* entero */
  Base = 0;
  tipoBase = 0;

  MODODEB=MDB_STEP;
}
static void interpretar(void)
{
  instr i;
  int h;
  int tipofuente, vifuente, valorfuente;
  double vrfuente;
  int j;
  
  Inicializar(1);
  h = 0;
  
  do
  {
    if (pc >= MAXCOD)
    {
        char b[100];
        
        sprintf(b,"\nERROR(m2r): Puntero al codigo incorrecto (%d)\n",pc);
        errorFatal(b,0,0);
    }
    
    if (pc >= ninst)
    {
        printf("AVISO: el programa debe terminar con la instrucción 'halt'\n");
        break;
    }

    if (debug)
    {
       int r;
       
       r = depurar();
       if (r == 2) return; /* q - salir */
       if (r == 1) /* r - reiniciar la ejecución */
       {
         Inicializar(0);
         h = 0;
         continue;
       }
    }

    i = codigo[pc];

#if (0)
    if (debug)
    {
        printf("(%ld)%d : ",npasos,pc);
        /*PrintfInstruccion(i);*/
        printf("%s",codfuente[pc]);
    }
#endif    

    pc++;
    npasos++;
    
    switch (i.codinstr) {

    case MVETQ:
    case MOV:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            AsignarDestino(i.destino,tipofuente,vifuente,vrfuente);
            break;

    case ADDR:
    case ADDI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            Acumulador += (tipoAcum ? vrfuente : vifuente);
            break;
    case SUBR:
    case SUBI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            Acumulador -= (tipoAcum ? vrfuente : vifuente);
            break;
    case MULR:
    case MULI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            Acumulador *= (tipoAcum ? vrfuente : vifuente);
            break;
    case DIVR:
    case DIVI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (i.codinstr == DIVI)
            {
               if (vifuente == 0)
                  errorFatal("\nERROR(m2r): Division por cero en la instrucción %d.\n", pc,0);
            }
            else if (IgualReales(vrfuente,0.0))
                  errorFatal("\nERROR(m2r): Division por cero en la instrucción %d.\n", pc,0);
            Acumulador /= (tipoAcum ? vrfuente : vifuente);
            if (i.codinstr == DIVI)
                Acumulador = (int)Acumulador;
            break;
    case MODI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            {
               int modulo,acum;
               
               if (vifuente == 0)
                  errorFatal("\nERROR(m2r): Division por cero en la instrucción %d.\n", pc,0);
               acum = (int)Acumulador;
               modulo = acum % vifuente;
               Acumulador = modulo;
            }
            break;
    case ANDR:
    case ANDI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)            
                 Acumulador = ((IgualReales(Acumulador,1)) && 
                               (IgualReales(vrfuente,1)) ? 1 : 0);
            else
                 Acumulador = ((Acumulador == 1) && (vifuente == 1) ? 1 : 0);
            tipoAcum = 0;
            break;
    case ORR:
    case ORI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)            
                 Acumulador = ((IgualReales(Acumulador,0)) && 
                               (IgualReales(vrfuente,0)) ? 0 : 1);
            else
                 Acumulador = ((Acumulador == 0) && (vifuente == 0) ? 0 : 1);
            tipoAcum = 0;
            break;
    case NOTI:
    case NOTR:
            if (tipoAcum)            
                 Acumulador = (IgualReales(Acumulador,0) ? 1 : 0);
            else     
                 Acumulador = (Acumulador == 0 ? 1 : 0);
            tipoAcum = 0;
            break;

    case HALT:
            h = 1;
            break;
    case WRR:
    case WRI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipofuente,0,i.codinstr,pc);
            if (i.codinstr == WRR)
             printf("%8.3f",vrfuente);
            else
             printf("%d",vifuente);
            break;
    case WRC:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipofuente,0,i.codinstr,pc);
            putchar((char)vifuente);
            break;
    case WRL:
            putchar('\n');
            break;
    case RDI:
            valorfuente = lee_valor();
            AsignarDestino(i.destino,0,valorfuente,0.0);
            break;
    case RDR:
            vrfuente = lee_valorReal();
            AsignarDestino(i.destino,1,0,vrfuente);
            break;
    case RDC:
            valorfuente = getchar();
            limpia_bufEntrada(getchar());
            AsignarDestino(i.destino,0,valorfuente,0.0);
            break;
    case JMP:
            valorfuente = ValorPosProg(i.fuente) - 1;
            SaltoPosProg(valorfuente);
            break;
    case EQLR:
    case EQLI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)
              Acumulador = (IgualReales(Acumulador,vrfuente) ? 1 : 0);
            else
              Acumulador = (Acumulador == vifuente ? 1 : 0);
            tipoAcum = 0;
            break;
    case NEQR:
    case NEQI:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)
              Acumulador = (!IgualReales(Acumulador,vrfuente) ? 1 : 0);
            else
              Acumulador = (Acumulador != vifuente ? 1 : 0);
            tipoAcum = 0;
            break;
    case GTRI:
    case GTRR:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)
              Acumulador = (Acumulador > vrfuente ? 1 : 0);
            else
              Acumulador = (Acumulador > vifuente ? 1 : 0);
            tipoAcum = 0;
            break;
    case GEQI:
    case GEQR:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)
              Acumulador = ((Acumulador >= vrfuente || 
                             IgualReales(Acumulador,vrfuente)) ? 1 : 0);
            else
              Acumulador = (Acumulador >= vifuente ? 1 : 0);
            tipoAcum = 0;
            break;
    case LSSI:
    case LSSR:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)
              Acumulador = (Acumulador < vrfuente ? 1 : 0);
            else
              Acumulador = (Acumulador < vifuente ? 1 : 0);
            tipoAcum = 0;
            break;
    case LEQI:
    case LEQR:
            tipofuente = ValorArgumento(i.fuente,&vifuente,&vrfuente);
            ChequearTipos(tipoAcum,tipofuente,i.codinstr,pc);
            if (tipoAcum)
              Acumulador = ((Acumulador <= vrfuente) ||
                            IgualReales(Acumulador,vrfuente) ? 1 : 0);
            else
              Acumulador = (Acumulador <= vifuente ? 1 : 0);
            tipoAcum = 0;
            break;
    case JZ:
            ChequearTipos(tipoAcum,0,JZ,pc); 
            valorfuente = ValorPosProg(i.fuente) - 1;
            if (Acumulador == 0)
                SaltoPosProg(valorfuente);
            break;
    case JNZ:
            ChequearTipos(tipoAcum,0,JNZ,pc); 
            valorfuente = ValorPosProg(i.fuente) - 1;
            if (Acumulador != 0)
                SaltoPosProg(valorfuente);
            break;
    case ITOR:
            ChequearTipos(tipoAcum,0,ITOR,pc); 
            tipoAcum = 1;
            break;
    case RTOI:
            ChequearTipos(tipoAcum,0,RTOI,pc); 
            tipoAcum = 0;
            Acumulador = (int)Acumulador;
            break;
    }
  } while (!h);
}

/*----------------------------------------------------------------------*/
/* Lectura de un fichero de instrucciones */
/*----------------------------------------------------------------------*/

#define ESLETRA(c) ((((c)>='a') && ((c)<='z')) || (((c)>='A') && ((c)<='Z')))
#define ESNUM(c)   (((c)>='0') && ((c)<='9'))

int es_inst(char *s)
{
	int i;

    for(i=0;i<NUMINSTR;i++)
	{
		if (!strcmp(pr[i],s))
            return(i+MOV);
	}
	return(-1);
}
/*-----------------------------------------------------------------*/
typedef struct {
     int etiqueta;
     int ninst;
} ETIQ;

#define MAXETIQ  2000

ETIQ ae[MAXETIQ];
int ce = 0;

void NuevaEtiqueta(int etiq,int ninst)
{
   ae[ce].etiqueta = etiq;
   ae[ce].ninst = ninst;
   ce++;
}
int BuscaEtiq(int etiq)
{
  int i;
  
  for (i=0;i<ce;i++)
    if (ae[i].etiqueta == etiq)
       return(ae[i].ninst);
  return -1;
}

void ResolverEtiquetas(int ninst)
{
  int i;
  
  for (i=0;i<ninst;i++)
    if (codigo[i].fuente.tipo == A_ETIQ)
    {
       int ni;
       
       ni = BuscaEtiq(codigo[i].fuente.num);
       if (ni == -1)
       {
           printf("ERROR(m2r) en la instrucción %d: la etiqueta 'L%d' no aparece al principio de ninguna instruccion\n",i+1,codigo[i].fuente.num);
           exit(1);
       }
       if (codigo[i].codinstr == MVETQ)
           codigo[i].fuente.tipo = A__N;
       else
           codigo[i].fuente.tipo = A_N;
       codigo[i].fuente.num = ni+1;
    }
}
/*--------------------------------------------------------------------*/

static char buf[500];

#define QUITAR_BLANCOS    while ((buf[i] == ' ') || (buf[i] == '\t')) i++

/*----------------------------------------------------------------------*/
int LeeNumero(int *indice)
{
    int numero,nega,i;

    i = *indice;
    numero = 0;
    nega = 0;

    QUITAR_BLANCOS;

    if (buf[i]=='-')
    {
        nega = 1;
        i++;
        QUITAR_BLANCOS;
        if (!ESNUM(buf[i]))
            errorFatal("ERROR(m2r) en la instrucción %d: Esperaba numero despues de '-'\n",
                ninst+1,0);
    }
    else
        if (!ESNUM(buf[i]))
            errorFatal("ERROR(m2r) en la instrucción %d: Esperaba un numero, encontrado '%c'\n",
                ninst+1,buf[i]);

    while (ESNUM(buf[i]))
    {
        numero = 10*numero+buf[i]-'0';
        i++;
    }

    if (nega) numero = - numero;

    *indice = i;

    return(numero);
}
/*----------------------------------------------------------------------*/
double LeeNumeroReal(int *indice)
{
    int nega,i,dec;
    double numero;

    i = *indice;
    numero = 0;
    nega = 0;

    QUITAR_BLANCOS;

    if (buf[i]=='-')
    {
        nega = 1;
        i++;
        QUITAR_BLANCOS;
        if (!ESNUM(buf[i]))
            errorFatal("ERROR(m2r) en la instrucción %d: Esperaba numero despues de '-'\n",
                ninst+1,0);
    }
    else
        if (!ESNUM(buf[i]))
            errorFatal("ERROR(m2r) en la instrucción %d: Esperaba un numero, encontrado '%c'\n",
                ninst+1,buf[i]);

    while (ESNUM(buf[i]))
    {
        numero = 10*numero+buf[i]-'0';
        i++;
    }
    if (buf[i] == '.')
    {
       int dec;

       i++;    
       dec = 0;
       while (ESNUM(buf[i]))
       {
    	numero = 10*numero+buf[i]-'0';
    	i++;
    	dec++;
       }
       while (dec)
       {
          numero = numero / 10.0;
          dec--;
       }
    }
    

    if (nega) numero = - numero;

    *indice = i;

    return(numero);
}
/*----------------------------------------------------------------------*/
void LeeDestino(Argumento *a,int *indice)
{
    int i;

    i = *indice;

    if ((buf[i] == '-') || ESNUM(buf[i]))
    {
        a->tipo = A_N;
        a->num = LeeNumero(&i);
    }
    else switch (buf[i])
    {
        case 'A':
                a->tipo = A_A;
                a->num = 0;
                i++;
                break;
        case 'B':
                a->tipo = A_B;
                a->num = 0;
                i++;
                break;
        case '@':
                i++;
                QUITAR_BLANCOS;
                if (buf[i] == 'A')
                {
                    a->tipo = A_DIRA;
                    a->num = 0;
                    i++;
                }
                else if (buf[i] == 'B')
                {
                    a->tipo = A_DIRB_N;
                    i++;
                    QUITAR_BLANCOS;
                    if (buf[i] == '+')
                        i++;
                    QUITAR_BLANCOS;
                    a->num = LeeNumero(&i);
                }
                else
                    errorFatal("ERROR(m2r) en la instrucción %d: Esperaba 'A' o 'B' despues de '@'\n",
                        ninst+1,0);
                break;
        default:
                errorFatal("ERROR(m2r) en la instrucción %d: Esperaba numero,'A','B','@A' o '@B+numero', encontrado '%c'\n",
                        ninst+1,buf[i]);
                break;
    }

    *indice = i;
}
/*----------------------------------------------------------------------*/
void LeeFuente(Argumento *a,int *indice)
{
    int i;

    i = *indice;

    if ((buf[i] == '-') || ESNUM(buf[i]))
    {
        a->tipo = A_N;
        a->num = LeeNumero(&i);
    }
    else switch (buf[i])
    {
        case 'A':
                a->tipo = A_A;
                a->num = 0;
                i++;
                break;
        case 'B':
                a->tipo = A_B;
                a->num = 0;
                i++;
                break;
        case '@':
                i++;
                QUITAR_BLANCOS;
                if (buf[i] == 'A')
                {
                    a->tipo = A_DIRA;
                    a->num = 0;
                    i++;
                }
                else if (buf[i] == 'B')
                {
                    a->tipo = A_DIRB_N;
                    i++;
                    QUITAR_BLANCOS;
                    if (buf[i] == '+')
                        i++;
                    QUITAR_BLANCOS;
                    a->num = LeeNumero(&i);
                }
                else
                    errorFatal("ERROR(m2r) en la instrucción %d: Esperaba 'A' o 'B' despues de '@'\n",
                        ninst+1,0);
                break;
        case '#':
                i++;
                QUITAR_BLANCOS;
                a->tipo = A__N;
                a->num = LeeNumero(&i);
                break;
        case '$':
                i++;
                QUITAR_BLANCOS;
                a->tipo = A__R;
                a->numr = LeeNumeroReal(&i);
                break;
        default:
                errorFatal("ERROR(m2r) en la instrucción %d: Esperaba numero,'#numero','$numero','A','B','@A' o '@B+numero', encontrado '%c'\n",
                        ninst+1,buf[i]);
                break;
    }

    *indice = i;

}
/*----------------------------------------------------------------------*/
void LeePosprog(Argumento *a,int *indice)
{
    int i,et;

    i = *indice;

    if ((buf[i] == '-') || ESNUM(buf[i]))
    {
        a->tipo = A_N;
        a->num = LeeNumero(&i);
    }
    else switch (buf[i])
    {
        case '@':
                i++;
                QUITAR_BLANCOS;
                if (buf[i] == 'A')
                {
                    a->tipo = A_DIRA;
                    a->num = 0;
                    i++;
                }
                else if (buf[i] == 'B')
                {
                    a->tipo = A_DIRB_N;
                    i++;
                    QUITAR_BLANCOS;
                    if (buf[i] == '+')
                        i++;
                    QUITAR_BLANCOS;
                    a->num = LeeNumero(&i);
                }
                else
                    errorFatal("ERROR(m2r) en la instrucción %d: Esperaba 'A' o 'B' despues de '@'\n",
                        ninst+1,0);
                break;
        case 'L':
                i++;
                if (!ESNUM(buf[i]))
                    errorFatal("ERROR(m2r) en la instrucción %d: Esperaba un numero despues de 'L'.\n",
                        ninst+1,0);
                et = LeeNumero(&i);        
                a->tipo = A_ETIQ;
                a->num = et;
                break;
        default:
                errorFatal("ERROR(m2r) en la instrucción %d: Esperaba numero, etiqueta, '@A' o '@B+numero', encontrado '%c'\n",
                        ninst+1,buf[i]);
                break;
    }

    *indice = i;

}
/*----------------------------------------------------------------------*/
void LeeEtiqueta(Argumento *a,int *indice)
{
    int i,et;

    i = *indice;

    if (buf[i] == 'L')
    {
                i++;
                if (!ESNUM(buf[i]))
                    errorFatal("ERROR(m2r) en la instrucción %d: Esperaba un numero despues de 'L'.\n",
                        ninst+1,0);
                et = LeeNumero(&i);        
                a->tipo = A_ETIQ;
                a->num = et;
    }
    else
        errorFatal("ERROR(m2r) en la instrucción %d: Esperaba una etiqueta, encontrado '%c'\n",
                        ninst+1,buf[i]);
    *indice = i;
}
/*----------------------------------------------------------------------*/
void compile(FILE *f)
{
    char op[15];
    int i,ni,j, codinstr;
    Argumento fuente,destino;

	ninst = 0;
    while (!feof(f))
    {
        if (!fgets(buf,500,f))
            break;
	if (buf[strlen(buf)-1] != '\n')
	{
		int l = strlen(buf);
		buf[l] = '\n';
		buf[l+1] = '\0';
	}		

        i = 0;
        QUITAR_BLANCOS;
		if (buf[i] == '\n') /* admite lineas en blanco */
			continue;
	ni = 0;

        if (ESNUM(buf[i]))
        {
		while (ESNUM(buf[i]))
		{
			ni = 10*ni+buf[i]-'0';
			i++;
		}

		/* ni es el numero de linea */

		if (ni != ninst+1)
			printf("AVISO: Numero de linea incorrecto: %d (debe ser %d)\n",ni,ninst+1);
        }
        else
        {
                ni = ninst+1;
                while (buf[i] == 'L')
                { 
                       int et;
                    
                       i++;
                       if (!ESNUM(buf[i]))
                       {
                          printf("ERROR(m2r) en la instrucción %d: despues de 'L' debe ir un numero\n",ninst+1);
                          exit(1);
                       }
                       et = LeeNumero(&i);
                       NuevaEtiqueta(et,ninst);
                       QUITAR_BLANCOS;
                }
		if (buf[i] == '\n' || buf[i] == ';') /* admite lineas en blanco */
			continue;
        }
        
        
        if (debug)
            codfuente[ninst] = strdup(buf);
              
        QUITAR_BLANCOS;

        if (!ESLETRA(buf[i]))
            errorFatal("ERROR(m2r) en la instrucción %d: la instruccion no comienza por letra\n",
                ninst+1,0);

	j = 0;

        while ((j<14) && ESLETRA(buf[i]))
	{
			op[j] = buf[i];
			j++;
			i++;
	}
	op[j] = '\0';

        codinstr = es_inst(op);
        if (codinstr == -1)
         {
            char b[500];
            
            sprintf(b,"ERROR(m2r) en linea %%d: nombre de instruccion incorrecto (%s)\n",op);
            errorFatal(b,ninst+1,0);
         }

        QUITAR_BLANCOS;

        codigo[ninst].codinstr = codinstr;
        switch (codinstr)
        {
            case MOV:
                    LeeFuente(&fuente,&i);
                    QUITAR_BLANCOS;
                    LeeDestino(&destino,&i);
                    codigo[ninst].fuente = fuente;
                    codigo[ninst].destino = destino;
                    break;
            case MVETQ:
                    LeeEtiqueta(&fuente,&i);
                    QUITAR_BLANCOS;
                    LeeDestino(&destino,&i);
                    codigo[ninst].fuente = fuente;
                    codigo[ninst].destino = destino;
                    break;
            case ADDI:
            case ADDR:
            case SUBI:
            case SUBR:
            case MULI:
            case MULR:
            case DIVI:
            case MODI:
            case DIVR:
            case ANDI:
            case ANDR:
            case ORI:
            case ORR:
            case WRI:
            case WRR:
            case WRC:
            case EQLI:
            case EQLR:
            case NEQI:
            case NEQR:
            case GTRI:
            case GTRR:
            case GEQI:
            case GEQR:
            case LSSI:
            case LSSR:
            case LEQI:
            case LEQR:
                    LeeFuente(&fuente,&i);
                    codigo[ninst].fuente = fuente;
                    break;
            case RDI:
            case RDR:
            case RDC:
                    LeeDestino(&destino,&i);
                    codigo[ninst].destino = destino;
                    break;
            case JMP:
            case JZ:
            case JNZ:
                    LeePosprog(&fuente,&i);
                    codigo[ninst].fuente = fuente;
                    break;
            case HALT:
            case WRL:
            case ITOR:
            case RTOI:
            case NOTI:
            case NOTR:
                    break;
        }

        QUITAR_BLANCOS;

        if ((buf[i] != '\n') && (buf[i] != ';'))
        {
            printf("AVISO (%d.%d): caracter '%c' inesperado o falta ';' para comentario\n",ninst+1,i+1,buf[i]);
            printf(" (la instrucción '%s' debe tener %d argumentos)\n",op,nargs[codinstr]);
        }

	ninst++;
    }
    ResolverEtiquetas(ninst);
}


/*----------------------------------------------------------------------*/
int main(int argc,char *argv[])
{
  FILE *f;
  int fich = 1;

  if ((argc != 2) && (argc != 3))
  {
    fprintf(stderr,"USO: m2r [-d] <nombre_fichero>\n");
    exit(1);
  }
  if (argv[1][0] == '-')
    {
      fich = 2;
      if (argv[1][1] == 'd')
	debug = 1;
    }
  f = fopen(argv[fich],"rt");
  if (!f)	
  {
    printf("ERROR(m2r): No puedo abrir el fichero '%s'\n",argv[fich]);
    exit(1);
  }

  compile(f);
  fclose(f);
  interpretar();
  exit(0);
  return(1);
}
