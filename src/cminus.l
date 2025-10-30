/****************************************************/
/* File: cminus.l                                   */
/* Lex specification for C-                         */
/* Project for CES41: Compiladores                  */
/****************************************************/

%option noyywrap 
/* opção noyywrap pode ser necessária para novas versões do flex
  limitação: não compila mais de um arquivo fonte de uma só vez (não precisamos disso)
  https://stackoverflow.com/questions/1480138/undefined-reference-to-yylex 
*/ 

%{
typedef struct treeNode TreeNode;
typedef TreeNode * YYSTYPE;
#define YYSTYPE_IS_DECLARED 1
#define YYSTYPE_IS_TRIVIAL 1
extern YYSTYPE yylval;

#include "globals.h"
#include "util.h"
#include "scan.h"
/* lexeme of identifier or reserved word */
char tokenString[MAXTOKENLEN+1];
char previousTokenString[MAXTOKENLEN+1];
%}
digit       [0-9]
number      {digit}+
letter      [a-zA-Z]
identifier  {letter}+
newline     \n
whitespace  [ \t\r]+
comment     \/\*([^*]|\*+[^*/])*\*+\/
%%
"if"            {return IF;}
"else"          {return ELSE;}
"int"           {return INT;}
"return"        {return RETURN;}
"void"          {return VOID;}
"while"         {return WHILE;}
"+"             {return PLUS;}
"-"             {return MINUS;}
"*"             {return TIMES;}
"/"             {return OVER;}
"<="            {return LE;}
"<"             {return LT;}
">="            {return GE;}
">"             {return GT;}
"=="            {return EQ;}
"!="            {return NEQ;}
"="             {return ASSIGN;}
";"             {return SEMI;}
","             {return COMMA;}
{number}        {
                  yylval = newExpNode(ConstK);
                  yylval->attr.val = atoi(yytext);
                  return NUM;
                }
{identifier}    {
                  yylval = newExpNode(IdK);
                  yylval->attr.name = copyString(yytext);
                  return ID;
                }
{newline}       {lineno++; printLine(redundant_source);}
{whitespace}    {/* skip whitespace */}
"("             {return LPAREN;}
")"             {return RPAREN;}
"{"             {return LBRACE;}
"}"             {return RBRACE;}
"["             {return LBRACKET;}
"]"             {return RBRACKET;}
{comment}       {
                  int i = 0;
                  while(yytext[i] != '\0') {
                      if(yytext[i] == '\n') {
                        lineno++;
                        printLine(redundant_source);
                      }
                      i++;
                  }
                }
<<EOF>>         {return ENDFILE;}
.               {return ERROR;}
%%
TokenType getToken(void)
{ 
  static int firstTime = TRUE;
  static int eofReturned = FALSE;
  TokenType currentToken;
  if (firstTime)
  { 
    firstTime = FALSE;
    yyin = source;
    yyout = listing;
    printLine(redundant_source);
  }
  if (eofReturned) return ENDFILE;
  
  strncpy(tokenString, previousTokenString, MAXTOKENLEN);
  currentToken = yylex();
  strncpy(previousTokenString, yytext, MAXTOKENLEN);
  if (TraceScan) {
    pc("\t%d: ",lineno);
    printToken(currentToken,previousTokenString);
  }
  if (currentToken == ENDFILE) eofReturned = TRUE;
  return currentToken;
}