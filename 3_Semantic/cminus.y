/****************************************************/
/* File: cminus.y                                     */
/* The C-MINUS Yacc/Bison specification file           */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static char * savedName; /* for use in assignments */
static int savedNum;
static int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void); // added 11/2/11 to ensure no conflict with lex
int yyerror(char * message);

%}

%token IF ELSE WHILE RETURN INT VOID
%token ID NUM 
%token ASSIGN EQ NE LT LE GT GE PLUS MINUS TIMES OVER LPAREN RPAREN LBRACE RBRACE LCURLY RCURLY SEMI COMMA
%token ERROR

%nonassoc WOELSE
%nonassoc ELSE

%% /* Grammar for CMINUS */

program       : decl_list
                  { savedTree = $1;} 
              ;
decl_list     : decl_list declaration
                { YYSTYPE t = $1;
                  if (t != NULL)
                  { while (t->sibling != NULL)
                        t = t->sibling;
                    t->sibling = $2;
                    $$ = $1; }
                    else $$ = $2;
                }
              | declaration  { $$ = $1; }
              ;
declaration   : var_decl { $$ = $1; }
              | func_decl { $$ = $1;}
              ;
id            : ID
                {
                  savedName = copyString(tokenString);
                  savedLineNo = lineno;
                }
              ;
num           :NUM
                {
                  savedNum = atoi(tokenString);
                  savedLineNo = lineno;
                }
              ;
var_decl      : VOID id SEMI
                {
                  $$ = newDeclNode(VarK);
                  $$->attr.name = savedName;
                  $$->type = Void;
                  $$->lineno = savedLineNo;
                }
              | VOID id LBRACE num RBRACE SEMI
                {
                  $$ = newDeclNode(VarK);
                  $$->attr.name = savedName;
                  $$->type = Void;
                  $$->lineno = savedLineNo;
                  $$->child[0] = newExpNode(ConstK);
                  $$->child[0]->attr.val = savedNum;
                }
              | INT id SEMI
                {
                  $$ = newDeclNode(VarK);
                  $$->attr.name = savedName;
                  $$->type = Integer;
                  $$->lineno = savedLineNo;
                }
              | INT id LBRACE num RBRACE SEMI
                {
                  $$ = newDeclNode(VarK);
                  $$->attr.name = savedName;
                  $$->type = Integer;
                  $$->lineno = savedLineNo;
                  $$->child[0] = newExpNode(ConstK);
                  $$->child[0]->attr.val = savedNum;
                }
              ;
func_decl     : VOID id
                {
                  $$ = newDeclNode(FuncK);
                  $$->attr.name = savedName;
                  $$->type = Void;
                  $$->lineno = savedLineNo;
                }
                LPAREN params RPAREN compound_stmt
                {
                  $$ = $3;
                  $$->child[0] = $5;
                  $$->child[1] = $7;
                }
              | INT id
                {
                  $$ = newDeclNode(FuncK);
                  $$->attr.name = savedName;
                  $$->type = Integer;
                  $$->lineno = savedLineNo;
                }
                LPAREN params RPAREN compound_stmt
                {
                  $$ = $3;
                  $$->child[0] = $5;
                  $$->child[1] = $7;
                }
              ;
params        : param_list { $$ = $1; }
              | VOID 
                {
                  $$ = newDeclNode(VoidParamK);
                  $$->lineno = lineno;
                }
param_list    : param_list COMMA param 
                { 
                  YYSTYPE t = $1;
                  if (t != NULL)
                  { while (t->sibling != NULL)
                        t = t->sibling;
                    t->sibling = $3;
                    $$ = $1; }
                    else $$ = $3;
                }
              | param { $$ = $1;}
              ;
param         : INT id
                {
                  $$ = newDeclNode(ParamK);
                  $$->attr.name = savedName;
                  $$->type = Integer;
                }
              | INT id LBRACE RBRACE
                {
                  $$ = newDeclNode(ParamK);
                  $$->attr.name = savedName;
                  $$->type = IntegerArr;
                }
              | VOID id
                {
                  $$ = newDeclNode(ParamK);
                  $$->attr.name = savedName;
                  $$->type = Void;
                }
              | VOID id LBRACE RBRACE
                {
                  $$ = newDeclNode(ParamK);
                  $$->attr.name = savedName;
                  $$->type = VoidArr;
                }
              ;
compound_stmt : LCURLY local_decl stmt_list RCURLY
                {
                  $$ = newStmtNode(CompK);
                  $$->child[0] = $2;
                  $$->child[1] = $3;
                }
              ;
local_decl    : local_decl var_decl
                {
                  YYSTYPE t = $1;
                  if (t != NULL)
                  { while (t->sibling != NULL)
                        t = t->sibling;
                    t->sibling = $2;
                    $$ = $1; }
                    else $$ = $2;
                }
              | { $$ = NULL; }
              ;
