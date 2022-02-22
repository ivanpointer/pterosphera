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

r2d2 = 180 / PI;
function r2d(r) = r * r2d2;
