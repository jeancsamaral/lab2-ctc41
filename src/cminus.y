/****************************************************/
/* File: cminus.y                                   */
/* The C- Yacc/Bison specification file             */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/* Project for CES41: Compiladores                  */
/****************************************************/
%{
#define YYPARSER /* prevents a double definition of TokenType in globals.h */
#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *

static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void); /* lex function from flex */
int yyerror(char * message);
%}

%token INT VOID
%token IF ELSE RETURN WHILE
%token ID NUM
%token ASSIGN LE LT GE GT EQ NE
%token PLUS MINUS TIMES OVER
%token LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE
%token SEMI COMMA ERROR

%% /* Grammar for C- */

program
  : declaration_list
      { savedTree = $1; }
  ;

declaration_list
  : declaration_list declaration
      { TreeNode * t = $1;
        if (t != NULL)
        { while (t->sibling != NULL)
            t = t->sibling;
          t->sibling = $2;
          $$ = $1; }
        else $$ = $2;
      }
  | declaration  { $$ = $1; }
  ;

declaration
  : var_declaration { $$ = $1; }
  | fun_declaration { $$ = $1; }
  ;

type_specifier
  : INT   { $$ = $1; /* reuse the temp node from lexer */ }
  | VOID  { $$ = $1; /* reuse the temp node from lexer */ }
  ;

var_declaration
  : type_specifier ID SEMI
      { $$ = newDeclNode(VarDeclK);
        $$->attr.name = $2->attr.name;
        $$->type = $1->type;
        $$->lineno = lineno;
      }
  | type_specifier ID LBRACK NUM RBRACK SEMI
      { $$ = newDeclNode(ArrVarDeclK);
        $$->attr.name = $2->attr.name;
        $$->type = $1->type;
        $$->arraysize = $4->attr.val;
        $$->child[0] = $4;
        $$->lineno = lineno;
      }
  ;

fun_declaration
  : type_specifier ID LPAREN params RPAREN compound_stmt
      { $$ = newDeclNode(FunDeclK);
        $$->attr.name = $2->attr.name;
        $$->type = $1->type;
        $$->lineno = lineno;
        $$->child[0] = $4;
        $$->child[1] = $6;
      }
  ;

params
  : param_list { $$ = $1; }
  | VOID       { $$ = NULL; }
  ;

param_list
  : param_list COMMA param
      { TreeNode * t = $1;
        if (t != NULL)
        { while (t->sibling != NULL)
            t = t->sibling;
          t->sibling = $3;
          $$ = $1; }
        else $$ = $3;
      }
  | param { $$ = $1; }
  ;

param
  : type_specifier ID
      { $$ = newParamNode(NonArrParamK);
        $$->attr.name = $2->attr.name;
        $$->type = $1->type;
        $$->lineno = lineno;
      }
  | type_specifier ID LBRACK RBRACK
      { $$ = newParamNode(ArrParamK);
        $$->attr.name = $2->attr.name;
        $$->type = $1->type;
        $$->lineno = lineno;
      }
  ;

compound_stmt
  : LBRACE local_declarations statement_list RBRACE
      { TreeNode * t = $2;
        if (t != NULL)
        { while (t->sibling != NULL)
            t = t->sibling;
          t->sibling = $3;
          $$ = $2;
        }
        else $$ = $3;
      }
  ;

local_declarations
  : local_declarations var_declaration
      { TreeNode * t = $1;
        if (t != NULL)
        { while (t->sibling != NULL)
            t = t->sibling;
          t->sibling = $2;
          $$ = $1; }
        else $$ = $2;
      }
  | /* empty */ { $$ = NULL; }
  ;

statement_list
  : statement_list statement
      { TreeNode * t = $1;
        if (t != NULL)
        { while (t->sibling != NULL)
            t = t->sibling;
          t->sibling = $2;
          $$ = $1; }
        else $$ = $2;
      }
  | /* empty */ { $$ = NULL; }
  ;

statement
  : expression_stmt { $$ = $1; }
  | compound_stmt { $$ = $1; }
  | selection_stmt { $$ = $1; }
  | iteration_stmt { $$ = $1; }
  | return_stmt { $$ = $1; }
  ;

