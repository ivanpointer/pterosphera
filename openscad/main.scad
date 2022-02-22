include <switches/mx.scad>
use <trackball/trackball_socket.scad>
include <bodies/col_arc_2.scad>
include <BOSL2/std.scad>

main();

module main() {
    // Model definition - the higher the more faces/smooth
    $fn = 360 / 20; // degrees per face

    debug = true;

    // Center the models
    center = false;

    // Render!!
    home_row = 3;

    hand_right = [
        // X offset, radius, columns, rows
            [ 49.8, 48.2, 2, 4 ], // Index
            [ 53.2, 55.0, 1, 5 ], // Middle
            [ 51.0, 51.5, 1, 5 ], // Ring
            [ 38.1, 41.5, 2, 4 ]  // Pinky
        ];

    cv = swith_col_args(hand_right,home_row);
    for(ci=[0:len(cv)-1]) {
        switch_col_arc(cv[ci], ci < len(cv)-1 ? cv[ci+1] : [], debug);
    }
}

function swith_col_args(h,o) = [
    for(fi=[0:len(h)-1])
        for(c=[0:h[fi][2]-1])
    [ h[fi][3], o, h[fi][1], h[fi][0], y_offset(h,fi,c), c + 1, h[fi][2] ]
];
function y_offset(h,fi,c) = ((col_no(h,fi) + c) * -mx_socket_perim_W) - ((fi > 0 ? finger_col_offset : 0) * fi);
function col_no(v,x,n=0) =  n > x - 1 ? 0 : v[n][2] + col_no(v,x,n+1);
