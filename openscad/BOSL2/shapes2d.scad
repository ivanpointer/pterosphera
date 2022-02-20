//////////////////////////////////////////////////////////////////////
// LibFile: shapes2d.scad
//   This file includes redefinitions of the core modules to
//   work with attachment, and functional forms of those modules
//   that produce paths.  You can create regular polygons
//   with optional rounded corners and alignment features not
//   available with circle().  The file also provides teardrop2d,
//   which is useful for 3D printable holes.  
//   Many of the commands have module forms that produce geometry and
//   function forms that produce a path. 
// Includes:
//   include <BOSL2/std.scad>
// FileGroup: Basic Modeling
// FileSummary: Attachable circles, squares, polygons, teardrop.  Can make geometry or paths.
// FileFootnotes: STD=Included in std.scad
//////////////////////////////////////////////////////////////////////

use <builtins.scad>


// Section: 2D Primitives

// Function&Module: square()
// Topics: Shapes (2D), Path Generators (2D)
// Usage: As a Module
//   square(size, [center], ...);
// Usage: With Attachments
//   square(size, [center], ...) { attachables }
// Usage: As a Function
//   path = square(size, [center], ...);
// See Also: rect()
// Description:
//   When called as the builtin module, creates a 2D square or rectangle of the given size.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the square to create.  If given as a scalar, both X and Y will be the same size.
//   center = If given and true, overrides `anchor` to be `CENTER`.  If given and false, overrides `anchor` to be `FRONT+LEFT`.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D):
//   square(40);
// Example(2D): Centered
//   square([40,30], center=true);
// Example(2D): Called as Function
//   path = square([40,30], anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   move_copies(path) color("blue") circle(d=2,$fn=8);
function square(size=1, center, anchor, spin=0) =
    let(
        anchor = get_anchor(anchor, center, [-1,-1], [-1,-1]),
        size = is_num(size)? [size,size] : point2d(size),
        path = [
            [ size.x,-size.y],
            [-size.x,-size.y],
            [-size.x, size.y],
            [ size.x, size.y]
        ] / 2
    ) reorient(anchor,spin, two_d=true, size=size, p=path);


module square(size=1, center, anchor, spin) {
    anchor = get_anchor(anchor, center, [-1,-1], [-1,-1]);
    size = is_num(size)? [size,size] : point2d(size);
    attachable(anchor,spin, two_d=true, size=size) {
        _square(size, center=true);
        children();
    }
}



// Function&Module: rect()
// Usage: As Module
//   rect(size, [rounding], [chamfer], ...);
// Usage: With Attachments
//   rect(size, ...) { attachables }
// Usage: As Function
//   path = rect(size, [rounding], [chamfer], ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: square()
// Description:
//   When called as a module, creates a 2D rectangle of the given size, with optional rounding or chamfering.
//   When called as a function, returns a 2D path/list of points for a square/rectangle of the given size.
// Arguments:
//   size = The size of the rectangle to create.  If given as a scalar, both X and Y will be the same size.
//   rounding = The rounding radius for the corners.  If negative, produces external roundover spikes on the X axis. If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   chamfer = The chamfer size for the corners.  If negative, produces external chamfer spikes on the X axis. If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D):
//   rect(40);
// Example(2D): Anchored
//   rect([40,30], anchor=FRONT);
// Example(2D): Spun
//   rect([40,30], anchor=FRONT, spin=30);
// Example(2D): Chamferred Rect
//   rect([40,30], chamfer=5);
// Example(2D): Rounded Rect
//   rect([40,30], rounding=5);
// Example(2D): Negative-Chamferred Rect
//   rect([40,30], chamfer=-5);
// Example(2D): Negative-Rounded Rect
//   rect([40,30], rounding=-5);
// Example(2D): Mixed Chamferring and Rounding
//   rect([40,30],rounding=[5,0,10,0],chamfer=[0,8,0,15],$fa=1,$fs=1);
// Example(2D): Called as Function
//   path = rect([40,30], chamfer=5, anchor=FRONT, spin=30);
//   stroke(path, closed=true);
//   move_copies(path) color("blue") circle(d=2,$fn=8);
module rect(size=1, rounding=0, chamfer=0, anchor=CENTER, spin=0) {
    size = is_num(size)? [size,size] : point2d(size);
    if (rounding==0 && chamfer==0) {
        attachable(anchor, spin, two_d=true, size=size) {
            square(size, center=true);
            children();
        }
    } else {
        pts = rect(size=size, rounding=rounding, chamfer=chamfer);
        attachable(anchor, spin, two_d=true, path=pts) {
            polygon(pts);
            children();
        }
    }
}



function rect(size=1, rounding=0, chamfer=0, anchor=CENTER, spin=0) =
    assert(is_num(size)     || is_vector(size))
    assert(is_num(chamfer)  || len(chamfer)==4)
    assert(is_num(rounding) || len(rounding)==4)
    let(
        anchor=point2d(anchor),
        size = is_num(size)? [size,size] : point2d(size),
        complex = rounding!=0 || chamfer!=0
    )
    (rounding==0 && chamfer==0)? let(
        path = [
            [ size.x/2, -size.y/2],
            [-size.x/2, -size.y/2],
            [-size.x/2,  size.y/2],
            [ size.x/2,  size.y/2] 
        ]
    )
    rot(spin, p=move(-v_mul(anchor,size/2), p=path)) :
    let(
        chamfer = is_list(chamfer)? chamfer : [for (i=[0:3]) chamfer],
        rounding = is_list(rounding)? rounding : [for (i=[0:3]) rounding],
        quadorder = [3,2,1,0],
        quadpos = [[1,1],[-1,1],[-1,-1],[1,-1]],
        eps = 1e-9,
        insets = [for (i=[0:3]) abs(chamfer[i])>=eps? chamfer[i] : abs(rounding[i])>=eps? rounding[i] : 0],
        insets_x = max(insets[0]+insets[1],insets[2]+insets[3]),
        insets_y = max(insets[0]+insets[3],insets[1]+insets[2])
    )
    assert(insets_x <= size.x, "Requested roundings and/or chamfers exceed the rect width.")
    assert(insets_y <= size.y, "Requested roundings and/or chamfers exceed the rect height.")
    let(
        path = [
            for(i = [0:3])
            let(
                quad = quadorder[i],
                qinset = insets[quad],
                qpos = quadpos[quad],
                qchamf = chamfer[quad],
                qround = rounding[quad],
                cverts = quant(segs(abs(qinset)),4)/4,
                step = 90/cverts,
                cp = v_mul(size/2-[qinset,abs(qinset)], qpos),
                qpts = abs(qchamf) >= eps? [[0,abs(qinset)], [qinset,0]] :
                    abs(qround) >= eps? [for (j=[0:1:cverts]) let(a=90-j*step) v_mul(polar_to_xy(abs(qinset),a),[sign(qinset),1])] :
                    [[0,0]],
                qfpts = [for (p=qpts) v_mul(p,qpos)],
                qrpts = qpos.x*qpos.y < 0? reverse(qfpts) : qfpts
            )
            each move(cp, p=qrpts)
        ]
    ) complex?
        reorient(anchor,spin, two_d=true, path=path, p=path) :
        reorient(anchor,spin, two_d=true, size=size, p=path);


// Function&Module: circle()
// Topics: Shapes (2D), Path Generators (2D)
// Usage: As a Module
//   circle(r|d=, ...);
// Usage: With Attachments
//   circle(r|d=, ...) { attachables }
// Usage: As a Function
//   path = circle(r|d=, ...);
// See Also: ellipse(), circle_2tangents(), circle_3points()
// Description:
//   When called as the builtin module, creates a 2D polygon that approximates a circle of the given size.
//   When called as a function, returns a 2D list of points (path) for a polygon that approximates a circle of the given size.
// Arguments:
//   r = The radius of the circle to create.
//   d = The diameter of the circle to create.
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): By Radius
//   circle(r=25);
// Example(2D): By Diameter
//   circle(d=50);
// Example(NORENDER): Called as Function
//   path = circle(d=50, anchor=FRONT, spin=45);
function circle(r, d, anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        sides = segs(r),
        path = [for (i=[0:1:sides-1]) let(a=360-i*360/sides) r*[cos(a),sin(a)]]
    ) reorient(anchor,spin, two_d=true, r=r, p=path);

module circle(r, d, anchor=CENTER, spin=0) {
    r = get_radius(r=r, d=d, dflt=1);
    attachable(anchor,spin, two_d=true, r=r) {
        _circle(r=r);
        children();
    }
}



