#include <stdlib.h>
#include <string.h>
#define STR_SIZE 100

typedef struct variable {
    char name[STR_SIZE];
    int position;
    int size;
    enum {INT, ARRAY} type;
}*Variable;

Variable initArray(char name[], int size, int position);
Variable initInteger(char name[], int position);

void freeVariable(Variable v);
