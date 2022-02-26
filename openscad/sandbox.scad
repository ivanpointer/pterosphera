
* hull() {
    translate([0, -1, 0]) rotate([-15,0,0]) cube(3,center=true);
    rotate([0,0,90]) translate([0, -1, 0]) rotate([-15,0,0]) cube(3,center=true);
}

hull() {
    polyhedron(points = [
        [-.5,0,0],
        [-.5,3,0],
        [0,3,3],
        [0,0,3],

        [0,-.5,0],
        [3,-.5,0],
        [3,0,3],

        [3,3,3],
        [3,3,0],
        [0,0,0]
    ], faces = [
        [0,1,2,3],
        [4,5,6,3],
        [2,3,6,7],
        [0,1,4,5,8]
    ]);
}