// Function&Module: ellipse()
// Usage: As a Module
//   ellipse(r|d=, [realign=], [circum=], ...);
// Usage: With Attachments
//   ellipse(r|d=, [realign=], [circum=], ...) { attachables }
// Usage: As a Function
//   path = ellipse(r|d=, [realign=], [circum=], ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), circle_2tangents(), circle_3points()
// Description:
//   When called as a module, creates a 2D polygon that approximates a circle or ellipse of the given size.
//   When called as a function, returns a 2D list of points (path) for a polygon that approximates a circle or ellipse of the given size.
//   By default the point list or shape is the same as the one you would get by scaling the output of {{circle()}}, but with this module your
//   attachments to the ellipse will retain their dimensions, whereas scaling a circle with attachments will also scale the attachments.
//   If you set unifom to true then you will get a polygon with congruent sides whose vertices lie on the ellipse.  
// Arguments:
//   r = Radius of the circle or pair of semiaxes of ellipse 
//   ---
//   d = Diameter of the circle or a pair giving the full X and Y axis lengths.  
//   realign = If false starts the approximate ellipse with a point on the X+ axis.  If true the midpoint of a side is on the X+ axis and the first point of the polygon is below the X+ axis.  This can result in a very different polygon when $fn is small.  Default: false
//   circum = If true, the polygon that approximates the circle will be upsized slightly to circumscribe the theoretical circle.  If false, it inscribes the theoretical circle.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D): By Radius
//   ellipse(r=25);
// Example(2D): By Diameter
//   ellipse(d=50);
// Example(2D): Anchoring
//   ellipse(d=50, anchor=FRONT);
// Example(2D): Spin
//   ellipse(d=50, anchor=FRONT, spin=45);
// Example(NORENDER): Called as Function
//   path = ellipse(d=50, anchor=FRONT, spin=45);
// Example(2D,NoAxes): Uniformly sampled hexagon at the top, regular non-uniform one at the bottom
//   r=[10,3];
//   ydistribute(7){
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6)],width=0.1,color="red");
//     }
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6,uniform=true)],width=0.1,color="red");
//     }
//   }
// Example(2D): The realigned hexagons are even more different
//   r=[10,3];
//   ydistribute(7){
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6,realign=true)],width=0.1,color="red");
//     }
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//       stroke([ellipse(r=r, $fn=6,realign=true,uniform=true)],width=0.1,color="red");
//     }
//   }
// Example(2D): For odd $fn the result may not look very elliptical:
//    r=[10,3];
//    ydistribute(7){
//      union(){
//        stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//        stroke([ellipse(r=r, $fn=5,realign=false)],width=0.1,color="red");
//      }
//      union(){
//        stroke([ellipse(r=r, $fn=100)],width=0.05,color="blue");
//        stroke([ellipse(r=r, $fn=5,realign=false,uniform=true)],width=0.1,color="red");
//      }
//    }
// Example(2D): The same ellipse, turned 90 deg, gives a very different result:
//   r=[3,10];
//   xdistribute(7){
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.1,color="blue");
//       stroke([ellipse(r=r, $fn=5,realign=false)],width=0.2,color="red");
//     }
//     union(){
//       stroke([ellipse(r=r, $fn=100)],width=0.1,color="blue");
//       stroke([ellipse(r=r, $fn=5,realign=false,uniform=true)],width=0.2,color="red");
//     }
//   }
module ellipse(r, d, realign=false, circum=false, uniform=false, anchor=CENTER, spin=0)
{
    r = force_list(get_radius(r=r, d=d, dflt=1),2);
    dummy = assert(is_vector(r,2) && all_positive(r), "Invalid radius or diameter for ellipse");
    sides = segs(max(r));
    sc = circum? (1 / cos(180/sides)) : 1;
    rx = r.x * sc;
    ry = r.y * sc;
    attachable(anchor,spin, two_d=true, r=[rx,ry]) {
        if (uniform) {
            assert(!circum, "Circum option not allowed when \"uniform\" is true");
            polygon(ellipse(r,realign=realign, circum=circum, uniform=true));
        }
        else if (rx < ry) {
            xscale(rx/ry) {
                zrot(realign? 180/sides : 0) {
                    circle(r=ry, $fn=sides);
                }
            }
        } else {
            yscale(ry/rx) {
                zrot(realign? 180/sides : 0) {
                    circle(r=rx, $fn=sides);
                }
            }
        }
        children();
    }
}


// Iterative refinement to produce an inscribed polygon
// in an ellipse whose side lengths are all equal
function _ellipse_refine(a,b,N, _theta=[]) =
   len(_theta)==0? _ellipse_refine(a,b,N,lerpn(0,360,N,endpoint=false))
   :
   let(
       pts = [for(t=_theta) [a*cos(t),b*sin(t)]],
       lenlist= path_segment_lengths(pts,closed=true),
       meanlen = mean(lenlist),
       error = lenlist/meanlen
   )
   all_equal(error,EPSILON) ? pts
   :
   let(
        dtheta = [each deltas(_theta),
                  360-last(_theta)],
        newdtheta = [for(i=idx(dtheta)) dtheta[i]/error[i]],
        adjusted = [0,each cumsum(list_head(newdtheta / sum(newdtheta) * 360))]
   )
   _ellipse_refine(a,b,N,adjusted);




function _ellipse_refine_realign(a,b,N, _theta=[],i=0) =
   len(_theta)==0?
         _ellipse_refine_realign(a,b,N, count(N-1,180/N,360/N))
   :
   let(
       pts = [for(t=_theta) [a*cos(t),b*sin(t)],
              [a*cos(_theta[0]), -b*sin(_theta[0])]],
       lenlist= path_segment_lengths(pts,closed=true),
       meanlen = mean(lenlist),
       error = lenlist/meanlen
   )
   all_equal(error,EPSILON) ? pts
   :
   let(
        dtheta = [each deltas(_theta),
                  360-last(_theta)-_theta[0],
                  2*_theta[0]],
        newdtheta = [for(i=idx(dtheta)) dtheta[i]/error[i]],
        normdtheta = newdtheta / sum(newdtheta) * 360,
        adjusted = cumsum([last(normdtheta)/2, each list_head(normdtheta, -3)])
   )
   _ellipse_refine_realign(a,b,N,adjusted, i+1);



function ellipse(r, d, realign=false, circum=false, uniform=false, anchor=CENTER, spin=0) =
    let(
        r = force_list(get_radius(r=r, d=d, dflt=1),2),
        sides = segs(max(r))
    )
    uniform ? assert(!circum, "Circum option not allowed when \"uniform\" is true")
                 reorient(anchor,spin,two_d=true,r=[r.x,r.y],
                          p=realign ? reverse(_ellipse_refine_realign(r.x,r.y,sides))
                                    : reverse_polygon(_ellipse_refine(r.x,r.y,sides)))
    :
    let(
        offset = realign? 180/sides : 0,
        sc = circum? (1 / cos(180/sides)) : 1,
        rx = r.x * sc,
        ry = r.y * sc,
        pts = [for (i=[0:1:sides-1]) let(a=360-offset-i*360/sides) [rx*cos(a), ry*sin(a)]]
    ) reorient(anchor,spin, two_d=true, r=[rx,ry], p=pts);


// Section: Polygons

