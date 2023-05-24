/****************************************************/
/* File: symtab.h                                   */
/* Symbol table interface for the CMINUS compiler     */
/* (allows only one symbol table)                   */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#ifndef _SYMTAB_H_
#define _SYMTAB_H_
#define SIZE 211

#include "globals.h"

/* the list of line numbers of the source 
 * code in which a variable is referenced
 */
typedef struct LineListRec
   { int lineno;
     struct LineListRec * next;
   } * LineList;

/* The record in the bucket lists for
 * each variable, including name, 
 * assigned memory location, and
 * the list of line numbers in which
 * it appears in the source code
 */
typedef struct ParameterListRec
{
  char * name;
  ExpType type;
  struct ParameterListRec * next;
} * ParamList;

typedef struct BucketListRec
   { char * name;
     char * kind;
     ExpType type;
     LineList lines;
     int memloc ; /* memory location for variable */
     struct parameterListRec * params;
     struct BucketListRec * next;
   } * BucketList;

typedef struct ScopeListRec
    {
      char * name;
      BucketList bucket[SIZE];
      struct ScopeListRec * parent;
    } * ScopeList;

/* Procedure st_insert inserts line numbers and
 * memory locations into the symbol table
 * loc = memory location is inserted only the
 * first time, otherwise ignored
 */
BucketList st_insert( ScopeList scope, char * name, char * kind, ExpType type, int lineno, int loc );

/* Function st_lookup returns the memory 
 * location of a variable or -1 if not found
 */
BucketList st_lookup ( ScopeList scope, char * name );
BucketList st_lookup_excluding_parent ( ScopeList scope, char * name );

/* Procedure printSymTab prints a formatted 
 * listing of the symbol table contents 
 * to the listing file
 */
void printSymTab(FILE * listing);
void printFuncTab(FILE * listing);
void printGloSymTab(FILE * listing);
void printScopeTab(FILE * listing);

#endif
