/****************************************************/
/* File: cminus.l                                   */
/* Lex specification for C-                         */
/* Project for CES41: Compiladores                  */
/****************************************************/

%option noyywrap 

%{
/* Forward declarations to define YYSTYPE before including headers */
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
%}

digit       [0-9]
number      {digit}+
letter      [a-zA-Z]
identifier  {letter}+
newline     \n
whitespace  [ \t\r]+

%%

"else"         {return ELSE;}
"if"           {return IF;}
"int"          {
                 yylval = newExpNode(IdK);
                 yylval->type = Integer;
                 return INT;
               }
"return"       {return RETURN;}
"void"         {
                 yylval = newExpNode(IdK);
                 yylval->type = Void;
                 return VOID;
               }
"while"        {return WHILE;}
"+"            {return PLUS;}
"-"            {return MINUS;}
"*"            {return TIMES;}
"/"            {return OVER;}
"<"            {return LT;}
"<="           {return LE;}
">"            {return GT;}
">="           {return GE;}
"=="           {return EQ;}
"!="           {return NE;}
"="            {return ASSIGN;}
";"            {return SEMI;}
","            {return COMMA;}
"("            {return LPAREN;}
")"            {return RPAREN;}
"["            {return LBRACK;}
"]"            {return RBRACK;}
"{"            {return LBRACE;}
"}"            {return RBRACE;}
{number}       {
                 yylval = newExpNode(ConstK);
                 yylval->attr.val = atoi(yytext);
                 return NUM;
               }
{identifier}   {
                 yylval = newExpNode(IdK);
                 yylval->attr.name = copyString(yytext);
                 return ID;
               }
{newline}      {lineno++;}
{whitespace}   {/* skip whitespace */}
"/*"           { char c;
                 char prev = 0;
                 do {
                   c = input();
                   if (c == EOF) break;
                   if (c == '\n') lineno++;
                   if (prev == '*' && c == '/') break;
                   prev = c;
                 } while (1);
               }
.              {return ERROR;}

%%

TokenType getToken(void)
{ static int firstTime = TRUE;
  TokenType currentToken;
  if (firstTime)
  { firstTime = FALSE;
    lineno++;
    yyin = source;
    yyout = listing;
  }
  currentToken = yylex();
  strncpy(tokenString,yytext,MAXTOKENLEN);
  if (TraceScan) {
    pc("\t%d: ",lineno);
    printToken(currentToken,tokenString);
  }
  return currentToken;
}