// Function&Module: regular_ngon()
// Usage:
//   regular_ngon(n, r/d=/or=/od=, [realign=]);
//   regular_ngon(n, ir=/id=, [realign=]);
//   regular_ngon(n, side=, [realign=]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), pentagon(), hexagon(), octagon(), ellipse(), star()
// Description:
//   When called as a function, returns a 2D path for a regular N-sided polygon.
//   When called as a module, creates a 2D regular N-sided polygon.
// Arguments:
//   n = The number of sides.
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0", "tip1", etc. = Each tip has an anchor, pointing outwards.
//   "side0", "side1", etc. = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   regular_ngon(n=5, or=30);
//   regular_ngon(n=5, od=60);
// Example(2D): by Inner Size
//   regular_ngon(n=5, ir=30);
//   regular_ngon(n=5, id=60);
// Example(2D): by Side Length
//   regular_ngon(n=8, side=20);
// Example(2D): Realigned
//   regular_ngon(n=8, side=20, realign=true);
// Example(2D): Alignment by Tip
//   regular_ngon(n=5, r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   regular_ngon(n=5, r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   regular_ngon(n=5, od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, regular_ngon(n=6, or=30));
function regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0, _mat, _anchs) =
    assert(is_undef(align_tip) || is_vector(align_tip))
    assert(is_undef(align_side) || is_vector(align_side))
    assert(is_undef(align_tip) || is_undef(align_side), "Can only specify one of align_tip and align-side")
    let(
        sc = 1/cos(180/n),
        ir = is_finite(ir)? ir*sc : undef,
        id = is_finite(id)? id*sc : undef,
        side = is_finite(side)? side/2/sin(180/n) : undef,
        r = get_radius(r1=ir, r2=or, r=r, d1=id, d2=od, d=d, dflt=side)
    )
    assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.")
    let(
        inset = opp_ang_to_hyp(rounding, (180-360/n)/2),
        mat = !is_undef(_mat) ? _mat :
            ( realign? zrot(-180/n) : ident(4)) * (
                !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
                !is_undef(align_side)? rot(from=RIGHT, to=point2d(align_side)) * zrot(180/n) :
                1
            ),
        path4 = rounding==0? ellipse(r=r, $fn=n) : (
            let(
                steps = floor(segs(r)/n),
                step = 360/n/steps,
                path2 = [
                    for (i = [0:1:n-1]) let(
                        a = 360 - i*360/n,
                        p = polar_to_xy(r-inset, a)
                    )
                    each arc(N=steps, cp=p, r=rounding, start=a+180/n, angle=-360/n)
                ],
                maxx_idx = max_index(column(path2,0)),
                path3 = list_rotate(path2,maxx_idx)
            ) path3
        ),
        path = apply(mat, path4),
        anchors = !is_undef(_anchs) ? _anchs :
            !is_string(anchor)? [] : [
            for (i = [0:1:n-1]) let(
                a1 = 360 - i*360/n,
                a2 = a1 - 360/n,
                p1 = apply(mat, polar_to_xy(r,a1)),
                p2 = apply(mat, polar_to_xy(r,a2)),
                tipp = apply(mat, polar_to_xy(r-inset+rounding,a1)),
                pos = (p1+p2)/2
            ) each [
                named_anchor(str("tip",i), tipp, unit(tipp,BACK), 0),
                named_anchor(str("side",i), pos, unit(pos,BACK), 0),
            ]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, p=path, anchors=anchors);


module regular_ngon(n=6, r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) {
    sc = 1/cos(180/n);
    ir = is_finite(ir)? ir*sc : undef;
    id = is_finite(id)? id*sc : undef;
    side = is_finite(side)? side/2/sin(180/n) : undef;
    r = get_radius(r1=ir, r2=or, r=r, d1=id, d2=od, d=d, dflt=side);
    assert(!is_undef(r), "regular_ngon(): need to specify one of r, d, or, od, ir, id, side.");
    mat = ( realign? zrot(-180/n) : ident(4) ) * (
            !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
            !is_undef(align_side)? rot(from=RIGHT, to=point2d(align_side)) * zrot(180/n) :
            1
        );
    inset = opp_ang_to_hyp(rounding, (180-360/n)/2);
    anchors = [
        for (i = [0:1:n-1]) let(
            a1 = 360 - i*360/n,
            a2 = a1 - 360/n,
            p1 = apply(mat, polar_to_xy(r,a1)),
            p2 = apply(mat, polar_to_xy(r,a2)),
            tipp = apply(mat, polar_to_xy(r-inset+rounding,a1)),
            pos = (p1+p2)/2
        ) each [
            named_anchor(str("tip",i), tipp, unit(tipp,BACK), 0),
            named_anchor(str("side",i), pos, unit(pos,BACK), 0),
        ]
    ];
    path = regular_ngon(n=n, r=r, rounding=rounding, _mat=mat, _anchs=anchors);
    attachable(anchor,spin, two_d=true, path=path, extent=false, anchors=anchors) {
        polygon(path);
        children();
    }
}


// Function&Module: pentagon()
// Usage:
//   pentagon(or|od=, [realign=]);
//   pentagon(ir=|id=, [realign=]);
//   pentagon(side=, [realign=]);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), hexagon(), octagon(), ellipse(), star()
// Description:
//   When called as a function, returns a 2D path for a regular pentagon.
//   When called as a module, creates a 2D regular pentagon.
// Arguments:
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip4" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side4" = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   pentagon(or=30);
//   pentagon(od=60);
// Example(2D): by Inner Size
//   pentagon(ir=30);
//   pentagon(id=60);
// Example(2D): by Side Length
//   pentagon(side=20);
// Example(2D): Realigned
//   pentagon(side=20, realign=true);
// Example(2D): Alignment by Tip
//   pentagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   pentagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   pentagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, pentagon(or=30));
function pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module pentagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=5, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: hexagon()
// Usage: As Module
//   hexagon(r/or, [realign=], <align_tip=|align_side=>, [rounding=], ...);
//   hexagon(d=/od=, ...);
//   hexagon(ir=/id=, ...);
//   hexagon(side=, ...);
// Usage: With Attachments
//   hexagon(r/or, ...) { attachments }
// Usage: As Function
//   path = hexagon(r/or, ...);
//   path = hexagon(d=/od=, ...);
//   path = hexagon(ir=/id=, ...);
//   path = hexagon(side=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), pentagon(), octagon(), ellipse(), star()
// Description:
//   When called as a function, returns a 2D path for a regular hexagon.
//   When called as a module, creates a 2D regular hexagon.
// Arguments:
//   r/or = Outside radius, at points.
//   ---
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip5" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side5" = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   hexagon(or=30);
//   hexagon(od=60);
// Example(2D): by Inner Size
//   hexagon(ir=30);
//   hexagon(id=60);
// Example(2D): by Side Length
//   hexagon(side=20);
// Example(2D): Realigned
//   hexagon(side=20, realign=true);
// Example(2D): Alignment by Tip
//   hexagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   hexagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   hexagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, hexagon(or=30));
function hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module hexagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=6, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: octagon()
// Usage: As Module
//   octagon(r/or, [realign=], <align_tip=|align_side=>, [rounding=], ...);
//   octagon(d=/od=, ...);
//   octagon(ir=/id=, ...);
//   octagon(side=, ...);
// Usage: With Attachments
//   octagon(r/or, ...) { attachments }
// Usage: As Function
//   path = octagon(r/or, ...);
//   path = octagon(d=/od=, ...);
//   path = octagon(ir=/id=, ...);
//   path = octagon(side=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), regular_ngon(), pentagon(), hexagon(), ellipse(), star()
// Description:
//   When called as a function, returns a 2D path for a regular octagon.
//   When called as a module, creates a 2D regular octagon.
// Arguments:
//   r/or = Outside radius, at points.
//   d/od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   rounding = Radius of rounding for the tips of the polygon.  Default: 0 (no rounding)
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first vertex points in that direction.  This occurs before spin.
//   align_side = If given as a 2D vector, rotates the whole shape so that the normal of side0 points in that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0" ... "tip7" = Each tip has an anchor, pointing outwards.
//   "side0" ... "side7" = The center of each side has an anchor, pointing outwards.
// Example(2D): by Outer Size
//   octagon(or=30);
//   octagon(od=60);
// Example(2D): by Inner Size
//   octagon(ir=30);
//   octagon(id=60);
// Example(2D): by Side Length
//   octagon(side=20);
// Example(2D): Realigned
//   octagon(side=20, realign=true);
// Example(2D): Alignment by Tip
//   octagon(r=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Side
//   octagon(r=30, align_side=BACK+RIGHT)
//       attach("side0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Rounded
//   octagon(od=100, rounding=20, $fn=20);
// Example(2D): Called as Function
//   stroke(closed=true, octagon(or=30));
function octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0) =
    regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin);


module octagon(r, d, or, od, ir, id, side, rounding=0, realign=false, align_tip, align_side, anchor=CENTER, spin=0)
    regular_ngon(n=8, r=r, d=d, or=or, od=od, ir=ir, id=id, side=side, rounding=rounding, realign=realign, align_tip=align_tip, align_side=align_side, anchor=anchor, spin=spin) children();


// Function&Module: right_triangle()
// Usage: As Module
//   right_triangle(size, [center], ...);
// Usage: With Attachments
//   right_triangle(size, [center], ...) { attachments }
// Usage: As Function
//   path = right_triangle(size, [center], ...);
// Description:
//   Creates a right triangle with the Hypotenuse in the X+Y+ quadrant.
// Arguments:
//   size = The width and length of the right triangle, given as a scalar or an XY vector.
//   center = If true, forces `anchor=CENTER`.  If false, forces `anchor=[-1,-1]`.  Default: undef (use `anchor=`)
//   ---
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Example(2D):
//   right_triangle([40,30]);
// Example(2D): With `center=true`
//   right_triangle([40,30], center=true);
// Example(2D): Anchors
//   right_triangle([40,30])
//       show_anchors();
function right_triangle(size=[1,1], center, anchor, spin=0) =
    let(
        size = is_num(size)? [size,size] : size,
        anchor = get_anchor(anchor, center, [-1,-1], [-1,-1])
    )
    assert(is_vector(size,2))
    let(
        path = [ [size.x/2,-size.y/2], [-size.x/2,-size.y/2], [-size.x/2,size.y/2] ]
    ) reorient(anchor,spin, two_d=true, size=[size.x,size.y], size2=0, shift=-size.x/2, p=path);