stmt_list     : stmt_list stmt
                { 
                  YYSTYPE t = $1;
                  if (t != NULL)
                  { while (t->sibling != NULL)
                        t = t->sibling;
                    t->sibling = $2;
                    $$ = $1; }
                    else $$ = $2;
                }
              | { $$ = NULL; }
              ;     
stmt          : if_stmt { $$ = $1; }
              | compound_stmt { $$ = $1; }
              | repeat_stmt { $$ = $1; }
              | return_stmt { $$ = $1; }
              | expression_stmt { $$ = $1; }
              ;
expression_stmt : exp SEMI { $$ = $1; }
                | SEMI { $$ = NULL; }
                ;
if_stmt       : IF LPAREN exp RPAREN stmt %prec WOELSE
                  { $$ = newStmtNode(IfK);
                    $$->child[0] = $3;
                    $$->child[1] = $5;
                  }
              | IF LPAREN exp RPAREN stmt ELSE stmt
                  { $$ = newStmtNode(IfelseK);
                    $$->child[0] = $3;
                    $$->child[1] = $5;
                    $$->child[2] = $7;
                  }
              ;
repeat_stmt   : WHILE LPAREN exp RPAREN stmt
                { $$ = newStmtNode(WhileK);
                  $$->child[0] = $3;
                  $$->child[1] = $5;
                }
              ;
return_stmt   : RETURN SEMI
                {
                  $$ = newStmtNode(ReturnK);
                  $$->child[0] = NULL;
                }
              | RETURN exp SEMI
                {
                  $$ = newStmtNode(ReturnK);
                  $$->child[0] = $2;
                }
              ;
exp           : var ASSIGN exp
                {
                  $$ = newExpNode(AssignK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                }
              | simple_exp { $$ = $1; }
              ;
var           : id
                {
                  $$ = newExpNode(IdK);
                  $$->attr.name = savedName;
                }
              | id
                {
                  $$ = newExpNode(ArrK);
                  $$->attr.name = savedName;
                }
                LBRACE exp RBRACE
                {
                  $$ = $2;
                  $$->child[0] = $4;
                }
              ;
simple_exp    : add_exp EQ add_exp
                {
                  $$ = newExpNode(OpK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                  $$->attr.op = EQ;
                }
              | add_exp NE add_exp
                {
                  $$ = newExpNode(OpK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                  $$->attr.op = NE;
                }
              | add_exp LT add_exp
                {
                  $$ = newExpNode(OpK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                  $$->attr.op = LT;
                }
              | add_exp LE add_exp
                {
                  $$ = newExpNode(OpK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                  $$->attr.op = LE;
                }
              | add_exp GT add_exp
                {
                  $$ = newExpNode(OpK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                  $$->attr.op = GT;
                }
              | add_exp GE add_exp
                {
                  $$ = newExpNode(OpK);
                  $$->child[0] = $1;
                  $$->child[1] = $3;
                  $$->attr.op = GE;
                }
              | add_exp { $$ = $1; }
              ;
add_exp       : add_exp PLUS term 
                  { $$ = newExpNode(OpK);
                    $$->child[0] = $1;
                    $$->child[1] = $3;
                    $$->attr.op = PLUS;
                  }
              | add_exp MINUS term
                  { $$ = newExpNode(OpK);
                    $$->child[0] = $1;
                    $$->child[1] = $3;
                    $$->attr.op = MINUS;
                  } 
              | term { $$ = $1; }
              ;
term          : term TIMES factor 
                  { $$ = newExpNode(OpK);
                    $$->child[0] = $1;
                    $$->child[1] = $3;
                    $$->attr.op = TIMES;
                  }
              | term OVER factor
                  { $$ = newExpNode(OpK);
                    $$->child[0] = $1;
                    $$->child[1] = $3;
                    $$->attr.op = OVER;
                  }
              | factor { $$ = $1; }
              ;
factor        : LPAREN exp RPAREN
                  { $$ = $2; }
              | num
                  { $$ = newExpNode(ConstK);
                    $$->attr.val = atoi(tokenString);
                  }
              | var { $$ = $1; }
              | call { $$ = $1; }
              ;
call          : id
                {
                  $$ = newExpNode(CallK);
                  $$->attr.name = savedName;
                }
                LPAREN args RPAREN
                {
                  $$ = $2;
                  $$->child[0] = $4;
                }
              ;
args          : arg_list { $$ = $1; }
              | { $$ = NULL; }
              ;
arg_list      : arg_list COMMA exp 
                { 
                  YYSTYPE t = $1;
                  if (t != NULL)
                  { while (t->sibling != NULL)
                        t = t->sibling;
                    t->sibling = $3;
                    $$ = $1; }
                    else $$ = $3;
                }
              | exp { $$ = $1;}
              ;
%%

int yyerror(char * message)
{ fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
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
