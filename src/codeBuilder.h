#ifndef CODEB
#define CODEB
#include "basicTypes.h"

typedef struct context *CONTEXT;

CONTEXT new_context();
int exists_var(CONTEXT c, char *var);
Variable get_var(CONTEXT c, char *var_name);
char* declare_int(CONTEXT c, char* var_name, char* value);
char* declare_array(CONTEXT c, char* arr_name, int size);
char* assign(CONTEXT c, char *var_name, char *value);
char* read_var(CONTEXT c, char* var_name);
char* push_var(CONTEXT c, char* var_name);
char* store_var(CONTEXT c, char* var_name);
char* if_then_else(CONTEXT c, char* cond, char* then_code, char* else_code);
char* for_code(CONTEXT c, char* init_for, char* code, char* end_for);
char* init_for_in(CONTEXT c, char* var_name);
char* end_for_in(CONTEXT c, char* iter_name, char* arr_name, char* steps);
char* end_for_to(CONTEXT c, char* iter_name, char* stop, char* steps);
char* operator(char *op);
char* print_str( char* str);
char* print_num();
char* error( char* err);

#endif
