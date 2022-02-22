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

f_o = function(v,x,n=0) n > x - 1 ? 0 : v[n][2] + f_o(v,x,n+1);
f_yo = function(h,fi,c) ((f_o(h,fi) + c) * -mx_socket_perim_W) - ((fi > 0 ? finger_col_offset : 0) * fi);
o = home_row;
f_sca = function(h) [
    for(fi=[0:len(h)-1])
        for(c=[0:h[fi][2]-1])
            [ h[fi][3], o, h[fi][1], h[fi][0], f_yo(h,fi,c), c ] ];

cv = f_sca(hand_right);
for(ci=[0:len(cv)-1]) {
    switch_col_arc(cv[ci], ci > 0 ? cv[ci-1] : [], debug);
}

/*for(fi=[0:len(hand_right)-1]) {
    f=hand_right[fi];
    for(c=[0:f[2]-1]) {
        of = f_o(hand_right,fi);
        exof = fi > 0 ? finger_col_offset : 0;
        pv = fi > 0 ? hand_right[fi-1] : [];
        xof = f[0];
        yof = ((of + c) * -mx_socket_perim_W) - (exof * fi);
        switch_col_arc(f[3], home_row, f[1], pv, xof, yof, debug);*/

// ((of + c) * -mx_socket_perim_W) - (exof * fi)

// for(fi=[0:len(hand_right)-1]) {
//     f=hand_right[fi];
//     for(c=[0:f[2]-1]) {
//         of = f_o(hand_right,fi);
//         exof = ;
//         pv = fi > 0 ? hand_right[fi-1] : [];
//         xof = f[0];
//         yof = ;
//         switch_col_arc(f[3], home_row, f[1], pv, xof, yof, debug);
//     }
// }