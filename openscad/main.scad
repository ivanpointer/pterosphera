include <switches/mx.scad>
use <trackball/trackball_socket.scad>
use <bodies/col_arc_2.scad>
include <BOSL2/std.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

debug = true;

// Center the models
center = false;

// Render!!
home_row = 3;
finger_col_offset = 3; // An additional offset between each finger's columns

hand_right = [
    // X offset, radius, columns, rows
    [ 49.8, 48.2, 2, 4 ], // Index
    [ 53.2, 55.0, 1, 5 ], // Middle 
    [ 51.0, 51.5, 1, 5 ], // Ring
    [ 38.1, 41.5, 2, 4 ]  // Pinky
];

o = function(v,x,n=0) n > x - 1 ? 0 : v[n][2] + o(v,x,n+1);

for(fi=[0:len(hand_right)-1]) {
    f=hand_right[fi];
    for(c=[0:f[2]-1]) {
        of = o(hand_right,fi);
        exof = fi > 0 && c == 0 ? finger_col_offset : 0;
        pv = fi > 0 ? hand_right[fi-1] : [];
        xof = f[0];
        yof = ((of + c) * -mx_socket_perim_W) - (exof * fi);
        switch_col_arc(f[3], home_row, f[1], pv, xof, yof, debug);
    }
}