module right_triangle(size=[1,1], center, anchor, spin=0) {
    size = is_num(size)? [size,size] : size;
    anchor = get_anchor(anchor, center, [-1,-1], [-1,-1]);
    assert(is_vector(size,2));
    path = right_triangle(size, center=true);
    attachable(anchor,spin, two_d=true, size=[size.x,size.y], size2=0, shift=-size.x/2) {
        polygon(path);
        children();
    }
}


// Function&Module: trapezoid()
// Usage: As Module
//   trapezoid(h, w1, w2, [shift=], [rounding=], [chamfer=], ...);
//   trapezoid(h, w1, angle=, ...);
//   trapezoid(h, w2, angle=, ...);
//   trapezoid(w1, w2, angle=, ...);
// Usage: With Attachments
//   trapezoid(h, w1, w2, ...) { attachments }
// Usage: As Function
//   path = trapezoid(h, w1, w2, ...);
//   path = trapezoid(h, w1, angle=, ...);
//   path = trapezoid(h, w2=, angle=, ...);
//   path = trapezoid(w1=, w2=, angle=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: rect(), square()
// Description:
//   When called as a function, returns a 2D path for a trapezoid with parallel front and back sides.
//   When called as a module, creates a 2D trapezoid with parallel front and back sides.
// Arguments:
//   h = The Y axis height of the trapezoid.
//   w1 = The X axis width of the front end of the trapezoid.
//   w2 = The X axis width of the back end of the trapezoid.
//   ---
//   angle = If given in place of `h`, `w1`, or `w2`, then the missing value is calculated such that the right side has that angle away from the Y axis.
//   shift = Scalar value to shift the back of the trapezoid along the X axis by.  Default: 0
//   rounding = The rounding radius for the corners.  If given as a list of four numbers, gives individual radii for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-]. Default: 0 (no rounding)
//   chamfer = The Length of the chamfer faces at the corners.  If given as a list of four numbers, gives individual chamfers for each corner, in the order [X+Y+,X-Y+,X-Y-,X+Y-].  Default: 0 (no chamfer)
//   flip = If true, negative roundings and chamfers will point forward and back instead of left and right.  Default: `false`.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Examples(2D):
//   trapezoid(h=30, w1=40, w2=20);
//   trapezoid(h=25, w1=20, w2=35);
//   trapezoid(h=20, w1=40, w2=0);
//   trapezoid(h=20, w1=30, angle=30);
//   trapezoid(h=20, w1=20, angle=-30);
//   trapezoid(h=20, w2=10, angle=30);
//   trapezoid(h=20, w2=30, angle=-30);
//   trapezoid(w1=30, w2=10, angle=30);
// Example(2D): Chamfered Trapezoid
//   trapezoid(h=30, w1=60, w2=40, chamfer=5);
// Example(2D): Negative Chamfered Trapezoid
//   trapezoid(h=30, w1=60, w2=40, chamfer=-5);
// Example(2D): Flipped Negative Chamfered Trapezoid
//   trapezoid(h=30, w1=60, w2=40, chamfer=-5, flip=true);
// Example(2D): Rounded Trapezoid
//   trapezoid(h=30, w1=60, w2=40, rounding=5);
// Example(2D): Negative Rounded Trapezoid
//   trapezoid(h=30, w1=60, w2=40, rounding=-5);
// Example(2D): Flipped Negative Rounded Trapezoid
//   trapezoid(h=30, w1=60, w2=40, rounding=-5, flip=true);
// Example(2D): Mixed Chamfering and Rounding
//   trapezoid(h=30, w1=60, w2=40, rounding=[5,0,-10,0],chamfer=[0,8,0,-15],$fa=1,$fs=1);
// Example(2D): Called as Function
//   stroke(closed=true, trapezoid(h=30, w1=40, w2=20));
function trapezoid(h, w1, w2, angle, shift=0, chamfer=0, rounding=0, flip=false, anchor=CENTER, spin=0) =
    assert(is_undef(h) || is_finite(h))
    assert(is_undef(w1) || is_finite(w1))
    assert(is_undef(w2) || is_finite(w2))
    assert(is_undef(angle) || is_finite(angle))
    assert(num_defined([h, w1, w2, angle]) == 3, "Must give exactly 3 of the arguments h, w1, w2, and angle.")
    assert(is_finite(shift))
    assert(is_finite(chamfer)  || is_vector(chamfer,4))
    assert(is_finite(rounding) || is_vector(rounding,4))
    let(
        simple = chamfer==0 && rounding==0,
        h  = !is_undef(h)?  h  : opp_ang_to_adj(abs(w2-w1)/2, abs(angle)),
        w1 = !is_undef(w1)? w1 : w2 + 2*(adj_ang_to_opp(h, angle) + shift),
        w2 = !is_undef(w2)? w2 : w1 - 2*(adj_ang_to_opp(h, angle) + shift),
        chamfs = is_num(chamfer)? [for (i=[0:3]) chamfer] :
            assert(len(chamfer)==4) chamfer,
        rounds = is_num(rounding)? [for (i=[0:3]) rounding] :
            assert(len(rounding)==4) rounding,
        srads = [for (i=[0:3]) rounds[i]? rounds[i] : chamfs[i]],
        rads = v_abs(srads)
    )
    assert(w1>=0 && w2>=0 && h>0, "Degenerate trapezoid geometry.")
    assert(w1+w2>0, "Degenerate trapezoid geometry.")
    let(
        base = [
            [ w2/2+shift, h/2],
            [-w2/2+shift, h/2],
            [-w1/2,-h/2],
            [ w1/2,-h/2],
        ],
        ang1 = v_theta(base[0]-base[3])-90,
        ang2 = v_theta(base[1]-base[2])-90,
        angs = [ang1, ang2, ang2, ang1],
        qdirs = [[1,1], [-1,1], [-1,-1], [1,-1]],
        hyps = [for (i=[0:3]) adj_ang_to_hyp(rads[i],angs[i])],
        offs = [
            for (i=[0:3]) let(
                xoff = adj_ang_to_opp(rads[i],angs[i]),
                a = [xoff, -rads[i]] * qdirs[i].y * (srads[i]<0 && flip? -1 : 1),
                b = a + [hyps[i] * qdirs[i].x * (srads[i]<0 && !flip? 1 : -1), 0]
            ) b
        ],
        cpath = [
            each (
                let(i = 0)
                rads[i] == 0? [base[i]] :
                srads[i] > 0? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[angs[i], 90], r=rads[i]) :
                flip? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[angs[i],-90], r=rads[i]) :
                arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[180+angs[i],90], r=rads[i])
            ),
            each (
                let(i = 1)
                rads[i] == 0? [base[i]] :
                srads[i] > 0? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[90,180+angs[i]], r=rads[i]) :
                flip? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[270,180+angs[i]], r=rads[i]) :
                arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[90,angs[i]], r=rads[i])
            ),
            each (
                let(i = 2)
                rads[i] == 0? [base[i]] :
                srads[i] > 0? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[180+angs[i],270], r=rads[i]) :
                flip? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[180+angs[i],90], r=rads[i]) :
                arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[angs[i],-90], r=rads[i])
            ),
            each (
                let(i = 3)
                rads[i] == 0? [base[i]] :
                srads[i] > 0? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[-90,angs[i]], r=rads[i]) :
                flip? arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[90,angs[i]], r=rads[i]) :
                arc(N=rounds[i]?undef:2, cp=base[i]+offs[i], angle=[270,180+angs[i]], r=rads[i])
            ),
        ],
        path = reverse(cpath)
    ) simple
      ? reorient(anchor,spin, two_d=true, size=[w1,h], size2=w2, shift=shift, p=path)
      : reorient(anchor,spin, two_d=true, path=path, p=path);



module trapezoid(h, w1, w2, angle, shift=0, chamfer=0, rounding=0, flip=false, anchor=CENTER, spin=0) {
    path = trapezoid(h=h, w1=w1, w2=w2, angle=angle, shift=shift, chamfer=chamfer, rounding=rounding, flip=flip);
    union() {
        simple = chamfer==0 && rounding==0;
        h  = !is_undef(h)?  h  : opp_ang_to_adj(abs(w2-w1)/2, abs(angle));
        w1 = !is_undef(w1)? w1 : w2 + 2*(adj_ang_to_opp(h, angle) + shift);
        w2 = !is_undef(w2)? w2 : w1 - 2*(adj_ang_to_opp(h, angle) + shift);
        if (simple) {
            attachable(anchor,spin, two_d=true, size=[w1,h], size2=w2, shift=shift) {
                polygon(path);
                children();
            }
        } else {
            attachable(anchor,spin, two_d=true, path=path) {
                polygon(path);
                children();
            }
        }
    }
}



