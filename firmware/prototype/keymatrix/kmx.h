//
// Created by Ivan Pointer on 9/24/22.
//

// Note that the orientation of the matrix may be rows-out-cols-in or cols-out-rows-in, depending on the physical board;
// this matrix should be agnostic of this orientation.

#ifndef PROTOTYPE_KMX_H
#define PROTOTYPE_KMX_H

#include <stdint.h>
#include "../main.h"

// The various state of a physical key.
typedef enum kmx_keystate{DOWN, UP};

// The type used for the matrix indices.
typedef uint_fast8_t kmx_int;

// The matrix holding the key states for the switches
typedef enum kmx_keystate kmx_matrix[KMX_ROWS][KMX_COLS];

// A coordinate within a keyboard matrix.
typedef struct kmx_coord {
    // The index within the matrix for the output (out toward the transistor that powers a set of switches).
    kmx_int outIx;

    // The index within the matrix for the input (in from the powered set of switches).
    kmx_int inIx;
} kmx_coord;

// Represents an individual key in the matrix, with its state, to be reported to the master.
typedef struct kmx_key {
    // The coordinate where the key resides.
    struct kmx_coord coord;

    // The reported state of the key.
    enum kmx_keystate state;
} kmx_key;

// A pointer to the function for reporting a key state change.
typedef void (*kmx_key_reporter)(kmx_key);

// Instructs to read the next row, and report any state changes to the given reporter function.
void kmx_nextRow(kmx_key_reporter);

#endif //PROTOTYPE_KMX_H
