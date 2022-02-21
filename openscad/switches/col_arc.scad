include <mx.scad>

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module switch_col_arc(count, home_row, radius) {

    // Strategy: build the faces using two circles, one for the face of the switches, one for the back
    // render just the section of the two to create the "socket" base, then to cut out the socket bits from that (first the main hole, then add in the amoeba screw mounts, then cut the holes out of those).

    // Sum of interier angles for any polygon, where n = number of sides:
    // (n−2) × 180°

    // The mx_socket_perim_WH defines the minimum height (and width) of a face for cutting a socket hole into.

    //
    col_R = radius + mx_switch_full_height;
    
    // TODO: Plot points here, instead of using squares...
    //a = r2d(acos((mx_socket_perim_H ^ 2) / (2 * radius * mx_socket_perim_H)));
    a = asin(mx_socket_perim_H / col_R);
    echo("angle",a);
    ao = 90 + (a * (home_row - 1)) + (a / 2);
    e = tan(a) * mx_socket_perim_H;
    c = ["red", "blue", "green", "yellow", "purple"];

    apx = _arc_of_points_x([],count+1,0,a,ao,col_R);
    apy = _arc_of_points_y([],count+1,0,a,ao,col_R);
    echo(apx);
    echo(apy);

    for (i = [0:count]) {
        color(c[i]) translate([apx[i], 0, apy[i]]) sphere(2);
        if (i < count) {
            echo(dist([apx[i],apy[i]],[apx[i+1],apy[i+1]]));
        }
        //translate([i.x, i.y, i.z]) sphere(1);
        //back(i * mx_socket_perim_H) up(i * e) xrot(i * a) square(mx_socket_perim_WH, center = false);
    }
}

function _arc_of_points_x(v,n,i,a,ao,r) = i < n - 1 ? concat(_arc_of_points_xn(v[i],i,a,ao,r), _arc_of_points_x(v,n,i + 1,a,ao,r)) : _arc_of_points_xn(v[i],i,a,ao,r);
function _arc_of_points_y(v,n,i,a,ao,r) = i < n - 1 ? concat(_arc_of_points_yn(v[i],i,a,ao,r), _arc_of_points_y(v,n,i + 1,a,ao,r)) : _arc_of_points_yn(v[i],i,a,ao,r);

function _arc_of_points_xn(p,i,a,ao,r) = cos((a*(i+1)) - ao) * r;
function _arc_of_points_yn(p,i,a,ao,r) = sin((a*(i+1)) - ao) * r;

function dist(p1,p2) = ((((p2.x - p1.x) ^ 2) + ((p2.y - p1.y) ^ 2)) ^ 0.5);