// Function&Module: star()
// Usage: As Module
//   star(n, r/or, ir, [realign=], [align_tip=], [align_pit=], ...);
//   star(n, r/or, step=, ...);
// Usage: With Attachments
//   star(n, r/or, ir, ...) { attachments }
// Usage: As Function
//   path = star(n, r/or, ir, [realign=], [align_tip=], [align_pit=], ...);
//   path = star(n, r/or, step=, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse()
// Description:
//   When called as a function, returns the path needed to create a star polygon with N points.
//   When called as a module, creates a star polygon with N points.
// Arguments:
//   n = The number of stellate tips on the star.
//   r/or = The radius to the tips of the star.
//   ir = The radius to the inner corners of the star.
//   ---
//   d/od = The diameter to the tips of the star.
//   id = The diameter to the inner corners of the star.
//   step = Calculates the radius of the inner star corners by virtually drawing a straight line `step` tips around the star.  2 <= step < n/2
//   realign = If false, vertex 0 will lie on the X+ axis.  If true then the midpoint of the last edge will lie on the X+ axis, and vertex 0 will be below the X axis.    Default: false
//   align_tip = If given as a 2D vector, rotates the whole shape so that the first star tip points in that direction.  This occurs before spin.
//   align_pit = If given as a 2D vector, rotates the whole shape so that the first inner corner is pointed towards that direction.  This occurs before spin.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   atype = Choose "hull" or "intersect" anchor methods.  Default: "hull"
// Extra Anchors:
//   "tip0" ... "tip4" = Each tip has an anchor, pointing outwards.
//   "pit0" ... "pit4" = The inside corner between each tip has an anchor, pointing outwards.
//   "midpt0" ... "midpt4" = The center-point between each pair of tips has an anchor, pointing outwards.
// Examples(2D):
//   star(n=5, r=50, ir=25);
//   star(n=5, r=50, step=2);
//   star(n=7, r=50, step=2);
//   star(n=7, r=50, step=3);
// Example(2D): Realigned
//   star(n=7, r=50, step=3, realign=true);
// Example(2D): Alignment by Tip
//   star(n=5, ir=15, or=30, align_tip=BACK+RIGHT)
//       attach("tip0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Alignment by Pit
//   star(n=5, ir=15, or=30, align_pit=BACK+RIGHT)
//       attach("pit0", FWD) color("blue")
//           stroke([[0,0],[0,7]], endcap2="arrow2");
// Example(2D): Called as Function
//   stroke(closed=true, star(n=5, r=50, ir=25));
function star(n, r, ir, d, or, od, id, step, realign=false, align_tip, align_pit, anchor=CENTER, spin=0, atype="hull", _mat, _anchs) =
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")  
    assert(is_undef(align_tip) || is_vector(align_tip))
    assert(is_undef(align_pit) || is_vector(align_pit))
    assert(is_undef(align_tip) || is_undef(align_pit), "Can only specify one of align_tip and align_pit")
    assert(is_def(n), "Must specify number of points, n")
    let(
        r = get_radius(r1=or, d1=od, r=r, d=d),
        count = num_defined([ir,id,step]),
        stepOK = is_undef(step) || (step>1 && step<n/2)
    )
    assert(count==1, "Must specify exactly one of ir, id, step")
    assert(stepOK,  n==4 ? "Parameter 'step' not allowed for 4 point stars"
                  : n==5 || n==6 ? str("Parameter 'step' must be 2 for ",n," point stars")
                  : str("Parameter 'step' must be between 2 and ",floor(n/2-1/2)," for ",n," point stars"))
    let(
        mat = !is_undef(_mat) ? _mat :
            ( realign? zrot(-180/n) : ident(4) ) * (
                !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
                !is_undef(align_pit)? rot(from=RIGHT, to=point2d(align_pit)) * zrot(180/n) :
                1
            ),
        stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n),
        ir = get_radius(r=ir, d=id, dflt=stepr),
        offset = realign? 180/n : 0,
        path1 = [for(i=[2*n:-1:1]) let(theta=180*i/n, radius=(i%2)?ir:r) radius*[cos(theta), sin(theta)]],
        path = apply(mat, path1),
        anchors = !is_undef(_anchs) ? _anchs :
            !is_string(anchor)? [] : [
            for (i = [0:1:n-1]) let(
                a1 = 360 - i*360/n,
                a2 = a1 - 180/n,
                a3 = a1 - 360/n,
                p1 = apply(mat, polar_to_xy(r,a1)),
                p2 = apply(mat, polar_to_xy(ir,a2)),
                p3 = apply(mat, polar_to_xy(r,a3)),
                pos = (p1+p3)/2
            ) each [
                named_anchor(str("tip",i), p1, unit(p1,BACK), 0),
                named_anchor(str("pit",i), p2, unit(p2,BACK), 0),
                named_anchor(str("midpt",i), pos, unit(pos,BACK), 0),
            ]
        ]
    ) reorient(anchor,spin, two_d=true, path=path, p=path, extent=atype=="hull", anchors=anchors);


module star(n, r, ir, d, or, od, id, step, realign=false, align_tip, align_pit, anchor=CENTER, spin=0, atype="hull") {
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"");
    assert(is_undef(align_tip) || is_vector(align_tip));
    assert(is_undef(align_pit) || is_vector(align_pit));
    assert(is_undef(align_tip) || is_undef(align_pit), "Can only specify one of align_tip and align_pit");
    r = get_radius(r1=or, d1=od, r=r, d=d, dflt=undef);
    stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n);
    ir = get_radius(r=ir, d=id, dflt=stepr);
    mat = ( realign? zrot(-180/n) : ident(4) ) * (
            !is_undef(align_tip)? rot(from=RIGHT, to=point2d(align_tip)) :
            !is_undef(align_pit)? rot(from=RIGHT, to=point2d(align_pit)) * zrot(180/n) :
            1
        );
    anchors = [
        for (i = [0:1:n-1]) let(
            a1 = 360 - i*360/n - (realign? 180/n : 0),
            a2 = a1 - 180/n,
            a3 = a1 - 360/n,
            p1 = apply(mat, polar_to_xy(r,a1)),
            p2 = apply(mat, polar_to_xy(ir,a2)),
            p3 = apply(mat, polar_to_xy(r,a3)),
            pos = (p1+p3)/2
        ) each [
            named_anchor(str("tip",i), p1, unit(p1,BACK), 0),
            named_anchor(str("pit",i), p2, unit(p2,BACK), 0),
            named_anchor(str("midpt",i), pos, unit(pos,BACK), 0),
        ]
    ];
    path = star(n=n, r=r, ir=ir, realign=realign, _mat=mat, _anchs=anchors);
    attachable(anchor,spin, two_d=true, path=path, extent=atype=="hull", anchors=anchors) {
        polygon(path);
        children();
    }
}



/// Internal Function: _path_add_jitter()
/// Topics: Paths
/// See Also: jittered_poly(), subdivide_long_segments()
/// Usage:
///   jpath = _path_add_jitter(path, [dist], [closed=]);
/// Description:
///   Adds tiny jitter offsets to collinear points in the given path so that they
///   are no longer collinear.  This is useful for preserving subdivision on long
///   straight segments, when making geometry with `polygon()`, for use with
///   `linear_exrtrude()` with a `twist()`.
/// Arguments:
///   path = The path to add jitter to.
///   dist = The amount to jitter points by.  Default: 1/512 (0.00195)
///   ---
///   closed = If true, treat path like a closed polygon.  Default: true
/// Example(3D):
///   d = 100; h = 75; quadsize = 5;
///   path = pentagon(d=d);
///   spath = subdivide_long_segments(path, quadsize, closed=true);
///   jpath = _path_add_jitter(spath, closed=true);
///   linear_extrude(height=h, twist=72, slices=h/quadsize)
///      polygon(jpath);
function _path_add_jitter(path, dist=1/512, closed=true) =
    assert(is_path(path))
    assert(is_finite(dist))
    assert(is_bool(closed))
    [
        path[0],
        for (i=idx(path,s=1,e=closed?-1:-2)) let(
            n = line_normal([path[i-1],path[i]])
        ) path[i] + n * (is_collinear(select(path,i-1,i+1))? (dist * ((i%2)*2-1)) : 0),
        if (!closed) last(path)
    ];



