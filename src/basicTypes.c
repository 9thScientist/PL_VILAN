#include "basicTypes.h"

Variable initInteger(char name[], int position) {
    Variable v = malloc (sizeof(struct variable));

    strcpy(v->name, name);
    v->position = position;
    v->size = 1;
    v->type = INT;

    return v;
}

Variable initArray(char name[], int size, int position) {
    Variable v = malloc(sizeof(struct variable));

    strcpy(v->name, name);
    v->size = size;
    v->position = position;
    v->type = ARRAY;

    return v;
}

void freeVariable(Variable v) {
    free(v);
}
