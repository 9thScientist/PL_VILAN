#include <stdio.h>
#include <glib.h>
#include "codeBuilder.h"

#define STR_SIZE 100

struct context {
    GTree* vars;
    int gp;
    int label;
    void (*cerror) (char*);
};

// Starts a new context
CONTEXT new_context(void (*cerror) (char*)) {
    CONTEXT c = malloc(sizeof(struct context));

    c->vars = g_tree_new((GCompareFunc) strcmp);
    c->gp = 0;
    c->label = 0;
    c->cerror = cerror;

    return c;
}

// Returns true if var exists in context c
int exists_var(CONTEXT c, char *var) {
    if (g_tree_lookup(c->vars, var) == NULL)
        return 0;
    return 1;
}

Variable get_var(CONTEXT c, char *var_name) {
    return g_tree_lookup(c->vars, var_name);
}

char* declare_int(CONTEXT c, char* var_name, char* value) {
    GString *str = g_string_new(NULL);
    Variable var;

    var = initInteger(var_name, c->gp++);
    g_tree_insert(c->vars, var->name, var);

    g_string_append_printf(str, "%s", value);

    return g_string_free(str, FALSE);
}

char* declare_array(CONTEXT c, char* arr_name, int size) {
    GString *str = g_string_new(NULL);
    Variable var;

    var = initArray(arr_name, size, c->gp);
    g_tree_insert(c->vars, var->name, var);

    g_string_append_printf(str, "\tpushn %d\n", size);

    c->gp += size;

    return g_string_free(str, FALSE);
}


// assigns val to variable called var_name
char* assign(CONTEXT c, char *var_name, char *value) {
    GString *str = g_string_new(NULL);
    Variable var = get_var(c, var_name);

    if (var == NULL) {
        g_string_append_printf(str, "Variable %s not declared.", var_name);
        c->cerror(g_string_free(str, FALSE));
        return NULL;
    }

    g_string_append_printf(str, "%s", value);
    g_string_append_printf(str, "\tstoreg %d\n", var->position);


    return g_string_free(str, FALSE);
}

// Reads stdin to var_name
// if var is INT, converts the stdin string to int
char* read_var(CONTEXT c, char* var_name) {
    GString *str = g_string_new(NULL);
    Variable var = get_var(c, var_name);

    g_string_append_printf(str, "\tread\n");

    if (var->type == INT)
        g_string_append_printf(str, "\tatoi\n");

    g_string_append_printf(str, "\tstoreg %d\n", var->position);

    return g_string_free(str, FALSE);
}

char* read_array(CONTEXT c, char* arr_name, char* index) {
    GString *str = g_string_new(NULL);
    Variable arr = get_var(c, arr_name);

    g_string_append_printf(str, "%s", push_array(c, arr_name, index));
    g_string_append_printf(str, "\tread\n");
    g_string_append_printf(str, "\tatoi\n");
    g_string_append_printf(str, "\tstoren\n");

    return g_string_free(str, FALSE);
}

char* push_array(CONTEXT c, char* arr_name, char* index) {
    GString *str = g_string_new(NULL);
    Variable arr = get_var(c, arr_name);

    g_string_append_printf(str, "\tpushgp\n");
    g_string_append_printf(str, "\tpushi %d\n", arr->position);
    g_string_append_printf(str, "\tpadd\n%s", index);

    return g_string_free(str, FALSE);
}

char* push_var(CONTEXT c, char* var_name) {
    GString *str = g_string_new(NULL);
    Variable var = get_var(c, var_name);

    if (var == NULL) {
        g_string_append_printf(str, "Variable %s not declared.", var_name);
        c->cerror(g_string_free(str, FALSE));
        return NULL;
    }

    g_string_append_printf(str, "\tpushg %d\n", var->position );

    return g_string_free(str, FALSE);
}

char* store_var(CONTEXT c, char* var_name) {
    GString *str = g_string_new(NULL);
    Variable var = get_var(c, var_name);

    if (var == NULL) {
        return NULL;
    }

    g_string_append_printf(str, "\tstoreg %d\n", var->position );

    return g_string_free(str, FALSE);
}

char* if_then_else(CONTEXT c, char* cond, char* then_code, char* else_code) {
    GString *str = g_string_new(NULL);
    c->label++;

    g_string_append_printf(str, "%s", cond);
    g_string_append_printf(str, "\tjz\nt%d:", c->label);
    g_string_append_printf(str, "%s", else_code);
    g_string_append_printf(str, "\tjump f%d\n", c->label);
    g_string_append_printf(str, "t%d:nop\n%s", c->label, then_code, c->label);
    g_string_append_printf(str, "f%d:nop\n", c->label);

    return g_string_free(str, FALSE);
}

