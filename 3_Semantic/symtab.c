/****************************************************/
/* File: symtab.c                                   */
/* Symbol table implementation for the CMINUS compiler*/
/* (allows only one symbol table)                   */
/* Symbol table is implemented as a chained         */
/* hash table                                       */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"
#include "globals.h"

/* SIZE is the size of the hash table */
#define SIZE 211

/* SHIFT is the power of two used as multiplier
   in hash function  */
#define SHIFT 4

/* the hash function */
static int hash ( char * key )
{ int temp = 0;
  int i = 0;
  while (key[i] != '\0')
  { temp = ((temp << SHIFT) + key[i]) % SIZE;
    ++i;
  }
  return temp;
}

/* the hash table */
//static BucketList hashTable[SIZE];
static ScopeList scope;

ScopeList newScope (char * name)
{
  int i;
  ScopeList newScop = (ScopeList)malloc(sizeof(struct ScopeListRec));
  newScop->name = name;
  for(i=0; i<SIZE; ++i) {
    newScop->bucket[i] = NULL;
  }
  newScop->parent = NULL;
  return newScop;
}

void newGlobalScope(void) {
  scope = newScope("global");
  BucketList output = st_insert(scope, "output", "Function", Void, 0, 0);
  ParamList newParam = (ParamList)malloc(sizeof(struct ParameterListRec));
  newParam->name = "value";
  newParam->type = Integer;
  newParam->next = NULL;
  output->params = newParam;

  BucketList input = st_insert(scope, "input", "Function", Integer, 0, 1);
  input->params = NULL;
}

/* Procedure st_insert inserts line numbers and
 * memory locations into the symbol table
 * loc = memory location is inserted only the
 * first time, otherwise ignored
 */
BucketList st_insert( ScopeList scope, char * name, char * kind, ExpType type, int lineno, int loc )
{ int h = hash(name);
  BucketList l =  scope->bucket[h];
  while ((l != NULL) && (strcmp(name,l->name) != 0))
    l = l->next;
  if (l == NULL) /* variable not yet in table */
  { l = (BucketList) malloc(sizeof(struct BucketListRec));
    l->name = name;
    l->kind = kind;
    l->type = type;
    l->lines = (LineList) malloc(sizeof(struct LineListRec));
    l->lines->lineno = lineno;
    l->memloc = loc;
    l->lines->next = NULL;
    l->next = scope->bucket[h];
    scope->bucket[h] = l; }
  else /* found in table, so just add line number */
  { LineList t = l->lines;
    while (t->next != NULL) t = t->next;
    t->next = (LineList) malloc(sizeof(struct LineListRec));
    t->next->lineno = lineno;
    t->next->next = NULL;
  }
  return l;
} /* st_insert */

/* Function st_lookup returns the memory 
 * location of a variable or -1 if not found
 */
BucketList st_lookup ( ScopeList scope, char * name )
{ int h = hash(name);
  while (scope != NULL) {
    BucketList l =  scope->bucket[h];
    while ((l != NULL) && (strcmp(name,l->name) != 0))
      l = l->next;
    if (l == NULL) scope = scope->parent;
    else return l;
  }
  return NULL;
}

BucketList st_lookup_excluding_parent ( ScopeList scope, char * name )
{
  int h = hash(name);
  while (scope != NULL) {
    BucketList l =  scope->bucket[h];
    while ((l != NULL) && (strcmp(name,l->name) != 0))
      l = l->next;
    if (l == NULL) return NULL;
    else return l;
  }
  return NULL;
}

/* Procedure printSymTab prints a formatted 
 * listing of the symbol table contents 
 * to the listing file
 */
void printSymTab(FILE * listing)
{ int i;
  fprintf(listing,"Symbol Name  Symbol Kind  Symbol Type  Scope Name  Location  Line Numbers\n");
  fprintf(listing,"-----------  -----------  -----------  ----------  --------  ------------\n");
  for (i=0;i<SIZE;++i)
  { if (scope->bucket[i] != NULL)
    { BucketList l = scope->bucket[i];
      while (l != NULL)
      { LineList t = l->lines;
        fprintf(listing,"%-12s ",l->name);
        fprintf(listing,"%-12s ",l->kind);
        fprintf(listing,"%-12s ",l->type);
        fprintf(listing,"%-11s ",scope->name);        
        fprintf(listing,"%-9d  ",l->memloc);
        while (t != NULL)
        { fprintf(listing,"%3d ",t->lineno);
          t = t->next;
        }
        fprintf(listing,"\n");
        l = l->next;
      }
    }
  }
} /* printSymTab */

void printFuncTab(FILE * listing)
{ int i;
  fprintf(listing,"Function Name  Return Type  Parameter Name  Parameter Type\n");
  fprintf(listing,"-------------  -----------  --------------  --------------\n");
  for (i=0;i<SIZE;++i)
  { if (scope->bucket[i] != NULL)
    { BucketList l = scope->bucket[i];
      while ((l != NULL) && (strcmp(l->kind, "Function") != 0))
      { ParamList t = l->params;
        fprintf(listing,"%-14s ",l->name);
        fprintf(listing,"%-14s ",l->type);
        while((t != NULL))
        {
          fprintf(listing,"\n");
          fprintf(listing,"%-14s ","-");
          fprintf(listing,"%-12s ","-");
          fprintf(listing,"%-15s ",t->name);
          fprintf(listing,"%-15s ",t->type);
          t = t->next;
        }
        fprintf(listing,"\n");
        l = l->next;
      }
    }
  }
}

void printGloSymTab(FILE * listing)
{ int i;
  fprintf(listing,"Symbol Name  Symbol Kind  Symbol Type\n");
  fprintf(listing,"-----------  -----------  -----------\n");
  for (i=0;i<SIZE;++i)
  { if (scope->bucket[i] != NULL)
    { BucketList l = scope->bucket[i];
      while ((l != NULL) && (strcmp(l->name, "global") != 0))
      { fprintf(listing,"%-12s ",l->name);
        fprintf(listing,"%-12s ",l->kind);
        fprintf(listing,"%-12s ",l->type);
        fprintf(listing,"\n");
        l = l->next;
      }
    }
  }
}

void printScopeTab(FILE * listing)
{ int i;
  fprintf(listing,"Scope Name  Nested Level  Symbol Name  Symbol Type\n");
  fprintf(listing,"----------  ------------  -----------  -----------\n");
  for (i=0;i<SIZE;++i)
  { if (scope->bucket[i] != NULL)
    { BucketList l = scope->bucket[i];
      int level=0;
      while (l != NULL)
      { level++;
        fprintf(listing,"%-11s ",scope->name);
        fprintf(listing,"%-13d ",i);
        fprintf(listing,"%-12s ",l->name);
        fprintf(listing,"%-12s ",l->type);
        fprintf(listing,"\n");
        l = l->next;
      }
    }
  }
}

