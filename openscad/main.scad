include <switches/mx.scad>
use <trackball/trackball_socket.scad>
use <bodies/col_arc_2.scad>
include <BOSL2/std.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

// Enable debug coloring
$dcolor = true;

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

o = function(v,x,n=0) n > x - 1 ? 0 : v[n][2] + o(v,x,n+1);

for(fi=[0:len(hand_right)-1]) {
    f=hand_right[fi];
    for(c=[0:f[2]-1]) {
        of = o(hand_right,fi);
        translate([f[0], (of + c) * -mx_socket_perim_W, 0])
            switch_col_arc(f[3], home_row, f[1], debug = false);
    }
}