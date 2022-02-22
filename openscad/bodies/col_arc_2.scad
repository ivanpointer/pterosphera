include <../switches/mx.scad>
include <../BOSL2/std.scad>

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module switch_col_arc(n,o,r,pv,xof,yof,debug = false) {
    // Measurements
    //-  The step angle for each switch - calibrated to the touch-point of the finger.
    a = asin(mx_socket_perim_H / r);
    ao = 90 - ((o - 0.5) * a);
    echo("finger arc",a*(n-1));

    //-  The radius for top and bottom of the sockets
    rt = r + mx_switch_full_height - mx_socket_total_D;
    rb = rt + mx_socket_total_D;

    //-  The edges of the column
    y1 = 0 + yof;
    y2 = mx_socket_perim_W + yof;

    // Functions for generation
    spv_f = function(n) [
        sp_f(n,y1,rt), sp_f(n,y2,rt), sp_f(n,y1,rb), sp_f(n,y2,rb),
        sp_f(n+1,y1,rt), sp_f(n+1,y2,rt), sp_f(n+1,y1,rb), sp_f(n+1,y2,rb)
    ];
    sp_f = function(n,y,r) [ (cos((a*-n) - ao) * r) + xof, y, sin((a*-n) - ao) * r ];

    // Colors for debugging
    c = ["red","blue","green","purple", "yellow", "cyan", "white"];

    // Walk up, creating each switch plate
    for (i=[0:n-1]) {
        pts = spv_f(i);
        dcolor(c[i%len(c)],debug) hull() polyhedron(points = pts, faces = [
            [ 0,1,2,3 ],
            [ 4,5,6,7 ]
        ]);
    }

    // If there is a previous column to attach to, make the connection

}

