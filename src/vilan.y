%{
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include "codeBuilder.h"

void yyerror(char* );
int yylex();

CONTEXT c;
%}
%token DECLARE PROCEDURE ENDPROC GOTO BEGN END INTT ARR PRINT ERROR READ FOR IN TO STEP ENDFOR IF THEN ELSE ENDIF NUM STR VAR OPB OPA OPM
%union {
    char* s; int i;
    struct { char* init_code; char* end_code; } forc;
}

%type <s> STR
%type <s> VAR
%type <i> NUM
%type <s> numval
%type <s> term
%type <s> factor
%type <s> OPM
%type <s> OPA
%type <s> OPB
%type <s> vilan
%type <s> dec
%type <s> initvar
%type <s> code
%type <s> statament
%type <s> assign
%type <s> ffor
%type <forc> initfor
%type <s> steps
%type <s> iff
%type <s> cond
%type <s> procs
%type <s> proc

%%
vilan: DECLARE dec procs BEGN code END { fprintf(stdout, "%sstart\n%sbegin:%s\tstop\n", $2,
                                                  $3, $5); }
     ;

dec: initvar dec              { asprintf(&$$, "%s%s", $1, $2); }
   |                          { $$ = ""; }
   ;

initvar: INTT VAR              { $$ = declare_int(c, $2, "\tpushi 0\n"); }
       | INTT VAR '=' numval   { $$ = declare_int(c, $2, $4); }
       | ARR NUM VAR           { $$ = declare_array(c, $3, $2); }
       ;

procs: proc procs    { asprintf(&$$, "\tjump begin\n%s%s", $1, $2); }
     |               { $$ = ""; }
     ;

proc: PROCEDURE VAR code ENDPROC { asprintf(&$$, "%s:\tnop\n%s\treturn\n", $2, $3 ); }
    ;

code :                { $$ = ""; }
     | statament code { asprintf(&$$, "%s%s", $1, $2); }
     ;


statament: assign             { asprintf(&$$, "%s", $1); }
         | ffor               { asprintf(&$$, "%s", $1); }
         | iff                { asprintf(&$$, "%s", $1); }
         | PRINT STR          { asprintf(&$$, "%s", print_str($2)); }
         | PRINT numval       { asprintf(&$$, "%s%s", $2, print_num()); }
         | ERROR STR          { asprintf(&$$, "%s", error($2)); }
         | GOTO VAR           { asprintf(&$$, "\tpusha %s\n\tcall\n", $2); }
         ;

assign: VAR '=' numval                { $$ = assign(c, $1, $3); }
      | VAR '=' READ                  { $$ = read_var(c, $1); }
      | VAR '[' numval ']' '=' READ   { $$ = read_array(c, $1, $3); }
      | VAR '[' numval ']' '=' numval { asprintf(&$$, "%s%s\tloadn\n",
                                              push_array(c, $1, $3), $6); }
      ;

numval: term                { $$ = $1; }
      | numval OPA term     { $$ = operatorA(c, $1, $2, $3); }
      ;

term: factor                { $$ = $1; }
    | term OPM factor       { $$ = operatorM(c, $1, $2, $3); }
    ;

factor: VAR                 { $$ = push_var(c, $1); }
      | NUM                 { asprintf(&$$, "\tpushi %d\n", $1); }
      | VAR '[' numval ']'  { asprintf(&$$, "%s\tloadn\n", push_array(c, $1, $3)); }
      | '(' numval ')'      { $$ = $2; }
      ;

ffor: initfor code ENDFOR { $$ = for_code(c, $1.init_code, $2, $1.end_code);}
    ;

initfor: FOR VAR IN VAR steps  { $$.init_code = init_for_in(c, $2, 0);
                                 $$.end_code = end_for_in(c, $2, $4, $5); }
       | FOR VAR TO numval steps  { $$.init_code = init_for_in(c, $2, 0);
                                    $$.end_code = end_for_to(c, $2, $4, $5);}
       | FOR VAR '=' NUM TO numval steps  {$$.init_code = init_for_in(c, $2,$4);
                                       $$.end_code = end_for_to(c, $2, $6, $7);}
       ;

steps: STEP numval   { $$ = $2; }
     |               { asprintf(&$$, "\tpushi 1\n"); }
     ;

iff: IF cond THEN code ENDIF             { $$ = if_then_else(c, $2, $4, ""); }
   | IF cond THEN code ELSE code ENDIF   { $$ = if_then_else(c, $2, $4, $6); }
   ;

cond: numval              { $$ = $1; }
    | numval OPB numval   { asprintf(&$$, "%s%s%s", $3, $1, operator(c, $2)); }
    | '(' cond ')'        { $$ = $2; }
    ;
%%
#include "lex.yy.c"

void yyerror (char *s) {
    fprintf(stderr, "%d: %s\n\t%s\n", yylineno, yytext, s);
}

int main(int argc, char* argv[]) {
    int i;
    c = new_context(yyerror);
/*
    if(argc >= 2) {
        yyin = fopen(argv[1], "r");

        for(i = 0; i < argc; i++) {
            if (!strcmp(argv[i], "-o"))
                yyout = fopen(argv[++i], "w");
        }
    }
*/
    yyparse();

    return 0;
}
