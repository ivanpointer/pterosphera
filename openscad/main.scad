include <switches/mx.scad>
use <trackball/trackball_socket.scad>
include <bodies/col_arc_2.scad>
include <BOSL2/std.scad>
include <lib/utils.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

// Show/hide debug queues
debug = true;

// Which row (from the top) is considered the home row
home_row = 3;

// The right hand column definitions
hand_right = [
    // X offset, radius, columns, rows
        [ 49.8, 48.2, 2, 4 ], // Index
        [ 53.2, 55.0, 1, 5 ], // Middle
        [ 51.0, 51.5, 1, 5 ], // Ring
        [ 38.1, 41.5, 2, 4 ]  // Pinky
    ];

// MAIN
module main() { 
    // Render the whole thing
    keyboardHalf(hand_right,debug);

    // Render just one finger (for dev)
    // keyboardHalf([hand_right[0]], debug);
} main();

// Render the given half of the keyboard
module keyboardHalf(h,debug=false) {
    // Work some math about the shape of the end result
    cv = switch_col_args(h,home_row);
    allPoints = allDishPoints(cv);
    bp = boundingPair(allPoints);

    // Render!!
    for(ci=[0:len(cv)-1]) {
        switch_col_arc(cv[ci], ci < len(cv)-1 ? cv[ci+1] : [], bp, debug);
    }
}

// Get all points for the main switch area for the board
function allDishPoints(v,i=0) = i < len(v) -1
    ? concat_mx([all_finger_points(v[i]), allDishPoints(v,i+1)])
    : all_finger_points(v[i]);
function all_finger_points(m,i=0) = i < len(m) - 1 ? concat_mx([all_col_pts(m[0],m[1],m[2],m[3],m[4]), all_finger_points(m,i+1)]) : all_col_pts(m[0],m[1],m[2],m[3],m[4]);

// Generate the arguments expected by the column arc methods, with the proper offsets
function switch_col_args(h,o) = [
    for(fi=[0:len(h)-1])
        for(c=[0:h[fi][2]-1])
    [ h[fi][3], o, h[fi][1], h[fi][0], y_offset(h,fi,c), c + 1, h[fi][2] ]
];

// Work out the proper offset for the given column
function y_offset(h,fi,c) = ((col_no(h,fi) + c) * -mx_socket_perim_W) - ((fi > 0 ? finger_col_offset : 0) * fi);

// Recursive function to work out the column number, based on the profile set (some fingers get more than one column, and the matrix's first dimension is based on fingers)
function col_no(v,x,n=0) =  n > x - 1 ? 0 : v[n][2] + col_no(v,x,n+1);
