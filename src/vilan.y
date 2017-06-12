%{
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include "codeBuilder.h"

void yyerror(char* );
int yylex();

CONTEXT c;
%}
%token DECLARE BEGN END INTT ARR PRINT ERROR READ FOR IN TO STEP ENDFOR IF THEN ELSE ENDIF NUM STR VAR OPB
%union {
    char* s; int i;
    struct { char* code; int val; } val;
    struct { char* init_code; char* end_code; } forc;
}
%type <s> STR
%type <s> VAR
%type <i> NUM
%type <s> numval
//%type <i> list
%type <s> OPB
%type <s> vilan
%type <s> dec
%type <s> initvar
%type <s> code
%type <s> assign
%type <s> ffor
%type <forc> initfor
%type <s> steps
%type <s> iff
%type <s> cond

%left '*' '+' '-' '/'
%left OPB
%%
vilan: DECLARE dec BEGN code END { asprintf(&$$, "%sstart\n%s", $2, $4); printf ("Done.\n"); }
     ;

dec: initvar dec              { asprintf(&$$, "%s%s", $1, $2); }
   |                          { $$ = strdup(""); }
   ;

initvar: INTT VAR              { $$ = declare_int(c, $2, "\tpushi 0\n"); }
       | INTT VAR '=' numval   { $$ = declare_int(c, $2, $4); }
       | ARR NUM VAR         { $$ = declare_array(c, $3, $2); }
       ;

code: assign code             { asprintf(&$$, "%s%s", $1, $2); }
    | ffor code               { asprintf(&$$, "%s%s", $1, $2); }
    | iff code                { asprintf(&$$, "%s%s", $1, $2); }
    | PRINT STR code          { asprintf(&$$, "%s%s", print_str($2), $3); }
    | PRINT numval code       { asprintf(&$$, "%s%s", print_num(), $3); }
    | ERROR STR code          { asprintf(&$$, "%s%S", error($2), $3); }
    |                         { $$ = strdup(""); }
    ;

assign: VAR '=' numval      { $$ = assign(c, $1, $3); }
//      | VAR '=' list          { $$ = $1.value; }
      | VAR '=' READ        { $$ = read_var(c, $1); }
      ;

numval: numval '+' numval  { asprintf(&$$, "%s%sadd\n", $3, $1); }
      | numval '-' numval  { asprintf(&$$, "%s%ssub\n", $3, $1); }
      | numval '*' numval  { asprintf(&$$, "%s%smul\n", $3, $1); }
      | numval '/' numval  { asprintf(&$$, "%s%sdiv\n", $3, $1); }
      | '(' numval ')'     { $$ = $2; }
      | NUM                { asprintf(&$$, "\tpushi %d\n", $1); }
      | VAR                { $$ = push_var(c, $1); }
      ;
/*
list: '[' listval ']'      { $$ = 0; }
    ;

listval: numval ',' listval
       | numval
       |
       ;
*/
ffor: initfor code ENDFOR { $$ = for_code(c, $1.init_code, $2, $1.end_code);}
    ;

initfor: FOR VAR IN VAR steps     { $$.init_code = init_for_in(c, $2);
                                    $$.end_code = end_for_in(c, $2, $4, $5);}
       | FOR VAR TO numval steps  { $$.init_code = init_for_in(c, $2);
                                    $$.end_code = end_for_to(c, $2, $4, $5);}
       ;

steps: STEP numval   { $$ = $2; }
     |               { asprintf(&$$, "\tpushi 1\n"); }
     ;

iff: IF cond THEN code ENDIF             { $$ = if_then_else(c, $2, $4, ""); }
   | IF cond THEN code ELSE code ENDIF   { $$ = if_then_else(c, $2, $4, $6); }
   ;

cond: cond OPB cond     { asprintf(&$$, "%s%s%s", $3, $1, operator($2)); }
    | '(' cond ')'      { $$ = $2; }
    | NUM               { asprintf(&$$, "pushi %d", $1); }
    | VAR               { asprintf(&$$, "%s", push_var(c, $1)); }
    ;
%%
#include "lex.yy.c"

void yyerror (char *s) {
    fprintf(stderr, "%d: %s\n\t%s\n", yylineno, yytext, s);
}

int main(int argc, char* argv[]) {
    c = new_context();

    yyparse();

    return 0;
}
