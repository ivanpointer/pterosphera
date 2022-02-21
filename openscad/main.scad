use <switches/mx.scad>
use <trackball/trackball_socket.scad>
use <bodies/col_arc.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

$pdebug = true;

// Enable debug coloring
$dcolor = $pdebug;

// Center the models
center = false;

// Render!!
pinky_R = 41.5;
home_row = 3;
switch_col_arc(4, home_row, pinky_R);