// Module: jittered_poly()
// Topics: Extrusions
// See Also: subdivide_long_segments()
// Usage:
//   jittered_poly(path, [dist]);
// Description:
//   Creates a 2D polygon shape from the given path in such a way that any extra
//   collinear points are not stripped out in the way that `polygon()` normally does.
//   This is useful for refining the mesh of a `linear_extrude()` with twist.
// Arguments:
//   path = The path to add jitter to.
//   dist = The amount to jitter points by.  Default: 1/512 (0.00195)
// Example:
//   d = 100; h = 75; quadsize = 5;
//   path = pentagon(d=d);
//   spath = subdivide_long_segments(path, quadsize, closed=true);
//   linear_extrude(height=h, twist=72, slices=h/quadsize)
//      jittered_poly(spath);
module jittered_poly(path, dist=1/512) {
    polygon(_path_add_jitter(path, dist, closed=true));
}



// Section: Curved 2D Shapes


// Function&Module: teardrop2d()
//
// Description:
//   Makes a 2D teardrop shape. Useful for extruding into 3D printable holes.  Uses "intersect" style anchoring.  
//
// Usage: As Module
//   teardrop2d(r/d=, [ang], [cap_h]);
// Usage: With Attachments
//   teardrop2d(r/d=, [ang], [cap_h], ...) { attachments }
// Usage: As Function
//   path = teardrop2d(r/d=, [ang], [cap_h]);
//
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
//
// See Also: teardrop(), onion()
//
// Arguments:
//   r = radius of circular part of teardrop.  (Default: 1)
//   ang = angle of hat walls from the Y axis.  (Default: 45 degrees)
//   cap_h = if given, height above center where the shape will be truncated.
//   ---
//   d = diameter of spherical portion of bottom. (Use instead of r)
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//
// Example(2D): Typical Shape
//   teardrop2d(r=30, ang=30);
// Example(2D): Crop Cap
//   teardrop2d(r=30, ang=30, cap_h=40);
// Example(2D): Close Crop
//   teardrop2d(r=30, ang=30, cap_h=20);
module teardrop2d(r, ang=45, cap_h, d, anchor=CENTER, spin=0)
{
    path = teardrop2d(r=r, d=d, ang=ang, cap_h=cap_h);
    attachable(anchor,spin, two_d=true, path=path, extent=false) {
        polygon(path);
        children();
    }
}


function teardrop2d(r, ang=45, cap_h, d, anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=1),
        ang2 = 90-ang,
        prepath = zrot(90, p=circle(r=r)),
        eps=1e-9,
        prepath2 = [for (p=prepath) let(a=atan2(p.y,p.x)) if(a<=90-ang2+eps || a>=90+ang2-eps) p],
        hyp = is_undef(cap_h)
          ? opp_ang_to_hyp(abs(prepath2[0].x), ang)
          : adj_ang_to_hyp(cap_h-prepath2[0].y, ang),
        p1 = prepath2[0] + polar_to_xy(hyp, 90+ang),
        p2 = last(prepath2) + polar_to_xy(hyp, 90-ang),
        path = deduplicate([p1, each prepath2, p2], closed=true)
    ) reorient(anchor,spin, two_d=true, path=path, p=path, extent=false);



// Function&Module: egg()
// Usage: As Module
//   egg(length, r1, r2, R);
// Usage: As Function
//   path = egg(length, r1|d2, r2|d2, R|D);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse(), glued_circles()
// Description:
//   Constructs an egg-shaped object by connecting two circles with convex arcs that are tangent to the circles.
//   You specify the length of the egg, the radii of the two circles, and the desired arc radius.
//   Note that because the side radius, R, is often much larger than the end radii, you may get better
//   results using `$fs` and `$fa` to control the number of semgments rather than using `$fn`.
//   This shape may be useful for creating a cam.  
// Arguments:
//   length = length of the egg
//   r1 = radius of the left-hand circle
//   r2 = radius of the right-hand circle
//   R = radius of the joining arcs
//   ---
//   d1 = diameter of the left-hand circle
//   d2 = diameter of the right-hand circle
//   D = diameter of the joining arcs
// Extra Anchors:
//   "left" = center of the left circle
//   "right" = center of the right circle
// Example(2D,NoAxes): This first example shows how the egg is constructed from two circles and two joining arcs.
//   $fn=100;
//   color("red") stroke(egg(78,25,12, 60),closed=true);
//   stroke([left(14,circle(25)),
//           right(27,circle(12))]);
// Example(2D,Anim,VPD=250,VPR=[0,0,0]): Varying length between circles
//   r1 = 25; r2 = 12; R = 65;
//   length = floor(lookup($t, [[0,55], [0.5,90], [1,55]]));
//   egg(length,r1,r2,R,$fn=180);
//   color("black") text(str("length=",length), size=8, halign="center", valign="center");
// Example(2D,Anim,VPD=250,VPR=[0,0,0]): Varying tangent arc radius R
//   length = 78; r1 = 25; r2 = 12;
//   R = floor(lookup($t, [[0,45], [0.5,150], [1,45]]));
//   egg(length,r1,r2,R,$fn=180);
//   color("black") text(str("R=",R), size=8, halign="center", valign="center");
// Example(2D,Anim,VPD=250,VPR=[0,0,0]): Varying circle radius r2
//   length = 78; r1 = 25; R = 65;
//   r2 = floor(lookup($t, [[0,5], [0.5,30], [1,5]]));
//   egg(length,r1,r2,R,$fn=180);
//   color("black") text(str("r2=",r2), size=8, halign="center", valign="center");
function egg(length, r1, r2, R, d1, d2, D, anchor=CENTER, spin=0) =
    let(
        r1 = get_radius(r1=r1,d1=d1),
        r2 = get_radius(r1=r2,d1=d2),
        D = get_radius(r1=R, d1=D)
    )
    assert(length>0)
    assert(R>length/2, "Side radius R must be larger than length/2")
    assert(length>r1+r2, "Length must be longer than 2*(r1+r2)")
    assert(length>2*r2, "Length must be longer than 2*r2")
    assert(length>2*r1, "Length must be longer than 2*r1")  
    let(
        c1 = [-length/2+r1,0],
        c2 = [length/2-r2,0],
        Rmin = (r1+r2+norm(c1-c2))/2,
        Mlist = circle_circle_intersection(c1,R-r1,c2,R-r2),
        arcparms = reverse([for(M=Mlist) [M, c1+r1*unit(c1-M), c2+r2*unit(c2-M)]]),
        path = concat(
                      arc(r=r2, cp=c2, points=[[length/2,0],arcparms[0][2]],endpoint=false),
                      arc(r=R, cp=arcparms[0][0], points=select(arcparms[0],[2,1]),endpoint=false),
                      arc(r=r1, points=[arcparms[0][1], [-length/2,0], arcparms[1][1]],endpoint=false),
                      arc(r=R, cp=arcparms[1][0], points=select(arcparms[1],[1,2]),endpoint=false),
                      arc(r=r2, cp=c2, points=[arcparms[1][2], [length/2,0]],endpoint=false)
        ),
        anchors = [named_anchor("left", c1, BACK, 0),
                   named_anchor("right", c2, BACK, 0)]
    )
    reorient(anchor, spin, two_d=true, path=path, extent=true, p=path, anchors=anchors);

module egg(length,r1,r2,R,d1,d2,D,anchor=CENTER, spin=0)
{
  path = egg(length,r1,r2,R,d1,d2,D);
  anchors = [named_anchor("left", [-length/2+r1,0], BACK, 0),
             named_anchor("right", [length/2-r2,0], BACK, 0)];
  attachable(anchor, spin, two_d=true, path=path, extent=true, anchors=anchors){
    polygon(path);
    children();
  }
}



