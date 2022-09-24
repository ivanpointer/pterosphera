#include "kmx.h"

// Reads the next row of switches, reporting state changes to the given reporter.
void kmx_nextRow(kmx_key_reporter reporter) {
    kmx_key k;
    k.coord.inIx = 4;
    k.coord.outIx = 2;
    k.state = DOWN;
    (*reporter)(k);
}
