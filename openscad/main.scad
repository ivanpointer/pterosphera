use <switches/mx.scad>
use <trackball/trackball_socket.scad>
use <switches/col_arc.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

// Enable debug coloring
$dcolor = false;

// Center the models
center = false;

// Render!!
pinky_R = 41.5;
home_row = 3;
switch_col_arc(4, home_row, pinky_R);