// Function&Module: glued_circles()
// Usage: As Module
//   glued_circles(r/d=, [spread=], [tangent=], ...);
// Usage: With Attachments
//   glued_circles(r/d=, [spread=], [tangent=], ...) { attachments }
// Usage: As Function
//   path = glued_circles(r/d=, [spread=], [tangent=], ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse(), egg()
// Description:
//   When called as a function, returns a 2D path forming a shape of two circles joined by curved waist.
//   When called as a module, creates a 2D shape of two circles joined by curved waist.  Uses "hull" style anchoring.  
// Arguments:
//   r = The radius of the end circles.
//   spread = The distance between the centers of the end circles.  Default: 10
//   tangent = The angle in degrees of the tangent point for the joining arcs, measured away from the Y axis.  Default: 30
//   ---
//   d = The diameter of the end circles.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Examples(2D):
//   glued_circles(r=15, spread=40, tangent=45);
//   glued_circles(d=30, spread=30, tangent=30);
//   glued_circles(d=30, spread=30, tangent=15);
//   glued_circles(d=30, spread=30, tangent=-30);
// Example(2D): Called as Function
//   stroke(closed=true, glued_circles(r=15, spread=40, tangent=45));
function glued_circles(r, spread=10, tangent=30, d, anchor=CENTER, spin=0) =
    let(
        r = get_radius(r=r, d=d, dflt=10),
        r2 = (spread/2 / sin(tangent)) - r,
        cp1 = [spread/2, 0],
        cp2 = [0, (r+r2)*cos(tangent)],
        sa1 = 90-tangent,
        ea1 = 270+tangent,
        lobearc = ea1-sa1,
        lobesegs = ceil(segs(r)*lobearc/360),
        sa2 = 270-tangent,
        ea2 = 270+tangent,
        subarc = ea2-sa2,
        arcsegs = ceil(segs(r2)*abs(subarc)/360),
        // In the tangent zero case the inner curves are missing so we need to complete the two
        // outer curves.  In the other case the inner curves are present and endpoint=false
        // prevents point duplication.  
        path = tangent==0 ?
                    concat(arc(N=lobesegs+1, r=r, cp=-cp1, angle=[sa1,ea1]),
                           arc(N=lobesegs+1, r=r, cp=cp1, angle=[sa1+180,ea1+180]))
                :
                    concat(arc(N=lobesegs, r=r, cp=-cp1, angle=[sa1,ea1], endpoint=false),
                           [for(theta=lerpn(ea2+180,ea2-subarc+180,arcsegs,endpoint=false))  r2*[cos(theta),sin(theta)] - cp2],
                           arc(N=lobesegs, r=r, cp=cp1, angle=[sa1+180,ea1+180], endpoint=false),
                           [for(theta=lerpn(ea2,ea2-subarc,arcsegs,endpoint=false))  r2*[cos(theta),sin(theta)] + cp2]),
        maxx_idx = max_index(column(path,0)),
        path2 = reverse_polygon(list_rotate(path,maxx_idx))
    ) reorient(anchor,spin, two_d=true, path=path2, extent=true, p=path2);


module glued_circles(r, spread=10, tangent=30, d, anchor=CENTER, spin=0) {
    path = glued_circles(r=r, d=d, spread=spread, tangent=tangent);
    attachable(anchor,spin, two_d=true, path=path, extent=true) {
        polygon(path);
        children();
    }
}



function _superformula(theta,m1,m2,n1,n2=1,n3=1,a=1,b=1) =
    pow(pow(abs(cos(m1*theta/4)/a),n2)+pow(abs(sin(m2*theta/4)/b),n3),-1/n1);

// Function&Module: supershape()
// Usage: As Module
//   supershape(step, [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], <r=/d=>);
// Usage: With Attachments
//   supershape(step, [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], <r=/d=>) { attachments }
// Usage: As Function
//   path = supershape(step, [m1=], [m2=], [n1=], [n2=], [n3=], [a=], [b=], <r=/d=>);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: circle(), ellipse()
// Description:
//   When called as a function, returns a 2D path for the outline of the [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
//   When called as a module, creates a 2D [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
//   Note that the "hull" type anchoring (the default) is more intuitive for concave star-like shapes, but the anchor points do not
//   necesarily lie on the line of the anchor vector, which can be confusing, especially for simpler, ellipse-like shapes.  
// Arguments:
//   step = The angle step size for sampling the superformula shape.  Smaller steps are slower but more accurate.
//   m1 = The m1 argument for the superformula. Default: 4.
//   m2 = The m2 argument for the superformula. Default: m1.
//   n1 = The n1 argument for the superformula. Default: 1.
//   n2 = The n2 argument for the superformula. Default: n1.
//   n3 = The n3 argument for the superformula. Default: n2.
//   a = The a argument for the superformula.  Default: 1.
//   b = The b argument for the superformula.  Default: a.
//   r = Radius of the shape.  Scale shape to fit in a circle of radius r.
//   ---
//   d = Diameter of the shape.  Scale shape to fit in a circle of diameter d.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
//   atype = Select "hull" or "intersect" style anchoring.  Default: "hull". 
// Example(2D):
//   supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,r=50);
// Example(2D): Called as Function
//   stroke(closed=true, supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,d=100));
// Examples(2D,Med):
//   for(n=[2:5]) right(2.5*(n-2)) supershape(m1=4,m2=4,n1=n,a=1,b=2);  // Superellipses
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(.5,m1=m[i],n1=1);
//   m=[6,8,10,12]; for(i=[0:3]) right(2.7*i) supershape(.5,m1=m[i],n1=1,b=1.5);  // m should be even
//   m=[1,2,3,5]; for(i=[0:3]) fwd(1.5*i) supershape(m1=m[i],n1=0.4);
//   supershape(m1=5, n1=4, n2=1); right(2.5) supershape(m1=5, n1=40, n2=10);
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(m1=m[i], n1=60, n2=55, n3=30);
//   n=[0.5,0.2,0.1,0.02]; for(i=[0:3]) right(2.5*i) supershape(m1=5,n1=n[i], n2=1.7);
//   supershape(m1=2, n1=1, n2=4, n3=8);
//   supershape(m1=7, n1=2, n2=8, n3=4);
//   supershape(m1=7, n1=3, n2=4, n3=17);
//   supershape(m1=4, n1=1/2, n2=1/2, n3=4);
//   supershape(m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9);
//   for(i=[1:4]) right(3*i) supershape(m1=i, m2=3*i, n1=2);
//   m=[4,6,10]; for(i=[0:2]) right(i*5) supershape(m1=m[i], n1=12, n2=8, n3=5, a=2.7);
//   for(i=[-1.5:3:1.5]) right(i*1.5) supershape(m1=2,m2=10,n1=i,n2=1);
//   for(i=[1:3],j=[-1,1]) translate([3.5*i,1.5*j])supershape(m1=4,m2=6,n1=i*j,n2=1);
//   for(i=[1:3]) right(2.5*i)supershape(step=.5,m1=88, m2=64, n1=-i*i,n2=1,r=1);
// Examples:
//   linear_extrude(height=0.3, scale=0) supershape(step=1, m1=6, n1=0.4, n2=0, n3=6);
//   linear_extrude(height=5, scale=0) supershape(step=1, b=3, m1=6, n1=3.8, n2=16, n3=10);
function supershape(step=0.5, m1=4, m2, n1=1, n2, n3, a=1, b, r, d,anchor=CENTER, spin=0, atype="hull") =
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"")
    let(

        r = get_radius(r=r, d=d, dflt=undef),
        m2 = is_def(m2) ? m2 : m1,
        n2 = is_def(n2) ? n2 : n1,
        n3 = is_def(n3) ? n3 : n2,
        b = is_def(b) ? b : a,
        steps = ceil(360/step),
        step = 360/steps,
        angs = [for (i = [0:steps]) step*i],
        rads = [for (theta = angs) _superformula(theta=theta,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b)],
        scale = is_def(r) ? r/max(rads) : 1,
        path = [for (i = [steps:-1:1]) let(a=angs[i]) scale*rads[i]*[cos(a), sin(a)]]
    ) reorient(anchor,spin, two_d=true, path=path, p=path, extent=atype=="hull");

module supershape(step=0.5,m1=4,m2=undef,n1,n2=undef,n3=undef,a=1,b=undef, r=undef, d=undef, anchor=CENTER, spin=0, atype="hull") {
    assert(in_list(atype, _ANCHOR_TYPES), "Anchor type must be \"hull\" or \"intersect\"");
    path = supershape(step=step,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b,r=r,d=d);
    attachable(anchor,spin,extent=atype=="hull", two_d=true, path=path) {
        polygon(path);
        children();
    }
}


// Function&Module: reuleaux_polygon()
// Usage: As Module
//   reuleaux_polygon(N, r|d, ...);
// Usage: As Function
//   path = reuleaux_polygon(N, r|d, ...);
// Topics: Shapes (2D), Paths (2D), Path Generators, Attachable
// See Also: regular_ngon(), pentagon(), hexagon(), octagon()
// Description:
//   Creates a 2D Reuleaux Polygon; a constant width shape that is not circular.  Uses "intersect" type anchoring.  
// Arguments:
//   N = Number of "sides" to the Reuleaux Polygon.  Must be an odd positive number.  Default: 3
//   r = Radius of the shape.  Scale shape to fit in a circle of radius r.
//   ---
//   d = Diameter of the shape.  Scale shape to fit in a circle of diameter d.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// Extra Anchors:
//   "tip0", "tip1", etc. = Each tip has an anchor, pointing outwards.
// Examples(2D):
//   reuleaux_polygon(N=3, r=50);
//   reuleaux_polygon(N=5, d=100);
// Examples(2D): Standard vector anchors are based on extents
//   reuleaux_polygon(N=3, d=50) show_anchors(custom=false);
// Examples(2D): Named anchors exist for the tips
//   reuleaux_polygon(N=3, d=50) show_anchors(std=false);
module reuleaux_polygon(N=3, r, d, anchor=CENTER, spin=0) {
    assert(N>=3 && (N%2)==1);
    r = get_radius(r=r, d=d, dflt=1);
    path = reuleaux_polygon(N=N, r=r);
    anchors = [
        for (i = [0:1:N-1]) let(
            ca = 360 - i * 360/N,
            cp = polar_to_xy(r, ca)
        ) named_anchor(str("tip",i), cp, unit(cp,BACK), 0),
    ];
    attachable(anchor,spin, two_d=true, path=path, extent=false, anchors=anchors) {
        polygon(path);
        children();
    }
}


