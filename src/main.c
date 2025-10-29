/****************************************************/
/* File: main.c                                     */
/* Main program for C- compiler                     */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#include "globals.h"

/* set NO_PARSE to TRUE to get a scanner-only compiler */
#define NO_PARSE FALSE
/* set NO_ANALYZE to TRUE to get a parser-only compiler */
#define NO_ANALYZE TRUE

/* set NO_CODE to TRUE to get a compiler that does not
 * generate code
 */
#define NO_CODE TRUE

#include "util.h"
#if NO_PARSE
#include "scan.h"
#else
#include "parse.h"
#if !NO_ANALYZE
#include "analyze.h"
#if !NO_CODE
#include "cgen.h"
#endif
#endif
#endif

/* allocate global variables */
int lineno = 0;
FILE * source;
FILE * listing;
FILE * code;

/* allocate and set tracing flags */
int EchoSource = FALSE;
int TraceScan = TRUE;
int TraceParse = TRUE;
int TraceAnalyze = TRUE;
int TraceCode = TRUE;

int Error = FALSE;

int main( int argc, char * argv[] )
{ TreeNode * syntaxTree;
  
    //// opening sources ////
    char pgm[120]; /* source code file name */
    if ((argc < 2) || (argc > 3))
    { fprintf(stderr,"usage: %s <filename> [<detailpath>]\n",argv[0]);
      exit(1);
    }
    strcpy(pgm,argv[1]);
    if (strchr (pgm, '.') == NULL)
        strcat(pgm,".cm");// if no extension is given, append .cm (c minus) to the filename
    source = fopen(pgm,"r");
    if (source==NULL)
    { fprintf(stderr,"File %s not found\n",pgm);
        exit(1);
    }
    
    char detailpath[200];
    if (3 == argc) {
        strcpy(detailpath,argv[2]);
    } else strcpy(detailpath,"/tmp/");// default detailpath is /tmp. Check there if you called by hand.
    //// end opening sources ////
    
    listing = stdout; /* send messages from main() to screen */
    
#if NO_PARSE
    initializePrinter(detailpath, pgm, LER);
    fprintf(listing,"\nC- COMPILATION (LEX ONLY): %s\n",pgm);
    while (getToken()!=ENDFILE);
#else
    initializePrinter(detailpath, pgm, LOGALL);
    fprintf(listing,"\nC- COMPILATION: %s\n",pgm);
    
    syntaxTree = parse();
    
    // Phase transition: LEX done, starting SYN
    doneLEXstartSYN();
    
    if (TraceParse) {
        fprintf(listing,"\nSyntax tree:\n");
        printTree(syntaxTree);
    }
    
    // Phase transition: SYN done, starting TAB  
    doneSYNstartTAB();
    
#if !NO_ANALYZE
    if (! Error)
    { 
      if (TraceAnalyze) fprintf(listing,"\nBuilding Symbol Table...\n");
      buildSymtab(syntaxTree);
      if (TraceAnalyze) fprintf(listing,"\nChecking Types...\n");
      typeCheck(syntaxTree);
      if (TraceAnalyze) fprintf(listing,"\nType Checking Finished\n");
      
      // Phase transition: TAB done, starting GEN
      doneTABstartGEN();
    }
#if !NO_CODE
    if (! Error)
    { char * codefile;
      int fnlen = strcspn(pgm,".");
      codefile = (char *) calloc(fnlen+4, sizeof(char));
      strncpy(codefile,pgm,fnlen);
      strcat(codefile,".tm");
      code = fopen(codefile,"w");
      if (code == NULL)
      { printf("Unable to open %s\n",codefile);
        exit(1);
      }
      codeGen(syntaxTree,codefile);
      fclose(code);
    }
#endif
#endif
#endif
    fclose(source);
    closePrinter();
    return 0;
}
