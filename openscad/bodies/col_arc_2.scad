include <../switches/mx.scad>
include <../BOSL2/std.scad>

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module switch_col_arc(a,pa,debug = false) {
    // pv,n,o,r,xof,yof
    // Grab our arguments
    n = a[0];
    o = a[1];
    r = a[2];
    xof = a[3];
    yof = a[4];
    c = a[5];

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
    f_spv = function(n) [
        f_sp(n,y1,rt), f_sp(n,y2,rt), f_sp(n,y1,rb), f_sp(n,y2,rb),
        f_sp(n+1,y1,rt), f_sp(n+1,y2,rt), f_sp(n+1,y1,rb), f_sp(n+1,y2,rb)
    ];
    f_sp = function(n,y,r) [ (cos((a*-n) - ao) * r) + xof, y, sin((a*-n) - ao) * r ];

    // Colors for debugging
    clr = ["red","blue","green","purple", "yellow", "cyan", "white"];

    // Walk up, creating each switch plate
    for (i=[0:n-1]) {
        dcolor(clr[i%len(clr)],debug) {
            pts = f_spv(i);
            hull() polyhedron(points = pts, faces = [
                [ 0,1,2,3 ],
                [ 4,5,6,7 ]
            ]);

            // If there is a previous column to attach to, make the connection
            if (c == 0 && len(pa) > 0) {
                n2 = pa[0];
                if (i < n2) {
                    y3 = pa[4];

                    r2 = pa[2];
                    rt2 = r2 + mx_switch_full_height - mx_socket_total_D;
                    rb2 = rt2 + mx_socket_total_D;
                    a2 = asin(mx_socket_perim_H / r2);
                    ao2 = 90 - ((pa[1] - 0.5) * a2);

                    f_sp_2 = function(n,y,r) [ (cos((a2*-n) - ao2) * r) + pa[3], y, sin((a2*-n) - ao2) * r ];

                    join_points = [
                        f_sp(i,y2,rt), f_sp(i+1,y2,rt), f_sp(i+1,y2,rb), f_sp(i,y2,rb),
                        f_sp(i,y3,rt2), f_sp(i+1,y3,rt2), f_sp(i+1,y3,rb2), f_sp(i,y3,rb2)
                    ];
                    join_faces = [
                        [ 0,1,2,3 ],
                        [ 4,5,6,7 ]
                    ];
                    echo("points",join_points);
                    echo("faces",join_faces);
                    hull() polyhedron(points = join_points, faces = join_faces);

                    * for(p=join_points) translate(p) sphere(2);
                }
            }
        }
    }
}