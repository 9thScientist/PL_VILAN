%{
#include <stdio.h>

void yyerror(char* );
int yylex();
%}
%token DECLARE BEGN END INT ARRAY PRINT READ FOR IN TO STEP ENDFOR IF THEN ELSE ENDIF NUM STR VAR OPB
%union { char* s; int i; struct { char* name; int value; } var; }
%type <s> STR
%type <var> VAR
%type <i> NUM
%type <i> numval 
%type <i> assign
%type <i> list
%type <s> OPB
%%
vilan: DECLARE dec BEGN code END
     ;

dec: initvar dec
   |
   ;

initvar: INT VAR		{ printf("INT %s\n", $2.name); }
       | ARRAY NUM VAR
       ;

code: assign code 
    | for code
    | if code
    | PRINT STR code
    | 
    ;

assign: VAR '=' assign		{ $$ = $1.value; }
      | VAR '=' list		{ $$ = $1.value; } 
      | VAR '=' READ		{ $$ = $1.value; }
      | numval
      ;

numval: '(' numval '+' numval ')' { $$ = $2; }
      | '(' numval '-' numval ')' { $$ = $2; }
      | '(' numval '*' numval ')' { $$ = $2; }
      | '(' numval '/' numval ')' { $$ = $2; }
      | '(' numval ')'		{ $$ = $2; }
      | NUM
      | VAR			{ $$ = $1.value; }
      ;

list: '[' listval ']' 		{ $$ = 0; }
    ;

listval: numval ',' listval
       | numval
       |
       ;

for: initfor code ENDFOR
   ;

initfor: FOR VAR IN VAR steps
       | FOR VAR TO numval steps
       ;

steps: STEP numval
     |
     ;

if: IF cond THEN code ENDIF
  | IF cond THEN code ELSE code ENDIF
  ;

cond: '(' cond OPB cond ')'
    | '(' cond ')'
    | NUM 
    ;
%%
#include "lex.yy.c"

void yyerror (char *s) {
    fprintf(stderr, "%d: %s\n\t%s\n", yylineno, yytext, s);
}

int main(int argc, char* argv[]) {
    yyparse();

    return 0;
}
