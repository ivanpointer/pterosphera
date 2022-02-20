use <switches/mx.scad>
use <trackball/trackball_socket.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

// Enable debug coloring
$dcolor = false;

// Center the models
center = true;

// Render!!

mx_socket(center);
