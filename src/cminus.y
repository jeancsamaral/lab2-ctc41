%{
#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *

static int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void);
int yyerror(char *);

%}

%token IF ELSE INT RETURN VOID WHILE 
%token PLUS MINUS TIMES OVER 
%token LT LE GT GE EQ NEQ ASSIGN SEMI COMMA
%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE
%token ENDFILE NUM ID ERROR 

%% /* Grammar for C- */

program : declaration_list
            { savedTree = $1; }
        ;

declaration_list    : declaration_list declaration
                        {
                            YYSTYPE t = $1;
                            if (t != NULL)
                            {
                                while (t->sibling != NULL)
                                    t = t->sibling;
                                t->sibling = $2;
                                $$ = $1;
                            }
                            else $$ = $2;
                        }
                    | declaration 
                        {  $$ = $1; }
                    ;

declaration : var_declaration
                {  $$ = $1; }
            | fun_declaration
                {  $$ = $1; }
            ;

var_declaration : type_specifier ID SEMI
                    { 
                      $$ = newDeclNode(VarDeclK);
                      $$->attr.name = $2->attr.name;
                      $$->type = $1->type;
                      $$->lineno = lineno;
                    }
                | type_specifier ID LBRACKET NUM RBRACKET SEMI
                    { 
                      $$ = newDeclNode(ArrVarDeclK);
                      $$->attr.name = $2->attr.name;
                      $$->type = $1->type;
                      $$->arraysize = $4->attr.val;
                      $$->lineno = lineno;
                    }
                ;

type_specifier  : INT
                    { 
                      $$ = newExpNode(TypeK);
                      $$->type = Integer;  
                    }
                | VOID  
                    { 
                      $$ = newExpNode(TypeK);
                      $$->type = Void; 
                    }
                ;

fun_declaration : type_specifier ID LPAREN params RPAREN comp_decl
                    {
                      $$ = newDeclNode(FunDeclK);
                      $$->attr.name = $2->attr.name;
                      $$->type = $1->type;
                      $$->lineno = lineno;
                      $$->child[0] = $4;
                      $$->child[1] = $6;
                    }
                ;

params  : param_list
            { $$ = $1; }
        | VOID
            { $$ = NULL; }
        ;

param_list  : param_list COMMA param
                {
                  YYSTYPE t = $1;
                  if (t != NULL) {
                    while (t->sibling != NULL)
                      t = t->sibling;
                    t->sibling = $3;
                    $$ = $1;
                  }
                  else { $$ = $3; }
                }
            | param
                { $$ = $1; }
            ;

param : type_specifier ID
          { 
            $$ = newParamNode(NonArrParamK);
            $$->attr.name = $2->attr.name;
            $$->type = $1->type;
            $$->lineno = lineno;
          }
      | type_specifier ID LBRACKET RBRACKET
          { 
            $$ = newParamNode(ArrParamK);
            $$->attr.name = $2->attr.name;
            $$->type = $1->type;
            $$->lineno = lineno;
          }
      ;

comp_decl : LBRACE block_item_list RBRACE
            { 
              $$ = newStmtNode(CompoundK);
              $$->child[0] = $2;
              $$->child[1] = NULL;
            }
          ;

block_item_list : block_item_list block_item
                    {
                        YYSTYPE t = $1;
                        if (t != NULL) {
                            while (t->sibling != NULL)
                                t = t->sibling;
                            t->sibling = $2;
                            $$ = $1;
                        }
                        else { $$ = $2; }
                    }
                | { $$ = NULL; }
                ;

block_item : var_declaration
                { $$ = $1; }
           | statement
                { $$ = $1; }
           ;

local_decl  : local_decl var_declaration
                {
                    YYSTYPE t = $1;
                    if (t != NULL) {
                        while (t->sibling != NULL)
                            t = t->sibling;
                        t->sibling = $2;
                        $$ = $1;
                    }
                    else { $$ = $2; }
                }
            | { $$ = NULL; }
            ;

statement_list  : statement_list statement
                    {
                        YYSTYPE t = $1;
                        if (t != NULL) {
                            while (t->sibling != NULL)
                                t = t->sibling;
                            t->sibling = $2;
                            $$ = $1;
                        }
                        else { $$ = $2; }
                    }
                |  { $$ = NULL; }
                ;

statement : expr_decl
                { $$ = $1; }
          | comp_decl
                { $$ = $1; }
          | sel_decl
                { $$ = $1; }
          | iter_decl
                { $$ = $1; }
          | ret_decl
                { $$ = $1; }
          ;

expr_decl   : expression SEMI
                { $$ = $1; }
            | SEMI
                { $$ = NULL; }
            ;

sel_decl    : IF LPAREN expression RPAREN statement
                {
                  $$ = newStmtNode(IfK);
                  $$->child[0] = $3;
                  $$->child[1] = $5;
                  $$->lineno = lineno;
                }
            | IF LPAREN expression RPAREN statement ELSE statement
                {
                  $$ = newStmtNode(IfK);
                  $$->child[0] = $3;
                  $$->child[1] = $5;
                  $$->child[2] = $7;
                  $$->lineno = lineno;
                }
            ;

