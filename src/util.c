/****************************************************/
/* File: util.c                                     */
/* Utility function implementation                  */
/* for the TINY compiler                            */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#include "globals.h"
#include "util.h"

/* Procedure printToken prints a token 
 * and its lexeme to the listing file
 */
void printToken( TokenType token, const char* tokenString )
{
  switch (token)
  {
    case IF:
    case ELSE:
    case INT:
    case RETURN:
    case VOID:
    case WHILE:
      pc("reserved word: %s\n", tokenString);
      break;
    case PLUS:     pc("+\n"); break;
    case MINUS:    pc("-\n"); break;
    case TIMES:    pc("*\n"); break;
    case OVER:     pc("/\n"); break;
    case LT:       pc("<\n"); break;
    case LE:       pc("<=\n"); break;
    case GT:       pc(">\n"); break;
    case GE:       pc(">=\n"); break;
    case EQ:       pc("==\n"); break;
    case NEQ:      pc("!=\n"); break;
    case ASSIGN:   pc("=\n"); break;
    case SEMI:     pc(";\n"); break;
    case COMMA:    pc(",\n"); break;
    case LPAREN:   pc("(\n"); break;
    case RPAREN:   pc(")\n"); break;
    case LBRACKET: pc("[\n"); break;
    case RBRACKET: pc("]\n"); break;
    case LBRACE:   pc("{\n"); break;
    case RBRACE:   pc("}\n"); break;
    case ENDFILE:  pc("EOF\n"); break;
    case NUM:
      pc("NUM, val= %s\n", tokenString);
      break;
    case ID:
      pc("ID, name= %s\n", tokenString);
      break;
    case ERROR:
      pce("ERROR: %s\n", tokenString);
      break;
    default: /* should never happen */
      pce("Unknown token: %d\n", token);
  }
}

/* Function that prints the current line */
void printLine(FILE *redundant_source)
{ 
  char line[1024]; 
  char *ret = fgets(line, 1024, redundant_source); 
  if (ret) { 
    pc("%d: %-1s", lineno, line); 
    if (feof(redundant_source)) 
      pc("\n");
  }
}

/* Function newStmtNode creates a new statement node */
TreeNode * newStmtNode(StmtKind kind)
{
  TreeNode * t = (TreeNode *) malloc(sizeof(TreeNode));
  int i;
  if (t==NULL)
    pce("Out of memory error at line %d\n",lineno);
  else {
    for (i=0;i<MAXCHILDREN;i++) t->child[i] = NULL;
    t->sibling = NULL;
    t->nodekind = StmtK;
    t->kind.stmt = kind;
    t->lineno = lineno;
    t->type = Void;
  }
  return t;
}

/* Function newExpNode creates a new expression node */
TreeNode * newExpNode(ExpKind kind)
{
  TreeNode * t = (TreeNode *) malloc(sizeof(TreeNode));
  int i;
  if (t==NULL)
    pce("Out of memory error at line %d\n",lineno);
  else {
    for (i=0;i<MAXCHILDREN;i++) t->child[i] = NULL;
    t->sibling = NULL;
    t->nodekind = ExpK;
    t->kind.exp = kind;
    t->lineno = lineno;
    t->type = Void;
  }
  return t;
}

TreeNode * newDeclNode(DeclKind kind)
{
  TreeNode * t = (TreeNode *) malloc(sizeof(TreeNode));
  int i;
  if (t==NULL)
    pce("Out of memory error at line %d\n",lineno);
  else {
    for (i=0;i<MAXCHILDREN;i++) t->child[i] = NULL;
    t->sibling = NULL;
    t->nodekind = DeclK;
    t->kind.decl = kind;
    t->lineno = lineno;
    t->type = Void;
  }
  return t;
}

TreeNode * newParamNode(ParamKind kind)
{
  TreeNode * t = (TreeNode *) malloc(sizeof(TreeNode));
  int i;
  if (t==NULL)
    pce("Out of memory error at line %d\n",lineno);
  else {
    for (i=0;i<MAXCHILDREN;i++) t->child[i] = NULL;
    t->sibling = NULL;
    t->nodekind = ParamK;
    t->kind.param = kind;
    t->lineno = lineno;
    t->type = Void;
  }
  return t;
}

/* Function copyString allocates and makes a new copy of an existing string */
char * copyString(char * s)
{
  int n;
  char * t;
  if (s==NULL) return NULL;
  n = (int)strlen(s)+1;
  t = (char*)malloc(n);
  if (t==NULL)
    pce("Out of memory error at line %d\n",lineno);
  else strcpy(t,s);
  return t;
}

/* Variable indentno is used by printTree to store current number of spaces */
static int indentno = 0;

/* macros to increase/decrease indentation */
#define INDENT   do { indentno += 4; } while(0)
#define UNINDENT do { indentno -= 4; if (indentno < 0) indentno = 0; } while(0)

/* printSpaces indents by printing spaces */
static void printSpaces(void)
{
  int i;
  for (i=0;i<indentno;i++)
    pc(" ");
}

/* helper: imprime uso de vetor (r-value): nome + índice como filho */
static void printArrayUse(TreeNode *t)
{
  /* t é ArrIdK */
  pc("Id: %s\n", t->attr.name);
  INDENT;
  if (t->child[0]) printTree(t->child[0]); /* índice */
  UNINDENT;
}

