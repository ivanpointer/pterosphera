include <switches/mx.scad>
use <trackball/trackball_socket.scad>
use <bodies/col_arc.scad>
include <BOSL2/std.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

// Enable debug coloring
$dcolor = true;

// Center the models
center = false;

// Render!!
pinky_R = 41.5;
home_row = 3;
switch_col_arc(4, home_row, pinky_R, debug = false);

//trackball_socket();