function reuleaux_polygon(N=3, r, d, anchor=CENTER, spin=0) =
    assert(N>=3 && (N%2)==1)
    let(
        r = get_radius(r=r, d=d, dflt=1),
        ssegs = max(3,ceil(segs(r)/N)),
        slen = norm(polar_to_xy(r,0)-polar_to_xy(r,180-180/N)),
        path = [
            for (i = [0:1:N-1]) let(
                ca = 180 - (i+0.5) * 360/N,
                sa = ca + 180 + (90/N),
                ea = ca + 180 - (90/N),
                cp = polar_to_xy(r, ca)
            ) each arc(N=ssegs-1, r=slen, cp=cp, angle=[sa,ea], endpoint=false)
        ],
        anchors = [
            for (i = [0:1:N-1]) let(
                ca = 360 - i * 360/N,
                cp = polar_to_xy(r, ca)
            ) named_anchor(str("tip",i), cp, unit(cp,BACK), 0),
        ]
    ) reorient(anchor,spin, two_d=true, path=path, extent=false, anchors=anchors, p=path);



// Section: Text

// Module: text()
// Topics: Attachments, Text
// Usage:
//   text(text, [size], [font], ...);
// Description:
//   Creates a 3D text block that can be attached to other attachable objects.
//   NOTE: This cannot have children attached to it.
// Arguments:
//   text = The text string to instantiate as an object.
//   size = The font size used to create the text block.  Default: 10
//   font = The name of the font used to create the text block.  Default: "Helvetica"
//   ---
//   halign = If given, specifies the horizontal alignment of the text.  `"left"`, `"center"`, or `"right"`.  Overrides `anchor=`.
//   valign = If given, specifies the vertical alignment of the text.  `"top"`, `"center"`, `"baseline"` or `"bottom"`.  Overrides `anchor=`.
//   spacing = The relative spacing multiplier between characters.  Default: `1.0`
//   direction = The text direction.  `"ltr"` for left to right.  `"rtl"` for right to left. `"ttb"` for top to bottom. `"btt"` for bottom to top.  Default: `"ltr"`
//   language = The language the text is in.  Default: `"en"`
//   script = The script the text is in.  Default: `"latin"`
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#subsection-anchor).  Default: `"baseline"`
//   spin = Rotate this many degrees around the Z axis.  See [spin](attachments.scad#subsection-spin).  Default: `0`
// See Also: attachable()
// Extra Anchors:
//   "baseline" = Anchors at the baseline of the text, at the start of the string.
//   str("baseline",VECTOR) = Anchors at the baseline of the text, modified by the X and Z components of the appended vector.
// Examples(2D):
//   text("Foobar", size=10);
//   text("Foobar", size=12, font="Helvetica");
//   text("Foobar", anchor=CENTER);
//   text("Foobar", anchor=str("baseline",CENTER));
// Example: Using line_of() distributor
//   txt = "This is the string.";
//   line_of(spacing=[10,-5],n=len(txt))
//       text(txt[$idx], size=10, anchor=CENTER);
// Example: Using arc_of() distributor
//   txt = "This is the string";
//   arc_of(r=50, n=len(txt), sa=0, ea=180)
//       text(select(txt,-1-$idx), size=10, anchor=str("baseline",CENTER), spin=-90);
module text(text, size=10, font="Helvetica", halign, valign, spacing=1.0, direction="ltr", language="en", script="latin", anchor="baseline", spin=0) {
    no_children($children);
    dummy1 =
        assert(is_undef(anchor) || is_vector(anchor) || is_string(anchor), str("Got: ",anchor))
        assert(is_undef(spin)   || is_vector(spin,3) || is_num(spin), str("Got: ",spin));
    anchor = default(anchor, CENTER);
    spin =   default(spin,   0);
    geom = _attach_geom(size=[size,size],two_d=true);
    anch = !any([for (c=anchor) c=="["])? anchor :
        let(
            parts = str_split(str_split(str_split(anchor,"]")[0],"[")[1],","),
            vec = [for (p=parts) parse_float(str_strip(p," ",start=true))]
        ) vec;
    ha = halign!=undef? halign :
        anchor=="baseline"? "left" :
        anchor==anch && is_string(anchor)? "center" :
        anch.x<0? "left" :
        anch.x>0? "right" :
        "center";
    va = valign != undef? valign :
        starts_with(anchor,"baseline")? "baseline" :
        anchor==anch && is_string(anchor)? "center" :
        anch.y<0? "bottom" :
        anch.y>0? "top" :
        "center";
    base = anchor=="baseline"? CENTER :
        anchor==anch && is_string(anchor)? CENTER :
        anch.z<0? BOTTOM :
        anch.z>0? TOP :
        CENTER;
    m = _attach_transform(base,spin,undef,geom);
    multmatrix(m) {
        $parent_anchor = anchor;
        $parent_spin   = spin;
        $parent_orient = undef;
        $parent_geom   = geom;
        $parent_size   = _attach_geom_size(geom);
        $attach_to   = undef;
        do_show = _attachment_is_shown($tags);
        if (do_show) {
            _color($color) {
                _text(
                    text=text, size=size, font=font,
                    halign=ha, valign=va, spacing=spacing,
                    direction=direction, language=language,
                    script=script
                );
            }
        }
    }
}


// Section: Rounding 2D shapes

// Module: round2d()
// Usage:
//   round2d(r) ...
//   round2d(or) ...
//   round2d(ir) ...
//   round2d(or, ir) ...
// Description:
//   Rounds arbitrary 2D objects.  Giving `r` rounds all concave and convex corners.  Giving just `ir`
//   rounds just concave corners.  Giving just `or` rounds convex corners.  Giving both `ir` and `or`
//   can let you round to different radii for concave and convex corners.  The 2D object must not have
//   any parts narrower than twice the `or` radius.  Such parts will disappear.
// Arguments:
//   r = Radius to round all concave and convex corners to.
//   or = Radius to round only outside (convex) corners to.  Use instead of `r`.
//   ir = Radius to round only inside (concave) corners to.  Use instead of `r`.
// Examples(2D):
//   round2d(r=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   round2d(or=16,ir=8) {square([40,100], center=true); square([100,40], center=true);}
module round2d(r, or, ir)
{
    or = get_radius(r1=or, r=r, dflt=0);
    ir = get_radius(r1=ir, r=r, dflt=0);
    offset(or) offset(-ir-or) offset(delta=ir,chamfer=true) children();
}


// Module: shell2d()
// Usage:
//   shell2d(thickness, [or], [ir], [fill], [round])
// Description:
//   Creates a hollow shell from 2D children, with optional rounding.
// Arguments:
//   thickness = Thickness of the shell.  Positive to expand outward, negative to shrink inward, or a two-element list to do both.
//   or = Radius to round corners on the outside of the shell.  If given a list of 2 radii, [CONVEX,CONCAVE], specifies the radii for convex and concave corners separately.  Default: 0 (no outside rounding)
//   ir = Radius to round corners on the inside of the shell.  If given a list of 2 radii, [CONVEX,CONCAVE], specifies the radii for convex and concave corners separately.  Default: 0 (no inside rounding)
// Examples(2D):
//   shell2d(10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(-10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d([-10,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=10) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=[10,0]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,or=[0,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=[10,0]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(10,ir=[0,10]) {square([40,100], center=true); square([100,40], center=true);}
//   shell2d(8,or=[16,8],ir=[16,8]) {square([40,100], center=true); square([100,40], center=true);}
module shell2d(thickness, or=0, ir=0)
{
    thickness = is_num(thickness)? (
        thickness<0? [thickness,0] : [0,thickness]
    ) : (thickness[0]>thickness[1])? (
        [thickness[1],thickness[0]]
    ) : thickness;
    orad = is_finite(or)? [or,or] : or;
    irad = is_finite(ir)? [ir,ir] : ir;
    difference() {
        round2d(or=orad[0],ir=orad[1])
            offset(delta=thickness[1])
                children();
        round2d(or=irad[1],ir=irad[0])
            offset(delta=thickness[0])
                children();
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