char* for_code(CONTEXT c, char* init_for, char* code, char* end_for) {
    GString *str = g_string_new(NULL);

    g_string_append_printf(str, "%s", init_for);
    g_string_append_printf(str, "%s", code);
    g_string_append_printf(str, "%s", end_for);
    g_string_append_printf(str, "f%d: nop\n", c->label);

    return g_string_free(str, FALSE);
}

char* init_for_in(CONTEXT c, char* var_name, int value) {
    GString *str = g_string_new(NULL), *aux = g_string_new(NULL);
    char *asg;
    c->label++;

    g_string_append_printf(aux, "\tpushi %d\n", value);
    asg = assign(c, var_name, g_string_free(aux, FALSE));
    g_string_append_printf(str, "%s", asg);
    g_string_append_printf(str, "c%d:", c->label);

    return g_string_free(str, FALSE);
}

char* end_for_in(CONTEXT c, char* iter_name, char* arr_name, char* steps) {
    GString *str = g_string_new(NULL);
    Variable arr = get_var(c, arr_name);
    char *aux;

    //Increments iterator ( i += steps )
    aux = push_var(c, iter_name);

    g_string_append_printf(str, "%s", aux);
    g_string_append_printf(str, "%s", steps);
    g_string_append_printf(str, "\tadd\n%s", store_var(c, iter_name));
    free(aux);

    //Checks whether to break of the loop or not
    aux = push_var(c, iter_name);
    g_string_append_printf(str, "%s", aux);
    g_string_append_printf(str, "\tpushi %d\n", arr->size);
    g_string_append_printf(str, "\tsupeq\n\tjz c%d\n", c->label);

    return g_string_free(str, FALSE);
}

char* end_for_to(CONTEXT c, char* iter_name, char* stop, char* steps) {
    GString *str = g_string_new(NULL);
    char *aux;

    //Increments iterator ( i += steps )
    aux = push_var(c, iter_name);
    g_string_append_printf(str, "%s", aux);
    g_string_append_printf(str, "%s", steps);
    g_string_append_printf(str, "\tadd\n%s", store_var(c, iter_name));
    free(aux);

    //Checks whether to break of the loop or not
    aux = push_var(c, iter_name);
    g_string_append_printf(str, "%s", aux);
    g_string_append_printf(str, "%s", stop);
    g_string_append_printf(str, "\tsupeq\njz c%d\n", c->label);

    return g_string_free(str, FALSE);
}

// Arithmetic opeator
char* operatorA(CONTEXT c, char* left, char* op, char* right) {
    GString *str = g_string_new(NULL);

    g_string_append_printf(str, "%s", left);
    g_string_append_printf(str, "%s", right);

    if (!strcmp(op, "+"))
        g_string_append_printf(str, "\tadd\n");
    else if (!strcmp(op, "-"))
        g_string_append_printf(str, "\tsub\n");
    else if (!strcmp(op, "||"))
        g_string_append_printf(str, "\tadd\n");
    else
        c->cerror("Operador não reconhecido");


    return g_string_free(str, FALSE);
}

// Multiplicative opeator
char* operatorM(CONTEXT c, char* left, char* op, char* right) {
    GString *str = g_string_new(NULL);

    g_string_append_printf(str, "%s", left);
    g_string_append_printf(str, "%s", right);

    if (!strcmp(op, "*"))
        g_string_append_printf(str, "\tmul\n");
    else if (!strcmp(op, "/"))
        g_string_append_printf(str, "\tdiv\n");
    else if (!strcmp(op, "&&"))
        g_string_append_printf(str, "\tmul\n");
    else if (!strcmp(op, "%"))
        g_string_append_printf(str, "\tmod\n");
    else
        c->cerror("Operador não reconhecido");

    return g_string_free(str, FALSE);
}



char* operator(CONTEXT c, char *op) {
    GString *str = g_string_new(NULL);

    if (!strcmp(op, ">")) {
        g_string_append_printf(str, "\tsup\n");
    } else if (!strcmp(op, "<")) {
        g_string_append_printf(str, "\tinf\n");
    } else if (!strcmp(op, ">=")) {
        g_string_append_printf(str, "\tsupeq\n");
    } else if (!strcmp(op, "<=")) {
        g_string_append_printf(str, "\tinfeq\n");
    } else {
        c->cerror("Operador não reconhecido");
    }

    return g_string_free(str, FALSE);
}

char* print_str( char* string) {
	GString *str = g_string_new(NULL);

	g_string_append_printf(str, "\tpushs %s\n", string);
	g_string_append_printf(str, "\twrites\n");

	return g_string_free(str, FALSE);
}

char* print_num() {
	GString *str = g_string_new(NULL);

	g_string_append_printf(str, "\twritei\n");

	return g_string_free(str, FALSE);
}

char* error( char* err) {
	GString *str = g_string_new(NULL);

	g_string_append_printf(str, "\terr %s\n", err);

	return g_string_free(str, FALSE);
}