/* helper: imprime corpo de bloco (CompoundK) no MESMO nível atual */
static void printCompoundChildren(TreeNode *t)
{
  int i;
  if (!t) return;
  for (i = 0; i < MAXCHILDREN; i++)
    printTree(t->child[i]);
}

/* procedure printTree prints a syntax tree using indentation */
void printTree(TreeNode *tree)
{
  int i;
  while (tree != NULL) 
  {
    int childrenHandled = 0;
    printSpaces();

    if (tree->nodekind == StmtK)
    {
      switch (tree->kind.stmt) {
        case IfK:
          pc("Conditional selection\n");
          break;

        case WhileK:
          /* imprime laço, condição e corpo em um único nível abaixo */
          pc("Iteration (loop)\n");
          childrenHandled = 1;
          INDENT;
          if (tree->child[0]) printTree(tree->child[0]); /* condição */
          if (tree->child[1]) {
            if (tree->child[1]->nodekind == StmtK &&
                tree->child[1]->kind.stmt == CompoundK) {
              printCompoundChildren(tree->child[1]);
            } else {
              printTree(tree->child[1]);
            }
          }
          UNINDENT;
          break;

        case ReturnK:
          pc("Return\n");
          break;

        case CompoundK:
          /* Não imprime o nó; apenas “achata” filhos neste nível. */
          childrenHandled = 1;
          printCompoundChildren(tree);
          break;

        default:
          pce("Unknown StmtNode kind\n");
          break;
      }
    }
    else if (tree->nodekind == ExpK)
    {
      switch (tree->kind.exp) {
        case OpK:
          pc("Op: ");
          printToken(tree->attr.op, "\0");
          break;

        case ConstK:
          pc("Const: %d\n", tree->attr.val);
          break;

        case IdK:
          pc("Id: %s\n", tree->attr.name);
          break;

        case ArrIdK:
          printArrayUse(tree);
          childrenHandled = 1; /* já tratou o filho índice */
          break;

        case AssignK:
          /* child[0] = destino; child[1] = expressão RHS */
          if (tree->child[0] &&
              tree->child[0]->nodekind == ExpK &&
              tree->child[0]->kind.exp == IdK) {
            pc("Assign to var: %s\n", tree->child[0]->attr.name);
            INDENT;
            if (tree->child[1]) printTree(tree->child[1]);
            UNINDENT;
            childrenHandled = 1;
          } else if (tree->child[0] &&
                     tree->child[0]->nodekind == ExpK &&
                     tree->child[0]->kind.exp == ArrIdK) {
            pc("Assign to array: %s\n", tree->child[0]->attr.name);
            INDENT;
            if (tree->child[0]->child[0]) printTree(tree->child[0]->child[0]); /* índice */
            if (tree->child[1]) printTree(tree->child[1]);                     /* RHS */
            UNINDENT;
            childrenHandled = 1;
          } else {
            pc("Assign\n");
            INDENT;
            if (tree->child[1]) printTree(tree->child[1]);
            UNINDENT;
            childrenHandled = 1;
          }
          break;

        case CallK:
          pc("Function call: %s\n", tree->attr.name);
          break;

        case TypeK:
          pc("Type: %s\n", (tree->type == Integer) ? "int" : "void");
          break;

        default:
          pce("Unknown ExpNode kind\n");
          break;
      }
    }
    else if (tree->nodekind == DeclK)
    {
      switch (tree->kind.decl) {
        case FunDeclK:
          /* Controla explicitamente para evitar dupla indentação. */
          pc("Declare function (return type \"%s\"): %s\n",
             (tree->type == Integer) ? "int" : "void", tree->attr.name);
          childrenHandled = 1;
          INDENT;
          for (i = 0; i < MAXCHILDREN; i++) {
            TreeNode *ch = tree->child[i];
            if (!ch) continue;
            if (ch->nodekind == StmtK && ch->kind.stmt == CompoundK)
              printCompoundChildren(ch);
            else
              printTree(ch);
          }
          UNINDENT;
          break;

        case VarDeclK:
          pc("Declare %s var: %s\n",
             (tree->type == Integer) ? "int" : "void", tree->attr.name);
          break;

        case ArrVarDeclK:
          pc("Declare %s array: %s\n",
             (tree->type == Integer) ? "int" : "void", tree->attr.name);
          INDENT;
          printSpaces();
          pc("Const: %d\n", tree->arraysize);
          UNINDENT;
          childrenHandled = 1; /* não há outros filhos reais */
          break;

        default:
          pce("Unknown DeclNode kind\n");
          break;
      }
    }
    else if (tree->nodekind == ParamK)
    {
      switch (tree->kind.param) {
        case NonArrParamK:
          pc("Function param (%s var): %s\n",
             (tree->type == Integer) ? "int" : "void", tree->attr.name);
          break;
        case ArrParamK:
          pc("Function param (%s array): %s\n",
             (tree->type == Integer) ? "int" : "void", tree->attr.name);
          break;
        default:
          pce("Unknown ParamNode kind\n");
          break;
      }
    }
    else {
      pce("Unknown node kind\n");
    }

    /* impressão genérica dos filhos (um nível abaixo) se ainda não tratado */
    if (!childrenHandled) {
      INDENT;
      for (i = 0; i < MAXCHILDREN; i++)
        printTree(tree->child[i]);
      UNINDENT;
    }

    tree = tree->sibling;
  }
}