expression_stmt
  : expression SEMI { $$ = $1; }
  | SEMI { $$ = NULL; }
  ;

selection_stmt
  : IF LPAREN expression RPAREN statement
      { $$ = newStmtNode(IfK);
        $$->child[0] = $3;
        $$->child[1] = $5;
        $$->lineno = lineno;
      }
  | IF LPAREN expression RPAREN statement ELSE statement
      { $$ = newStmtNode(IfK);
        $$->child[0] = $3;
        $$->child[1] = $5;
        $$->child[2] = $7;
        $$->lineno = lineno;
      }
  ;

iteration_stmt
  : WHILE LPAREN expression RPAREN statement
      { $$ = newStmtNode(WhileK);
        $$->child[0] = $3;
        $$->child[1] = $5;
        $$->lineno = lineno;
      }
  ;

return_stmt
  : RETURN SEMI
      { $$ = newStmtNode(ReturnK);
        $$->lineno = lineno;
      }
  | RETURN expression SEMI
      { $$ = newStmtNode(ReturnK);
        $$->child[0] = $2;
        $$->lineno = lineno;
      }
  ;

expression
  : var ASSIGN expression
      { $$ = newStmtNode(AssignK);
        $$->attr.name = $1->attr.name;
        if ($1->kind.exp == ArrIdK) {
          $$->child[0] = $1->child[0]; /* array index */
          $$->child[1] = $3;           /* assigned value */
        } else {
          $$->child[0] = $3;           /* assigned value */
        }
        $$->lineno = lineno;
      }
  | simple_expression { $$ = $1; }
  ;

var
  : ID
      { $$ = $1; /* ID node already created by lexer */ }
  | ID LBRACK expression RBRACK
      { $$ = newExpNode(ArrIdK);
        $$->attr.name = $1->attr.name;
        $$->child[0] = $3;
        $$->lineno = lineno;
      }
  ;

simple_expression
  : additive_expression { $$ = $1; }
  | additive_expression LT additive_expression
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = LT;
        $$->lineno = lineno;
      }
  | additive_expression LE additive_expression
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = LE;
        $$->lineno = lineno;
      }
  | additive_expression GT additive_expression
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = GT;
        $$->lineno = lineno;
      }
  | additive_expression GE additive_expression
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = GE;
        $$->lineno = lineno;
      }
  | additive_expression EQ additive_expression
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = EQ;
        $$->lineno = lineno;
      }
  | additive_expression NE additive_expression
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = NE;
        $$->lineno = lineno;
      }
  ;

additive_expression
  : additive_expression PLUS term
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = PLUS;
        $$->lineno = lineno;
      }
  | additive_expression MINUS term
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = MINUS;
        $$->lineno = lineno;
      }
  | term { $$ = $1; }
  ;

term
  : term TIMES factor
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = TIMES;
        $$->lineno = lineno;
      }
  | term OVER factor
      { $$ = newExpNode(OpK);
        $$->child[0] = $1;
        $$->child[1] = $3;
        $$->attr.op = OVER;
        $$->lineno = lineno;
      }
  | factor { $$ = $1; }
  ;

factor
  : LPAREN expression RPAREN { $$ = $2; }
  | var { $$ = $1; }
  | call { $$ = $1; }
  | NUM { $$ = $1; /* NUM node already created by lexer */ }
  ;

call
  : ID LPAREN args RPAREN
      { $$ = newStmtNode(CallK);
        $$->attr.name = $1->attr.name;
        $$->child[0] = $3;
        $$->lineno = lineno;
      }
  ;

args
  : arg_list { $$ = $1; }
  | /* empty */ { $$ = NULL; }
  ;

arg_list
  : arg_list COMMA expression
      { TreeNode * t = $1;
        if (t != NULL)
        { while (t->sibling != NULL)
            t = t->sibling;
          t->sibling = $3;
          $$ = $1; }
        else $$ = $3;
      }
  | expression { $$ = $1; }
  ;

%%

int yyerror(char * message)
{ pce("Syntax error at line %d: %s\n",lineno,message);
  pce("Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output compatible with ealier versions of the C- scanner */
static int yylex(void)
{ return getToken(); }

TreeNode * parse(void)
{ yyparse();
  return savedTree;
}