iter_decl   : WHILE LPAREN expression RPAREN statement
                {
                  $$ = newStmtNode(WhileK);
                  $$->child[0] = $3;
                  $$->child[1] = $5;
                  $$->lineno = lineno;
                }
            ;

ret_decl : RETURN SEMI
            {
              $$ = newStmtNode(ReturnK);
              $$->lineno = lineno;
            }
         | RETURN expression SEMI
            { 
              $$ = newStmtNode(ReturnK);
              $$->child[0] = $2;
              $$->lineno = lineno;
            }
         ;

expression  : var ASSIGN expression
                {
                  $$ = newExpNode(AssignK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                  $$->lineno = lineno;
                }
            | simple_expression
                { $$ = $1; }
            ;

var : ID
        { $$ = $1; }
    | ID LBRACKET expression RBRACKET
        {
          $$ = newExpNode(ArrIdK);
          $$->attr.name = $1->attr.name;
          $$->child[0] = $3;
          $$->lineno = lineno;
        }
    ;

simple_expression : sum_expr relational sum_expr
                        {
                          $$ = $2;
                          if ($$ != NULL) {
                            $$->child[0] = $1;
                            $$->child[1] = $3;
                            $$->lineno = lineno;
                          }
                        }
                  | sum_expr
                        { $$ = $1; }
                  ;

relational  : LE
                {
                  $$ = newExpNode(OpK);
                  if ($$ != NULL) $$->attr.op = LE;
                }
            | LT
                {
                  $$ = newExpNode(OpK);
                  if ($$ != NULL) $$->attr.op = LT;
                }
            | GT
                {
                  $$ = newExpNode(OpK);
                  if ($$ != NULL) $$->attr.op = GT;
                }
            | GE
                {
                  $$ = newExpNode(OpK);
                  if ($$ != NULL) $$->attr.op = GE;
                }
            | EQ
                {
                  $$ = newExpNode(OpK);
                  if ($$ != NULL) $$->attr.op = EQ;
                }
            | NEQ
                {
                  $$ = newExpNode(OpK);
                  if ($$ != NULL) $$->attr.op = NEQ;
                }
            ;

sum_expr : sum_expr sum term
            {
                $$ = $2;
                if ($$ != NULL) {
                    $$->child[0] = $1;
                    $$->child[1] = $3;
                    $$->lineno = lineno;
                }
            }
         | term
            { $$ = $1; }
         ;

sum : PLUS
        {
          $$ = newExpNode(OpK);
          if ($$ != NULL) $$->attr.op = PLUS;
        }
    | MINUS
        {
          $$ = newExpNode(OpK);
          if ($$ != NULL) $$->attr.op = MINUS;
        }
    ;

term : term mult factor
            {
                $$ = $2;
                if ($$ != NULL) {
                    $$->child[0] = $1;
                    $$->child[1] = $3;
                    $$->lineno = lineno;
                }
            }
      | factor
            { $$ = $1; }
      ;

mult : TIMES
        {
          $$ = newExpNode(OpK);
          if ($$ != NULL) $$->attr.op = TIMES;
        }
    | OVER
        {
          $$ = newExpNode(OpK);
          if ($$ != NULL) $$->attr.op = OVER;
        }
    ;

factor  : LPAREN expression RPAREN
            { $$ = $2; }
        | var
            { $$ = $1; }
        | activation
            { $$ = $1; }
        | NUM
            { $$ = $1; }
        | MINUS factor
            {
              $$ = newExpNode(OpK);
              $$->attr.op = MINUS;
              $$->child[0] = $2;
              $$->lineno = lineno;
            }
        | PLUS factor
            {
              $$ = newExpNode(OpK);
              $$->attr.op = PLUS;
              $$->child[0] = $2;
              $$->lineno = lineno;
            }
        ;

activation  : ID LPAREN args RPAREN
                {
                  $$ = newExpNode(CallK);
                  $$->attr.name = $1->attr.name;
                  $$->child[0] = $3;
                  $$->lineno = lineno;
                }
            ;

args : arg_list
        { $$ = $1; }
     | { $$ = NULL; }
     ;

arg_list : arg_list COMMA expression
            {
              YYSTYPE t = $1;
              if (t != NULL) {
                while (t->sibling != NULL)
                  t = t->sibling;
                t->sibling = $3;
                $$ = $1;
              }
              else 
              { $$ = $3; }
            }
         | expression
            { $$ = $1; }
         ;

%%

int yyerror(char * message)
{ 
  /* Only report error if not at EOF after successful parse */
  if (yychar != ENDFILE || savedTree == NULL) {
    pce("Syntax error at line %d: %s\n",lineno,message);
    pce("Current token: ");
    printToken(yychar,tokenString);
    Error = TRUE;
  }
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the TINY scanner
 */
static int yylex(void)
{ return getToken(); }

TreeNode * parse(void)
{ yyparse();
  return savedTree;
}

