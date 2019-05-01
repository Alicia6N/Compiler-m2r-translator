#!/bin/bash

MAXTIME=15 	    # Tiempo máximo de ejecución (en segundos) de una prueba
PRINCIPAL=plp5      # Nombre del ejecutable de la práctica
FNT=fuentes	    # Directorio con los ficheros fuente de entrada
ENT=datos-entrada   # Directorio con los datos de entrada a las pruebas
SAL=salida-esperada # Directorio con los ficheros de salida correctos
OBT=salida-obtenida # Directorio con los ficheros obtenidos tras la ejecución de la práctica

mata=/tmp/mata
comparefiles=/tmp/comparefiles

# -------------- generar y compilar los ficheros auxiliares mata.c y comparefiles.cc -----
function genMataComparefiles() {

echo "#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>

const int TAMMAXFICH=300000;
int f;int segundos,st;
int segejec=0;
char *nfsal=NULL;
void SeAcabo(int i){  
  fprintf(stderr,\"ERROR, tiempo de ejecución agotado... (%d segundos)\\n\",segundos);
  fflush(stderr); 
  kill(f,SIGKILL);  
  exit(-1); 
}
void SeAcaboFich(int i){  
  fprintf(stderr,\"ERROR, fichero de salida muy grande (cuelgue?)... \\n\");
  fflush(stderr); 
  kill(f,SIGKILL);  
  exit(-1); 
}
int FicheroGrande() {  
  struct stat s;  int ret=0;
  if (nfsal != NULL) {   
    stat(nfsal,&s);    
    if (s.st_size > TAMMAXFICH) ret = 1;  
  }  
  return ret;
}
void Control(int i){ 
  segejec++; 
  if (segejec >= segundos) SeAcabo(i); 
  else if (FicheroGrande()) SeAcaboFich(i); 
  else alarm(1); 
}
void Salir(int i){exit(1);}
int main(int argc,char *argv[]){ 
  if (argc < 4) exit(1);  
  segundos = atoi(argv[1]);  
  nfsal = argv[2]; 
  signal(SIGALRM,Control);  
  signal(SIGCHLD,Salir);  
  alarm(1);  
  if ((f = fork()) == 0) execvp(argv[3],&argv[3]);   
  else wait(&st);
}
" > $mata.c
gcc -o $mata $mata.c

echo "#include <iostream>
#include <fstream>
#include <stdlib.h>

using namespace std;

int main(int argc, char *argv[])
{
  int salida=0;

  if (argc!=3) cout << \"Sintaxis: \" << argv[0] << \" <obtenido.txt> <correcto.txt>\" << endl;
  else 
  {
    ifstream fo(argv[1]);
    ifstream fc(argv[2]);
    if (fo.is_open() && fc.is_open())
    {
      string so,sc,tmp;

      fo >> tmp;
      while (!fo.eof() || tmp.length()!=0)
      {
        so=so+tmp;
        tmp=\"\";
        fo >> tmp;
      }
      fc >> tmp;
      while (!fc.eof() || tmp.length()!=0)
      {
        sc=sc+tmp;
        tmp=\"\";
        fc >> tmp;
      }

      if (so!=sc) {
        exit(-1);
      }
    }
    else {
      cout << \"Fichero \" << argv[1] << \" o \" << argv[2] << \" no encontrado\" << endl;
      exit(-1);
    }
  }
  exit(0);
  return salida;
}
" > $comparefiles.cc

g++ -o $comparefiles $comparefiles.cc

}

echo "*********************************************************"
echo "Autocorrector plp5 "
echo " Generando ficheros auxiliares... "
genMataComparefiles

# comprobar que está el m2r.c y compilarlo
okm2r=0
if test -s m2r.c ; then
  gcc -o m2r m2r.c
  if test -x m2r ; then
    okm2r=1
  fi
fi


if test $okm2r -eq 1 ; then
 

 # Compilacion
 echo "*********************************************************"
 echo " Compilando..."
 echo "*********************************************************"
 
 flex $PRINCIPAL.l
 bison -d $PRINCIPAL.y
 g++ -std=c++11 -Wno-write-strings -o $PRINCIPAL $PRINCIPAL.tab.c lex.yy.c

 if [ $? -ne 0 ]; then
	echo "LA PRACTICA NO COMPILA"

 else

  # Ejecucion y comprobacion de la salida
  echo
  echo "*********************************************************"
  echo " Ejecutando y comprobando salida a la vez..."
  echo "*********************************************************"

  npruebas=0
  pok=0;
  for i in `ls $FNT`
  do
	echo "Prueba: $i" 

	# Ejecucion del programa
	$mata $MAXTIME $OBT/$i.cod   ./$PRINCIPAL $FNT/$i > $OBT/$i.cod 2> $OBT/$i.err

	if test -s $OBT/$i.err ; then  # hay un error
	    $comparefiles  $OBT/$i.err $SAL/$i.err
	    if [ $? -ne 0 ]; then
	        echo "--- Fallo en la salida de error ----------"
	        diff -EwB -I "---" $OBT/$i.err $SAL/$i.err 2>&1
	    else
	        echo "OK" 
		let pok++
	    fi
	else  # no hay errores, ejecutar el m2r
	    bn=$(basename $i .acs)
	    if test -s $ENT/$bn.ent ; then
	       $mata $MAXTIME $OBT/$i.sal  ./m2r $OBT/$i.cod < $ENT/$bn.ent > $OBT/$i.sal 2>&1
	    else
	       $mata $MAXTIME $OBT/$i.sal  ./m2r $OBT/$i.cod > $OBT/$i.sal 2>&1
	    fi

            $comparefiles $OBT/$i.sal $SAL/$i.sal
	    if [ $? -ne 0 ]; then
	       echo "--- Fallo en la traducción ----------"
	       diff -EwB $OBT/$i.sal $SAL/$i.sal 2>&1
	    else
	        echo "OK" 
		let pok++
	    fi
	fi
	echo "--------------------------"
	let npruebas++
  done

  if [ $pok -eq $npruebas ]; then
	echo -e "\nTODAS LAS PRUEBAS DEL AUTOCORRECTOR FUNCIONAN\n"
  else 
	echo -e "\nOJO: FALLAN" $[npruebas-pok] "PRUEBAS DEL AUTOCORRECTOR\n"
  fi
 fi

 echo -e "\n\nAVISO IMPORTANTE: este autocorrector NO prueba todos los casos posibles\n"

else
 echo "NO SE ENCUENTRA El m2r.c O NO SE PUEDE COMPILAR"
fi
