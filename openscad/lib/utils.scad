// Utils/Helpers
include <../BOSL2/transforms.scad>

module center_if(width, height, depth, cond = false) {
    if (cond) {
        center(width, height, depth) children();
    } else {
        children();
    }
}

module center(width, height, depth) {
    left(width / 2) fwd(height / 2) down(depth / 2) children();
}

module back_if(dist, cond = false) {
    if (cond) {
        back(dist) children();
    } else {
        children();
    }
}

module fwd_if(dist, cond = false) {
    if (cond) {
        fwd(dist) children();
    } else {
        children();
    }
}

module right_if(dist, cond = false) {
    if (cond) {
        right(dist) children();
    } else {
        children();
    }
}

module up_if(dist, cond = false) {
    if (cond) {
        up(dist) children();
    } else {
        children();
    }
}

module down_if(dist, cond = false) {
    if (cond) {
        down(dist) children();
    } else {
        children();
    }
}

$dcolor = false;
module dcolor(c,debug=false) {
    if ($dcolor || debug) {
        color(c) children();
    } else {
        children();
    }
}

// Radian conversion
r2d2 = 180 / PI;
function r2d(r) = r * r2d2;

// Join matricies together
function concat_mx(m) = [ for(i=m) for(j=i) j ];

// Helpers for finding the highest coordinates within matrices
OUTER_LOW = 0;
OUTER_HIGH = 1;

// Two points, top back left, and bottom back right - defining all bounds of a matrix of points
function boundingPair(m) = [
        [ outerX(m,c=OUTER_LOW).x, outerY(m,c=OUTER_LOW).y, outerZ(m,c=OUTER_LOW).z ], // Bottom-front-left
        [ outerX(m,c=OUTER_HIGH).x, outerY(m,c=OUTER_HIGH).y, outerZ(m,c=OUTER_HIGH).z ] // Top-back-right
];

function bounding_coords(m) = [ bounding_coordsC(m,c=OUTER_HIGH), bounding_coordsC(m,c=OUTER_LOW) ];
function bounding_coordsC(m,c) = [ outerX(m,c=c),outerY(m,c=c),outerZ(m,c=c) ];

function outerX(m,c=OUTER_HIGH) = outerQ(m,0,c=c);
function outerY(m,c=OUTER_HIGH) = outerQ(m,1,c=c);
function outerZ(m,c=OUTER_HIGH) = outerQ(m,2,c=c);
function outerQ(m,q,c=OUTER_HIGH,i=0) = i < len(m) - 1 ? _c(m[i],outerQ(m,q,c,i+1),q,c) : m[i];
function _c(crnt,chlng,q,c=OUTER_HIGH) = c == OUTER_HIGH
    ? (crnt[q] > chlng[q] ? crnt : chlng)
    : (crnt[q] < chlng[q] ? crnt : chlng);


module plotPoints(points,clr="blue",offsets=[0,0,0]) {
    color(clr) for(p=[0:len(points)-1]) translate([points[p].x + offsets.x, points[p].y + offsets.y, points[p].z + offsets.z]) {
        text3d(str(p),0.2,1);
        sphere(0.1);
    }
}
