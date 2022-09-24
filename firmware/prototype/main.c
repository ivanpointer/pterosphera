#include <stdio.h>
#include "main.h"
#include "keymatrix/kmx.h"

// Prints the given key to console
void reportKey(kmx_key k) {
    printf("Reporting Key: %ix%i %i\n", k.coord.inIx, k.coord.outIx, k.state);
}

// The main loop
int main() {
    kmx_nextRow(&reportKey);
    return 0;
}
