//////////////////////////////////////////////////////////////////////
// LibFile: beziers.scad
//   Bezier curves and surfaces are way to represent smooth curves and smoothly curving
//   surfaces with a set of control points.  The curve or surface is defined by
//   the control points, but usually only passes through the first and last control point (the endpoints).
//   This file provides some
//   aids to constructing the control points, and highly optimized functions for
//   computing the Bezier curves and surfaces given by the control points, 
// Includes:
//   include <BOSL2/std.scad>
//   include <BOSL2/beziers.scad>
// FileGroup: Advanced Modeling
// FileSummary: Bezier curves and surfaces.
//////////////////////////////////////////////////////////////////////

// Terminology:
//   Path = A series of points joined by straight line segements.
//   Bezier Curve = A polynomial curve defined by a list of control points.  The curve starts at the first control point and ends at the last one.  The other control points define the shape of the curve and they are often *NOT* on the curve
//   Control Point = A point that influences the shape of the Bezier curve.
//   Degree = The degree of the polynomial used to make the bezier curve.  A bezier curve of degree N will have N+1 control points.  Most beziers are cubic (degree 3).  The higher the degree, the more the curve can wiggle.  
//   Bezier Parameter = A parameter, usually `u` below, that ranges from 0 to 1 to trace out the bezier curve.  When `u=0` you get the first control point and when `u=1` you get the last control point. Intermediate points are traced out *non-uniformly*.  
//   Bezier Path = A list of bezier control points corresponding to a series of Bezier curves that connect together, end to end.  Because they connect, the endpoints are shared between control points and are not repeated, so a degree 3 bezier path representing two bezier curves will have seven entries to represent two sets of four control points.    **NOTE:** A "bezier path" is *NOT* a standard path
//   Bezier Patch = A two-dimensional arrangement of Bezier control points that generate a bounded curved Bezier surface.  A Bezier patch is a (N+1) by (M+1) grid of control points, which defines surface with four edges (in the non-degenerate case). 
//   Bezier Surface = A surface defined by a list of one or more bezier patches.
//   Spline Steps = The number of straight-line segments used to approximate a Bezier curve.  The more spline steps, the better the approximation to the curve, but the slower it will be to generate.  This plays a role analogous to `$fn` for circles.  Usually defaults to 16.


// Section: Bezier Curves

// Function: bezier_points()
// Usage:
//   pt = bezier_points(bezier, u);
//   ptlist = bezier_points(bezier, RANGE);
//   ptlist = bezier_points(bezier, LIST);
// Topics: Bezier Curves
// Description:
//   Computes points on a bezier curve with control points specified by `bezier` at parameter values
//   specified by `u`, which can be a scalar or a list.  The value `u=0` gives the first endpoint; `u=1` gives the final endpoint,
//   and intermediate values of `u` fill in the curve in a non-uniform fashion.  This function uses an optimized method which
//   is best when `u` is a long list and the bezier degree is 10 or less.  The degree of the bezier
//   curve is `len(bezier)-1`.
// Arguments:
//   bezier = The list of endpoints and control points for this bezier curve.
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.  
// Example(2D): Quadratic (Degree 2) Bezier.
//   bez = [[0,0], [30,30], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   translate(bezier_points(bez, 0.3)) color("red") sphere(1);
// Example(2D): Cubic (Degree 3) Bezier
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   translate(bezier_points(bez, 0.4)) color("red") sphere(1);
// Example(2D): Degree 4 Bezier.
//   bez = [[0,0], [5,15], [40,20], [60,-15], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   translate(bezier_points(bez, 0.8)) color("red") sphere(1);
// Example(2D): Giving a List of `u`
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   pts = bezier_points(bez, [0, 0.2, 0.3, 0.7, 0.8, 1]);
//   rainbow(pts) move($item) sphere(1.5, $fn=12);
// Example(2D): Giving a Range of `u`
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   debug_bezier(bez, N=len(bez)-1);
//   pts = bezier_points(bez, [0:0.2:1]);
//   rainbow(pts) move($item) sphere(1.5, $fn=12);

// Ugly but speed optimized code for computing bezier curves using the matrix representation
// See https://pomax.github.io/bezierinfo/#matrix for explanation.
//
// All of the loop unrolling makes and the use of the matrix lookup table make a big difference
// in the speed of execution.  For orders 10 and below this code is 10-20 times faster than
// the recursive code using the de Casteljau method depending on the bezier order and the
// number of points evaluated in one call (more points is faster).  For orders 11 and above without the
// lookup table or hard coded powers list the code is about twice as fast as the recursive method.
// Note that everything I tried to simplify or tidy this code made is slower, sometimes a lot slower.
function bezier_points(curve, u) =
    is_num(u) ? bezier_points(curve,[u])[0] :
    let(
        N = len(curve)-1,
        M = _bezier_matrix(N)*curve
    )
    N==0 ? [for(uval=u)[1]*M] :
    N==1 ? [for(uval=u)[1, uval]*M] :
    N==2 ? [for(uval=u)[1, uval, uval^2]*M] :
    N==3 ? [for(uval=u)[1, uval, uval^2, uval^3]*M] :          
    N==4 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4]*M] :
    N==5 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5]*M] :
    N==6 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6]*M] :
    N==7 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7]*M] :
    N==8 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7, uval^8]*M] :
    N==9 ? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7, uval^8, uval^9]*M] :
    N==10? [for(uval=u)[1, uval, uval^2, uval^3, uval^4, uval^5,uval^6, uval^7, uval^8, uval^9, uval^10]*M] :
    /* N>=11 */  [for(uval=u)[for (i=[0:1:N]) uval^i]*M];


// Not public.
function _signed_pascals_triangle(N,tri=[[-1]]) =
    len(tri)==N+1 ? tri :
    let(last=tri[len(tri)-1])
    _signed_pascals_triangle(N,concat(tri,[[-1, for(i=[0:1:len(tri)-2]) (i%2==1?-1:1)*(abs(last[i])+abs(last[i+1])),len(last)%2==0? -1:1]]));


// Not public.
function _compute_bezier_matrix(N) =
    let(tri = _signed_pascals_triangle(N))
    [for(i=[0:N]) concat(tri[N][i]*tri[i], repeat(0,N-i))];


// The bezier matrix, which is related to Pascal's triangle, enables nonrecursive computation
// of bezier points.  This method is much faster than the recursive de Casteljau method
// in OpenScad, but we have to precompute the matrices to reap the full benefit.

// Not public.
_bezier_matrix_table = [
    [[1]],
    [[ 1, 0],
     [-1, 1]],
    [[1, 0, 0],
     [-2, 2, 0],
     [1, -2, 1]],
    [[ 1, 0, 0, 0],
     [-3, 3, 0, 0],
     [ 3,-6, 3, 0],
     [-1, 3,-3, 1]],
    [[ 1,  0,  0, 0, 0],
     [-4,  4,  0, 0, 0],
     [ 6,-12,  6, 0, 0],
     [-4, 12,-12, 4, 0],
     [ 1, -4,  6,-4, 1]],
    [[  1,  0, 0,   0, 0, 0],
     [ -5,  5, 0,   0, 0, 0],
     [ 10,-20, 10,  0, 0, 0],
     [-10, 30,-30, 10, 0, 0],
     [  5,-20, 30,-20, 5, 0],
     [ -1,  5,-10, 10,-5, 1]],
    [[  1,  0,  0,  0,  0, 0, 0],
     [ -6,  6,  0,  0,  0, 0, 0],
     [ 15,-30, 15,  0,  0, 0, 0],
     [-20, 60,-60, 20,  0, 0, 0],
     [ 15,-60, 90,-60, 15, 0, 0],
     [ -6, 30,-60, 60,-30, 6, 0],
     [  1, -6, 15,-20, 15,-6, 1]],
    [[  1,   0,   0,   0,  0,   0, 0, 0],
     [ -7,   7,   0,   0,  0,   0, 0, 0],
     [ 21, -42,  21,   0,  0,   0, 0, 0],
     [-35, 105,-105,  35,  0,   0, 0, 0],
     [ 35,-140, 210,-140,  35,  0, 0, 0],
     [-21, 105,-210, 210,-105, 21, 0, 0],
     [  7, -42, 105,-140, 105,-42, 7, 0],
     [ -1,   7, -21,  35, -35, 21,-7, 1]],
    [[  1,   0,   0,   0,   0,   0,  0, 0, 0],
     [ -8,   8,   0,   0,   0,   0,  0, 0, 0],
     [ 28, -56,  28,   0,   0,   0,  0, 0, 0],
     [-56, 168,-168,  56,   0,   0,  0, 0, 0],
     [ 70,-280, 420,-280,  70,   0,  0, 0, 0],
     [-56, 280,-560, 560,-280,  56,  0, 0, 0],
     [ 28,-168, 420,-560, 420,-168, 28, 0, 0],
     [ -8,  56,-168, 280,-280, 168,-56, 8, 0],
     [  1,  -8,  28, -56,  70, -56, 28,-8, 1]],
    [[1, 0, 0, 0, 0, 0, 0,  0, 0, 0], [-9, 9, 0, 0, 0, 0, 0, 0, 0, 0], [36, -72, 36, 0, 0, 0, 0, 0, 0, 0], [-84, 252, -252, 84, 0, 0, 0, 0, 0, 0],
     [126, -504, 756, -504, 126, 0, 0, 0, 0, 0], [-126, 630, -1260, 1260, -630, 126, 0, 0, 0, 0], [84, -504, 1260, -1680, 1260, -504, 84, 0, 0, 0],
     [-36, 252, -756, 1260, -1260, 756, -252, 36, 0, 0], [9, -72, 252, -504, 630, -504, 252, -72, 9, 0], [-1, 9, -36, 84, -126, 126, -84, 36, -9, 1]],
    [[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [-10, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0], [45, -90, 45, 0, 0, 0, 0, 0, 0, 0, 0], [-120, 360, -360, 120, 0, 0, 0, 0, 0, 0, 0],
     [210, -840, 1260, -840, 210, 0, 0, 0, 0, 0, 0], [-252, 1260, -2520, 2520, -1260, 252, 0, 0, 0, 0, 0],
     [210, -1260, 3150, -4200, 3150, -1260, 210, 0, 0, 0, 0], [-120, 840, -2520, 4200, -4200, 2520, -840, 120, 0, 0, 0],
     [45, -360, 1260, -2520, 3150, -2520, 1260, -360, 45, 0, 0], [-10, 90, -360, 840, -1260, 1260, -840, 360, -90, 10, 0],
     [1, -10, 45, -120, 210, -252, 210, -120, 45, -10, 1]]
];


// Not public.
function _bezier_matrix(N) =
    N>10 ? _compute_bezier_matrix(N) :
    _bezier_matrix_table[N];


// Function: bezier_curve()
// Usage:
//   path = bezier_curve(bezier, [splinesteps], [endpoint]);
// Topics: Bezier Curves
// See Also: bezier_curvature(), bezier_tangent(), bezier_derivative(), bezier_points()
// Description:
//   Takes a list of bezier control points and generates splinesteps segments (splinesteps+1 points)
//   along the bezier curve they define.
//   Points start at the first control point and are sampled uniformly along the bezier parameter.
//   The endpoints of the output will be *exactly* equal to the first and last bezier control points
//   when endpoint is true.  If endpoint is false the sampling stops one step before the final point
//   of the bezier curve, but you still get the same number of (more tightly spaced) points.  
//   The distance between the points will *not* be equidistant.  
//   The degree of the bezier curve is one less than the number of points in `curve`.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   splinesteps = The number of segments to create on the bezier curve.  Default: 16
//   endpoint = if false then exclude the endpoint.  Default: True
// Example(2D): Quadratic (Degree 2) Bezier.
//   bez = [[0,0], [30,30], [80,0]];
//   move_copies(bezier_curve(bez, 8)) sphere(r=1.5, $fn=12);
//   debug_bezier(bez, N=len(bez)-1);
// Example(2D): Cubic (Degree 3) Bezier
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   move_copies(bezier_curve(bez, 8)) sphere(r=1.5, $fn=12);
//   debug_bezier(bez, N=len(bez)-1);
// Example(2D): Degree 4 Bezier.
//   bez = [[0,0], [5,15], [40,20], [60,-15], [80,0]];
//   move_copies(bezier_curve(bez, 8)) sphere(r=1.5, $fn=12);
//   debug_bezier(bez, N=len(bez)-1);
function bezier_curve(bezier,splinesteps=16,endpoint=true) =
    bezier_points(bezier, lerpn(0,1,splinesteps+1,endpoint));


// Function: bezier_derivative()
// Usage:
//   deriv = bezier_derivative(bezier, u, [order]);
//   derivs = bezier_derivative(bezier, LIST, [order]);
//   derivs = bezier_derivative(bezier, RANGE, [order]);
// Topics: Bezier Curves
// See Also: bezier_curvature(), bezier_tangent(), bezier_points()
// Description:
//   Evaluates the derivative of the bezier curve at the given parameter value or values, `u`.  The `order` gives the order of the derivative. 
//   The degree of the bezier curve is one less than the number of points in `bezier`.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
//   order = The order of the derivative to return.  Default: 1 (for the first derivative)
function bezier_derivative(bezier, u, order=1) =
    assert(is_int(order) && order>=0)
    order==0? bezier_points(bezier, u) : let(
        N = len(bezier) - 1,
        dpts = N * deltas(bezier)
    ) order==1? bezier_points(dpts, u) :
    bezier_derivative(dpts, u, order-1);



// Function: bezier_tangent()
// Usage:
//   tanvec = bezier_tangent(bezier, u);
//   tanvecs = bezier_tangent(bezier, LIST);
//   tanvecs = bezier_tangent(bezier, RANGE);
// Topics: Bezier Curves
// See Also: bezier_curvature(), bezier_derivative(), bezier_points()
// Description:
//   Returns the unit tangent vector at the given parameter values on a bezier curve with control points `bezier`.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
function bezier_tangent(bezier, u) =
    let(
        res = bezier_derivative(bezier, u)
    ) is_vector(res)? unit(res) :
    [for (v=res) unit(v)];



// Function: bezier_curvature()
// Usage:
//   crv = bezier_curvature(curve, u);
//   crvlist = bezier_curvature(curve, LIST);
//   crvlist = bezier_curvature(curve, RANGE);
// Topics: Bezier Curves
// See Also: bezier_tangent(), bezier_derivative(), bezier_points()
// Description:
//   Returns the curvature value for the given parameters `u` on the bezier curve with control points `bezier`. 
//   The curvature is the inverse of the radius of the tangent circle at the given point.
//   Thus, the tighter the curve, the larger the curvature value.  Curvature will be 0 for
//   a position with no curvature, since 1/0 is not a number.
// Arguments:
//   bezier = The list of control points that define the Bezier curve.
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
function bezier_curvature(bezier, u) =
    is_num(u) ? bezier_curvature(bezier,[u])[0] :
    let(
        d1 = bezier_derivative(bezier, u, 1),
        d2 = bezier_derivative(bezier, u, 2)
    ) [
        for(i=idx(d1))
        sqrt(
            sqr(norm(d1[i])*norm(d2[i])) -
            sqr(d1[i]*d2[i])
        ) / pow(norm(d1[i]),3)
    ];



// Function: bezier_closest_point()
// Usage:
//   u = bezier_closest_point(bezier, pt, [max_err]);
// Topics: Bezier Curves
// See Also: bezier_points()
// Description:
//   Finds the closest part of the given bezier curve to point `pt`.
//   The degree of the curve, N, is one less than the number of points in `curve`.
//   Returns `u` for the closest position on the bezier curve to the given point `pt`.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   pt = The point to find the closest curve point to.
//   max_err = The maximum allowed error when approximating the closest approach.
// Example(2D):
//   pt = [40,15];
//   bez = [[0,0], [20,40], [60,-25], [80,0]];
//   u = bezier_closest_point(bez, pt);
//   debug_bezier(bez, N=len(bez)-1);
//   color("red") translate(pt) sphere(r=1);
//   color("blue") translate(bezier_points(bez,u)) sphere(r=1);
function bezier_closest_point(bezier, pt, max_err=0.01, u=0, end_u=1) =
    let(
        steps = len(bezier)*3,
        uvals = [u, for (i=[0:1:steps]) (end_u-u)*(i/steps)+u, end_u],
        path = bezier_points(bezier,uvals),
        minima_ranges = [
            for (i = [1:1:len(uvals)-2]) let(
                d1 = norm(path[i-1]-pt),
                d2 = norm(path[i  ]-pt),
                d3 = norm(path[i+1]-pt)
            ) if (d2<=d1 && d2<=d3) [uvals[i-1],uvals[i+1]]
        ]
    ) len(minima_ranges)>1? (
        let(
            min_us = [
                for (minima = minima_ranges)
                    bezier_closest_point(bezier, pt, max_err=max_err, u=minima.x, end_u=minima.y)
            ],
            dists = [for (v=min_us) norm(bezier_points(bezier,v)-pt)],
            min_i = min_index(dists)
        ) min_us[min_i]
    ) : let(
        minima = minima_ranges[0],
        pp = bezier_points(bezier, minima),
        err = norm(pp[1]-pp[0])
    ) err<max_err? mean(minima) :
    bezier_closest_point(bezier, pt, max_err=max_err, u=minima[0], end_u=minima[1]);


// Function: bezier_length()
// Usage:
//   pathlen = bezier_length(bezier, [start_u], [end_u], [max_deflect]);
// Topics: Bezier Curves
// See Also: bezier_points()
// Description:
//   Approximates the length of the portion of the bezier curve between start_u and end_u.
// Arguments:
//   bezier = The list of control points that define the Bezier curve. 
//   start_u = The Bezier parameter to start measuring measuring from.  Between 0 and 1.
//   end_u = The Bezier parameter to end measuring at.  Between 0 and 1.  Greater than start_u.
//   max_deflect = The largest amount of deflection from the true curve to allow for approximation.
// Example:
//   bez = [[0,0], [5,35], [60,-25], [80,0]];
//   echo(bezier_length(bez));
function bezier_length(bezier, start_u=0, end_u=1, max_deflect=0.01) =
    let(
        segs = len(bezier) * 2,
        uvals = lerpn(start_u, end_u, segs+1),
        path = bezier_points(bezier,uvals),
        defl = max([
            for (i=idx(path,e=-3)) let(
                mp = (path[i] + path[i+2]) / 2
            ) norm(path[i+1] - mp)
        ]),
        mid_u = lerp(start_u, end_u, 0.5)
    )
    defl <= max_deflect? path_length(path) :
    sum([
        for (i=[0:1:segs-1]) let(
            su = lerp(start_u, end_u, i/segs),
            eu = lerp(start_u, end_u, (i+1)/segs)
        ) bezier_length(bezier, su, eu, max_deflect)
    ]);



// Function: bezier_line_intersection()
// Usage: 
//   u = bezier_line_intersection(curve, line);
// Topics: Bezier Curves, Geometry, Intersection
// See Also: bezier_points(), bezier_length(), bezier_closest_point()
// Description:
//   Finds the intersection points of the 2D Bezier curve with control points `bezier` and the given line, specified as a pair of points.  
//   Returns the intersection as a list of `u` values for the Bezier.  
// Arguments:
//   bezier = The list of control points that define a 2D Bezier curve. 
//   line = a list of two distinct 2d points defining a line
function bezier_line_intersection(bezier, line) =
    assert(is_path(bezier,2), "The input ´bezier´ must be a 2d bezier")
    assert(_valid_line(line,2), "The input `line` is not a valid 2d line")
    let( 
        a = _bezier_matrix(len(bezier)-1)*bezier, // bezier algebraic coeffs. 
        n = [-line[1].y+line[0].y, line[1].x-line[0].x], // line normal
        q = [for(i=[len(a)-1:-1:1]) a[i]*n, (a[0]-line[0])*n] // bezier SDF to line
    )
    [for(u=real_roots(q)) if (u>=0 && u<=1) u];




// Section: Bezier Path Functions
//   To contruct more complicated curves you can connect a sequence of Bezier curves end to end.  
//   A Bezier path is a flattened list of control points that, along with the degree, represents such a sequence of bezier curves where all of the curves have the same degree.
//   A Bezier path looks like a regular path, since it is just a list of points, but it is not a regular path.  Use {{bezpath_curve()}} to convert a Bezier path to a regular path.
//   We interpret a degree N Bezier path as groups of N+1 control points that
//   share endpoints, so they overlap by one point.  So if you have an order 3 bezier path `[p0,p1,p2,p3,p4,p5,p6]` then the first
//   Bezier curve control point set is `[p0,p1,p2,p3]` and the second one is `[p3,p4,p5,p6]`.  The endpoint, `p3`, is shared between the control point sets.
//   The Bezier degree, which must be known to interpret the Bezier path, defaults to 3. 


// Function: bezpath_points()
// Usage:
//   pt = bezpath_points(bezpath, curveind, u, [N]);
//   ptlist = bezpath_points(bezpath, curveind, LIST, [N]);
//   path = bezpath_points(bezpath, curveind, RANGE, [N]);
// Topics: Bezier Paths
// See Also: bezier_points(), bezier_curve()
// Description:
//   Extracts from the Bezier path `bezpath` the control points for the Bezier curve whose index is `curveind` and
//   computes the point or points on the corresponding Bezier curve specified by `u`.  If `curveind` is zero you
//   get the first curve.  The number of curves is `(len(bezpath)-1)/N` so the maximum index is that number minus one.  
// Arguments:
//   bezpath = A Bezier path path to approximate.
//   curveind = Curve number along the path.  
//   u = Parameter values for evaluating the curve, given as a single value, a list or a range.
//   N = The degree of the Bezier path curves.  Default: 3
function bezpath_points(bezpath, curveind, u, N=3) =
    bezier_points(select(bezpath,curveind*N,(curveind+1)*N), u);


// Function: bezpath_curve()
// Usage:
//   path = bezpath_curve(bezpath, [splinesteps], [N], [endpoint])
// Topics: Bezier Paths
// See Also: bezier_points(), bezier_curve()
// Description:
//   Takes a bezier path and converts it into a path of points.
// Arguments:
//   bezpath = A bezier path to approximate.
//   splinesteps = Number of straight lines to split each bezier curve into. default=16
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
//   endpoint = If true, include the very last point of the bezier path.  Default: true
// Example(2D):
//   bez = [
//       [0,0], [-5,30],
//       [20,60], [50,50], [110,30],
//       [60,25], [70,0], [80,-25],
//       [80,-50], [50,-50]
//   ];
//   debug_bezier(bez, N=3, width=2);
function bezpath_curve(bezpath, splinesteps=16, N=3, endpoint=true) =
    assert(is_path(bezpath))
    assert(is_int(N))
    assert(is_int(splinesteps) && splinesteps>0)
    assert(len(bezpath)%N == 1, str("A degree ",N," bezier path should have a multiple of ",N," points in it, plus 1."))
    let(
        segs = (len(bezpath)-1) / N,
        step = 1 / splinesteps
    ) [
        for (seg = [0:1:segs-1])
            each bezier_points(select(bezpath, seg*N, (seg+1)*N), [0:step:1-step/2]),
        if (endpoint) last(bezpath)
    ];


// Function: bezpath_closest_point()
// Usage:
//   res = bezpath_closest_point(bezpath, pt, [N], [max_err]);
// Topics: Bezier Paths
// See Also: bezier_points(), bezier_curve(), bezier_closest_point()
// Description:
//   Finds an approximation to the closest part of the given bezier path to point `pt`.
//   Returns [segnum, u] for the closest position on the bezier path to the given point `pt`.
// Arguments:
//   bezpath = A bezier path to approximate.
//   pt = The point to find the closest curve point to.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
//   max_err = The maximum allowed error when approximating the closest approach.
// Example(2D):
//   pt = [100,0];
//   bez = [[0,0], [20,40], [60,-25], [80,0],
//          [100,25], [140,25], [160,0]];
//   pos = bezpath_closest_point(bez, pt);
//   xy = bezpath_points(bez,pos[0],pos[1]);
//   debug_bezier(bez, N=3);
//   color("red") translate(pt) sphere(r=1);
//   color("blue") translate(xy) sphere(r=1);
function bezpath_closest_point(bezpath, pt, N=3, max_err=0.01, seg=0, min_seg=undef, min_u=undef, min_dist=undef) =
    assert(is_vector(pt))
    assert(is_int(N))
    assert(is_num(max_err))
    assert(len(bezpath)%N == 1, str("A degree ",N," bezier path shound have a multiple of ",N," points in it, plus 1."))
    let(curve = select(bezpath,seg*N,(seg+1)*N))
    (seg*N+1 >= len(bezpath))? (
        let(curve = select(bezpath, min_seg*N, (min_seg+1)*N))
        [min_seg, bezier_closest_point(curve, pt, max_err=max_err)]
    ) : (
        let(
            curve = select(bezpath,seg*N,(seg+1)*N),
            u = bezier_closest_point(curve, pt, max_err=0.05),
            dist = norm(bezier_points(curve, u)-pt),
            mseg = (min_dist==undef || dist<min_dist)? seg : min_seg,
            mdist = (min_dist==undef || dist<min_dist)? dist : min_dist,
            mu = (min_dist==undef || dist<min_dist)? u : min_u
        )
        bezpath_closest_point(bezpath, pt, N, max_err, seg+1, mseg, mu, mdist)
    );



// Function: bezpath_length()
// Usage:
//   plen = bezpath_length(path, [N], [max_deflect]);
// Topics: Bezier Paths
// See Also: bezier_points(), bezier_curve(), bezier_length()
// Description:
//   Approximates the length of the bezier path.
// Arguments:
//   path = A bezier path to approximate.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
//   max_deflect = The largest amount of deflection from the true curve to allow for approximation.
function bezpath_length(bezpath, N=3, max_deflect=0.001) =
    assert(is_int(N))
    assert(is_num(max_deflect))
    assert(len(bezpath)%N == 1, str("A degree ",N," bezier path shound have a multiple of ",N," points in it, plus 1."))
    sum([
        for (seg=[0:1:(len(bezpath)-1)/N-1]) (
            bezier_length(
                select(bezpath, seg*N, (seg+1)*N),
                max_deflect=max_deflect
            )
        )
    ]);



// Function: path_to_bezpath()
// Usage:
//   bezpath = path_to_bezpath(path, [closed], [tangents], [uniform], [size=]|[relsize=]);
// Topics: Bezier Paths, Rounding
// See Also: path_tangents()
// Description:
//   Given a 2d or 3d input path and optional list of tangent vectors, computes a cubic (degree 3) bezier
//   path that passes through every point on the input path and matches the tangent vectors.  If you do
//   not supply the tangent it will be computed using `path_tangents()`.  If the path is closed specify this
//   by setting `closed=true`.  The size or relsize parameter determines how far the curve can deviate from
//   the input path.  In the case where the curve has a single hump, the size specifies the exact distance
//   between the specified path and the bezier.  If you give relsize then it is relative to the segment
//   length (e.g. 0.05 means 5% of the segment length).  In 2d when the bezier curve makes an S-curve
//   the size parameter specifies the sum of the deviations of the two peaks of the curve.  In 3-space
//   the bezier curve may have three extrema: two maxima and one minimum.  In this case the size specifies
//   the sum of the maxima minus the minimum.  If you do not supply the tangents then they are computed
//   using `path_tangents()` with `uniform=false` by default.  Tangents computed on non-uniform data tend
//   to display overshoots.  See `smooth_path()` for examples.
// Arguments:
//   path = 2D or 3D point list or 1-region that the curve must pass through
//   closed = true if the curve is closed .  Default: false
//   tangents = tangents constraining curve direction at each point
//   uniform = set to true to compute tangents with uniform=true.  Default: false
//   ---
//   size = absolute size specification for the curve, a number or vector
//   relsize = relative size specification for the curve, a number or vector.  Default: 0.1. 
function path_to_bezpath(path, closed, tangents, uniform=false, size, relsize) =
    is_1region(path) ? path_to_bezpath(path[0], default(closed,true), tangents, uniform, size, relsize) :
    let(closed=default(closed,false))
    assert(is_bool(closed))
    assert(is_bool(uniform))
    assert(num_defined([size,relsize])<=1, "Can't define both size and relsize")
    assert(is_path(path,[2,3]),"Input path is not a valid 2d or 3d path")
    assert(is_undef(tangents) || is_path(tangents,[2,3]),"Tangents must be a 2d or 3d path")
    assert(is_undef(tangents) || len(path)==len(tangents), "Input tangents must be the same length as the input path")
    let(
        curvesize = first_defined([size,relsize,0.1]),
        relative = is_undef(size),
        lastpt = len(path) - (closed?0:1)
    )
    assert(is_num(curvesize) || len(curvesize)==lastpt, str("Size or relsize must have length ",lastpt))
    let(
        sizevect = is_num(curvesize) ? repeat(curvesize, lastpt) : curvesize,
        tangents = is_def(tangents) ? [for(t=tangents) let(n=norm(t)) assert(!approx(n,0),"Zero tangent vector") t/n] :
                                      path_tangents(path, uniform=uniform, closed=closed)
    )
    assert(min(sizevect)>0, "Size and relsize must be greater than zero")
    [
        for(i=[0:1:lastpt-1])
            let(
                first = path[i],
                second = select(path,i+1),
                seglength = norm(second-first),
                dummy = assert(seglength>0, str("Path segment has zero length from index ",i," to ",i+1)),
                segdir = (second-first)/seglength,
                tangent1 = tangents[i],
                tangent2 = -select(tangents,i+1),                        // Need this to point backwards, in direction of the curve
                parallel = abs(tangent1*segdir) + abs(tangent2*segdir), // Total component of tangents parallel to the segment
                Lmax = seglength/parallel,    // May be infinity
                size = relative ? sizevect[i]*seglength : sizevect[i],
                normal1 = tangent1-(tangent1*segdir)*segdir,   // Components of the tangents orthogonal to the segment
                normal2 = tangent2-(tangent2*segdir)*segdir,
                p = [ [-3 ,6,-3 ],                   // polynomial in power form
                      [ 7,-9, 2 ],
                      [-5, 3, 0 ],
                      [ 1, 0, 0 ] ]*[normal1*normal1, normal1*normal2, normal2*normal2],
                uextreme = approx(norm(p),0) ? []
                                             : [for(root = real_roots(p)) if (root>0 && root<1) root],
                distlist = [for(d=bezier_points([normal1*0, normal1, normal2, normal2*0], uextreme)) norm(d)],
                scale = len(distlist)==0 ? 0 :
                        len(distlist)==1 ? distlist[0]
                                         : sum(distlist) - 2*min(distlist),
                Ldesired = size/scale,   // This will be infinity when the polynomial is zero
                L = min(Lmax, Ldesired)
            )
            each [
                  first, 
                  first + L*tangent1,
                  second + L*tangent2 
                 ],
        select(path,lastpt)
    ];




// Function: bezpath_close_to_axis()
// Usage:
//   bezpath = bezpath_close_to_axis(bezpath, [axis], [N]);
// Topics: Bezier Paths
// See Also: bezpath_offset()
// Description:
//   Takes a 2D bezier path and closes it to the specified axis.
// Arguments:
//   bezpath = The 2D bezier path to close to the axis.
//   axis = The axis to close to, "X", or "Y".  Default: "X"
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [[50,30], [40,10], [10,50], [0,30],
//          [-10, 10], [-30,10], [-50,20]];
//   closed = bezpath_close_to_axis(bez);
//   debug_bezier(closed);
// Example(2D):
//   bez = [[30,50], [10,40], [50,10], [30,0],
//          [10, -10], [10,-30], [20,-50]];
//   closed = bezpath_close_to_axis(bez, axis="Y");
//   debug_bezier(closed);
function bezpath_close_to_axis(bezpath, axis="X", N=3) =
    assert(is_path(bezpath,2), "bezpath_close_to_axis() can only work on 2D bezier paths.")
    assert(is_int(N))
    assert(len(bezpath)%N == 1, str("A degree ",N," bezier path shound have a multiple of ",N," points in it, plus 1."))
    let(
        sp = bezpath[0],
        ep = last(bezpath)
    ) (axis=="X")? concat(
        lerpn([sp.x,0], sp, N, false),
        list_head(bezpath),
        lerpn(ep, [ep.x,0], N, false),
        lerpn([ep.x,0], [sp.x,0], N+1)
    ) : (axis=="Y")? concat(
        lerpn([0,sp.y], sp, N, false),
        list_head(bezpath),
        lerpn(ep, [0,ep.y], N, false),
        lerpn([0,ep.y], [0,sp.y], N+1)
    ) : (
        assert(in_list(axis, ["X","Y"]))
    );


// Function: bezpath_offset()
// Usage:
//   bezpath = bezpath_offset(offset, bezier, [N]);
// Topics: Bezier Paths
// See Also: bezpath_close_to_axis()
// Description:
//   Takes a 2D bezier path and closes it with a matching reversed path that is offset by the given `offset` [X,Y] distance.
// Arguments:
//   offset = Amount to offset second path by.
//   bezier = The 2D bezier path.
//   N = The degree of the bezier curves.  Cubic beziers have N=3.  Default: 3
// Example(2D):
//   bez = [[50,30], [40,10], [10,50], [0,30], [-10, 10], [-30,10], [-50,20]];
//   closed = bezpath_offset([0,-5], bez);
//   debug_bezier(closed);
// Example(2D):
//   bez = [[30,50], [10,40], [50,10], [30,0], [10, -10], [10,-30], [20,-50]];
//   closed = bezpath_offset([-5,0], bez);
//   debug_bezier(closed);
function bezpath_offset(offset, bezier, N=3) =
    assert(is_vector(offset,2))
    assert(is_path(bezier,2), "bezpath_offset() can only work on 2D bezier paths.")
    assert(is_int(N))
    assert(len(bezier)%N == 1, str("A degree ",N," bezier path shound have a multiple of ",N," points in it, plus 1."))
    let(
        backbez = reverse([ for (pt = bezier) pt+offset ]),
        bezend = len(bezier)-1
    ) concat(
        list_head(bezier),
        lerpn(bezier[bezend], backbez[0], N, false),
        list_head(backbez),
        lerpn(backbez[bezend], bezier[0], N+1)
    );



// Section: Cubic Bezier Path Construction

// Function: bez_begin()
// Topics: Bezier Paths
// See Also: bez_tang(), bez_joint(), bez_end()
// Usage:
//   pts = bez_begin(pt, a, r, [p=]);
//   pts = bez_begin(pt, VECTOR, [r], [p=]);
// Description:
//   This is used to create the first endpoint and control point of a cubic bezier path.
// Arguments:
//   pt = The starting endpoint for the bezier path.
//   a = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the first control point.
//   r = Specifies the distance of the control point from the endpoint `pt`.
//   p = If given, specifies the number of degrees away from the Z+ axis.
// Example(2D): 2D Bezier Path by Angle
//   bezpath = flatten([
//       bez_begin([-50,  0],  45,20),
//       bez_tang ([  0,  0],-135,20),
//       bez_joint([ 20,-25], 135, 90, 10, 15),
//       bez_end  ([ 50,  0], -90,20),
//   ]);
//   debug_bezier(bezpath);
// Example(2D): 2D Bezier Path by Vector
//   bezpath = flatten([
//       bez_begin([-50,0],[0,-20]),
//       bez_tang ([-10,0],[0,-20]),
//       bez_joint([ 20,-25], [-10,10], [0,15]),
//       bez_end  ([ 50,0],[0, 20]),
//   ]);
//   debug_bezier(bezpath);
// Example(2D): 2D Bezier Path by Vector and Distance
//   bezpath = flatten([
//       bez_begin([-30,0],FWD, 30),
//       bez_tang ([  0,0],FWD, 30),
//       bez_joint([ 20,-25], 135, 90, 10, 15),
//       bez_end  ([ 30,0],BACK,30),
//   ]);
//   debug_bezier(bezpath);
// Example(3D,FlatSpin,VPD=200): 3D Bezier Path by Angle
//   bezpath = flatten([
//       bez_begin([-30,0,0],90,20,p=135),
//       bez_tang ([  0,0,0],-90,20,p=135),
//       bez_joint([20,-25,0], 135, 90, 15, 10, p1=135, p2=45),
//       bez_end  ([ 30,0,0],-90,20,p=45),
//   ]);
//   debug_bezier(bezpath);
// Example(3D,FlatSpin,VPD=225): 3D Bezier Path by Vector
//   bezpath = flatten([
//       bez_begin([-30,0,0],[0,-20, 20]),
//       bez_tang ([  0,0,0],[0,-20,-20]),
//       bez_joint([20,-25,0],[0,10,-10],[0,15,15]),
//       bez_end  ([ 30,0,0],[0,-20,-20]),
//   ]);
//   debug_bezier(bezpath);
// Example(3D,FlatSpin,VPD=225): 3D Bezier Path by Vector and Distance
//   bezpath = flatten([
//       bez_begin([-30,0,0],FWD, 20),
//       bez_tang ([  0,0,0],DOWN,20),
//       bez_joint([20,-25,0],LEFT,DOWN,r1=20,r2=15),
//       bez_end  ([ 30,0,0],DOWN,20),
//   ]);
//   debug_bezier(bezpath);
function bez_begin(pt,a,r,p) =
    assert(is_finite(r) || is_vector(a))
    assert(len(pt)==3 || is_undef(p))
    is_vector(a)? [pt, pt+(is_undef(r)? a : r*unit(a))] :
    is_finite(a)? [pt, pt+spherical_to_xyz(r,a,default(p,90))] :
    assert(false, "Bad arguments.");


// Function: bez_tang()
// Topics: Bezier Paths
// See Also: bez_begin(), bez_joint(), bez_end()
// Usage:
//   pts = bez_tang(pt, a, r1, r2, [p=]);
//   pts = bez_tang(pt, VECTOR, [r1], [r2], [p=]);
// Description:
//   This creates a smooth joint in a cubic bezier path.  It creates three points, being the
//   approaching control point, the fixed bezier control point, and the departing control
//   point.  The two control points will be collinear with the fixed point, making for a
//   smooth bezier curve at the fixed point. See {{bez_begin()}} for examples.
// Arguments:
//   pt = The fixed point for the bezier path.
//   a = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the departing control point.
//   r1 = Specifies the distance of the approching control point from the fixed point.  Overrides the distance component of the vector if `a` contains a vector.
//   r2 = Specifies the distance of the departing control point from the fixed point.  Overrides the distance component of the vector if `a` contains a vector.  If `r1` is given and `r2` is not, uses the value of `r1` for `r2`.
//   p = If given, specifies the number of degrees away from the Z+ axis.
function bez_tang(pt,a,r1,r2,p) =
    assert(is_finite(r1) || is_vector(a))
    assert(len(pt)==3 || is_undef(p))
    let(
        r1 = is_num(r1)? r1 : norm(a),
        r2 = default(r2,r1),
        p = default(p, 90)
    )
    is_vector(a)? [pt-r1*unit(a), pt, pt+r2*unit(a)] :
    is_finite(a)? [
        pt-spherical_to_xyz(r1,a,p),
        pt,
        pt+spherical_to_xyz(r2,a,p)
    ] :
    assert(false, "Bad arguments.");


// Function: bez_joint()
// Topics: Bezier Paths
// See Also: bez_begin(), bez_tang(), bez_end()
// Usage:
//   pts = bez_joint(pt, a1, a2, r1, r2, [p1=], [p2=]);
//   pts = bez_joint(pt, VEC1, VEC2, [r1=], [r2=], [p1=], [p2=]);
// Description:
//   This creates a disjoint corner joint in a cubic bezier path.  It creates three points, being
//   the aproaching control point, the fixed bezier control point, and the departing control point.
//   The two control points can be directed in different arbitrary directions from the fixed bezier
//   point. See {{bez_begin()}} for examples.
// Arguments:
//   pt = The fixed point for the bezier path.
//   a1 = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the approaching control point.
//   a2 = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the departing control point.
//   r1 = Specifies the distance of the approching control point from the fixed point.  Overrides the distance component of the vector if `a1` contains a vector.
//   r2 = Specifies the distance of the departing control point from the fixed point.  Overrides the distance component of the vector if `a2` contains a vector.
//   p1 = If given, specifies the number of degrees away from the Z+ axis of the approaching control point.
//   p2 = If given, specifies the number of degrees away from the Z+ axis of the departing control point.
function bez_joint(pt,a1,a2,r1,r2,p1,p2) =
    assert(is_finite(r1) || is_vector(a1))
    assert(is_finite(r2) || is_vector(a2))
    assert(len(pt)==3 || (is_undef(p1) && is_undef(p2)))
    let(
        r1 = is_num(r1)? r1 : norm(a1),
        r2 = is_num(r2)? r2 : norm(a2),
        p1 = default(p1, 90),
        p2 = default(p2, 90)
    ) [
        if (is_vector(a1)) (pt+r1*unit(a1))
        else if (is_finite(a1)) (pt+spherical_to_xyz(r1,a1,p1))
        else assert(false, "Bad Arguments"),
        pt,
        if (is_vector(a2)) (pt+r2*unit(a2))
        else if (is_finite(a2)) (pt+spherical_to_xyz(r2,a2,p2))
        else assert(false, "Bad Arguments")
    ];


// Function: bez_end()
// Topics: Bezier Paths
// See Also: bez_tang(), bez_joint(), bez_end()
// Usage:
//   pts = bez_end(pt, a, r, [p=]);
//   pts = bez_end(pt, VECTOR, [r], [p=]);
// Description:
//   This is used to create the approaching control point, and the endpoint of a cubic bezier path.
//   See {{bez_begin()}} for examples.
// Arguments:
//   pt = The starting endpoint for the bezier path.
//   a = If given a scalar, specifies the theta (XY plane) angle in degrees from X+.  If given a vector, specifies the direction and possibly distance of the first control point.
//   r = Specifies the distance of the control point from the endpoint `pt`.
//   p = If given, specifies the number of degrees away from the Z+ axis.
function bez_end(pt,a,r,p) =
    assert(is_finite(r) || is_vector(a))
    assert(len(pt)==3 || is_undef(p))
    is_vector(a)? [pt+(is_undef(r)? a : r*unit(a)), pt] :
    is_finite(a)? [pt+spherical_to_xyz(r,a,default(p,90)), pt] :
    assert(false, "Bad arguments.");



// Section: Bezier Surfaces


// Function: is_bezier_patch()
// Usage:
//   bool = is_bezier_patch(x);
// Topics: Bezier Patches, Type Checking
// Description:
//   Returns true if the given item is a bezier patch.
// Arguments:
//   x = The value to check the type of.
function is_bezier_patch(x) =
    is_list(x) && is_list(x[0]) && is_vector(x[0][0]) && len(x[0]) == len(x[len(x)-1]);  


// Function: bezier_patch_flat()
// Usage:
//   patch = bezier_patch_flat(size, [N=], [spin=], [orient=], [trans=]);
// Topics: Bezier Patches
// See Also: bezier_patch_points()
// Description:
//   Returns a flat rectangular bezier patch of degree `N`, centered on the XY plane.
// Arguments:
//   size = 2D XY size of the patch.
//   ---
//   N = Degree of the patch to generate.  Since this is flat, a degree of 1 should usually be sufficient.
//   orient = The orientation to rotate the edge patch into.  Given as an [X,Y,Z] rotation angle list.
//   trans = Amount to translate patch, after rotating to `orient`.
// Example(3D):
//   patch = bezier_patch_flat(size=[100,100], N=3);
//   debug_bezier_patches([patch], size=1, showcps=true);
function bezier_patch_flat(size=[100,100], N=4, spin=0, orient=UP, trans=[0,0,0]) =
    let(
        patch = [
            for (x=[0:1:N]) [
                for (y=[0:1:N])
                v_mul(point3d(size), [x/N-0.5, 0.5-y/N, 0])
            ]
        ],
        m = move(trans) * rot(a=spin, from=UP, to=orient)
    ) [for (row=patch) apply(m, row)];



// Function: bezier_patch_reverse()
// Usage:
//   rpatch = bezier_patch_reverse(patch);
// Topics: Bezier Patches
// See Also: bezier_patch_points(), bezier_patch_flat()
// Description:
//   Reverses the patch, so that the faces generated from it are flipped back to front.
// Arguments:
//   patch = The patch to reverse.
function bezier_patch_reverse(patch) =
    [for (row=patch) reverse(row)];


// Function: bezier_patch_points()
// Usage:
//   pt = bezier_patch_points(patch, u, v);
//   ptgrid = bezier_patch_points(patch, LIST, LIST);
//   ptgrid = bezier_patch_points(patch, RANGE, RANGE);
// Topics: Bezier Patches
// See Also: bezier_points(), bezier_curve(), bezpath_curve()
// Description:
//   Given a square 2-dimensional array of (N+1) by (N+1) points size, that represents a Bezier Patch
//   of degree N, returns a point on that surface, at positions `u`, and `v`.  A cubic bezier patch
//   will be 4x4 points in size.  If given a non-square array, each direction will have its own
//   degree.
// Arguments:
//   patch = The 2D array of control points for a Bezier patch.
//   u = The proportion of the way along the horizontal inner list of the patch to find the point of.  0<=`u`<=1.  If given as a list or range of values, returns a list of point lists.
//   v = The proportion of the way along the vertical outer list of the patch to find the point of.  0<=`v`<=1.  If given as a list or range of values, returns a list of point lists.
// Example(3D):
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]]
//   ];
//   debug_bezier_patches(patches=[patch], size=1, showcps=true);
//   pt = bezier_patch_points(patch, 0.6, 0.75);
//   translate(pt) color("magenta") sphere(d=3, $fn=12);
// Example(3D): Getting Multiple Points at Once
//   patch = [
//       [[-50, 50,  0], [-16, 50,  20], [ 16, 50,  20], [50, 50,  0]],
//       [[-50, 16, 20], [-16, 16,  40], [ 16, 16,  40], [50, 16, 20]],
//       [[-50,-16, 20], [-16,-16,  40], [ 16,-16,  40], [50,-16, 20]],
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50,  20], [50,-50,  0]]
//   ];
//   debug_bezier_patches(patches=[patch], size=1, showcps=true);
//   pts = bezier_patch_points(patch, [0:0.2:1], [0:0.2:1]);
//   for (row=pts) move_copies(row) color("magenta") sphere(d=3, $fn=12);
function bezier_patch_points(patch, u, v) =
    is_num(u) && is_num(v)? bezier_points([for (bez = patch) bezier_points(bez, u)], v) :
    assert(is_num(u) || !is_undef(u[0]))
    assert(is_num(v) || !is_undef(v[0]))
    let(
        vbezes = [for (i = idx(patch[0])) bezier_points(column(patch,i), is_num(u)? [u] : u)]
    )
    [for (i = idx(vbezes[0])) bezier_points(column(vbezes,i), is_num(v)? [v] : v)];


function _bezier_rectangle(patch, splinesteps=16, style="default") =
    let(
        uvals = lerpn(0,1,splinesteps.x+1),
        vvals = lerpn(1,0,splinesteps.y+1),
        pts = bezier_patch_points(patch, uvals, vvals)
    )
    vnf_vertex_array(pts, style=style, reverse=false);


// Function: bezier_vnf()
// Usage:
//   vnf = bezier_vnf(patches, [splinesteps], [style]);
// Topics: Bezier Patches
// See Also: bezier_patch_points(), bezier_patch_flat()
// Description:
//   Convert a patch or list of patches into the corresponding Bezier surface, representing the
//   result as a [VNF structure](vnf.scad).  The `splinesteps` argument specifies the sampling grid of
//   the surface for each patch by specifying the number of segments on the borders of the surface.
//   It can be a scalar, which gives a uniform grid, or
//   it can be [USTEPS, VSTEPS], which gives difference spacing in the U and V parameters. 
//   Note that the surface you produce may be disconnected and is not necessarily a valid manifold in OpenSCAD.
// Arguments:
//   patches = The bezier patch or list of bezier patches to convert into a vnf.
//   splinesteps = Number of segments on the border of the bezier surface.  You can specify [USTEPS,VSTEPS].  Default: 16
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", "min_edge", "quincunx", "convex" and "concave".  See {{vnf_vertex_array()}}.  Default: "default"
// Example(3D):
//   patch = [
//       // u=0,v=0                                         u=1,v=0
//       [[-50,-50,  0], [-16,-50,  20], [ 16,-50, -20], [50,-50,  0]],
//       [[-50,-16, 20], [-16,-16,  20], [ 16,-16, -20], [50,-16, 20]],
//       [[-50, 16, 20], [-16, 16, -20], [ 16, 16,  20], [50, 16, 20]],
//       [[-50, 50,  0], [-16, 50, -20], [ 16, 50,  20], [50, 50,  0]],
//       // u=0,v=1                                         u=1,v=1
//   ];
//   vnf = bezier_vnf(patch, splinesteps=16);
//   vnf_polyhedron(vnf);
// Example(3D,FlatSpin,VPD=444): Combining multiple patches
//   patch = [
//       // u=0,v=0                                u=1,v=0
//       [[0,  0,0], [33,  0,  0], [67,  0,  0], [100,  0,0]],
//       [[0, 33,0], [33, 33, 33], [67, 33, 33], [100, 33,0]],
//       [[0, 67,0], [33, 67, 33], [67, 67, 33], [100, 67,0]],
//       [[0,100,0], [33,100,  0], [67,100,  0], [100,100,0]],
//       // u=0,v=1                                u=1,v=1
//   ];
//   tpatch = translate([-50,-50,50], patch);
//   vnf = bezier_vnf([
//                     tpatch,
//                     xrot(90, tpatch),
//                     xrot(-90, tpatch),
//                     xrot(180, tpatch),
//                     yrot(90, tpatch),
//                     yrot(-90, tpatch)]);
//   vnf_polyhedron(vnf);
// Example(3D):
//   patch1 = [
//       [[18,18,0], [33,  0,  0], [ 67,  0,  0], [ 82, 18,0]],
//       [[ 0,40,0], [ 0,  0,100], [100,  0, 20], [100, 40,0]],
//       [[ 0,60,0], [ 0,100,100], [100,100, 20], [100, 60,0]],
//       [[18,82,0], [33,100,  0], [ 67,100,  0], [ 82, 82,0]],
//   ];
//   patch2 = [
//       [[18,82,0], [33,100,  0], [ 67,100,  0], [ 82, 82,0]],
//       [[ 0,60,0], [ 0,100,-50], [100,100,-50], [100, 60,0]],
//       [[ 0,40,0], [ 0,  0,-50], [100,  0,-50], [100, 40,0]],
//       [[18,18,0], [33,  0,  0], [ 67,  0,  0], [ 82, 18,0]],
//   ];
//   vnf = bezier_vnf(patches=[patch1, patch2], splinesteps=16);
//   vnf_polyhedron(vnf);
// Example(3D): Connecting Patches with asymmetric splinesteps.  Note it is fastest to join all the VNFs at once, which happens in vnf_polyhedron, rather than generating intermediate joined partial surfaces.  
//   steps = 8;
//   edge_patch = [
//       // u=0, v=0                    u=1,v=0
//       [[-60, 0,-40], [0, 0,-40], [60, 0,-40]],
//       [[-60, 0,  0], [0, 0,  0], [60, 0,  0]],
//       [[-60,40,  0], [0,40,  0], [60,40,  0]],
//       // u=0, v=1                    u=1,v=1
//   ];
//   corner_patch = [
//       // u=0, v=0                    u=1,v=0
//       [[ 0, 40,-40], [ 0,  0,-40], [40,  0,-40]],
//       [[ 0, 40,  0], [ 0,  0,  0], [40,  0,  0]],
//       [[40, 40,  0], [40, 40,  0], [40, 40,  0]],
//       // u=0, v=1                    u=1,v=1
//   ];
//   face_patch = bezier_patch_flat([120,120],orient=LEFT);
//   edges = [
//       for (axrot=[[0,0,0],[0,90,0],[0,0,90]], xang=[-90:90:180])
//           bezier_vnf(
//               splinesteps=[steps,1],
//               rot(a=axrot,
//                   p=rot(a=[xang,0,0],
//                       p=translate(v=[0,-100,100],p=edge_patch)
//                   )
//               )
//           )
//   ];
//   corners = [
//       for (xang=[0,180], zang=[-90:90:180])
//           bezier_vnf(
//               splinesteps=steps,
//               rot(a=[xang,0,zang],
//                   p=translate(v=[-100,-100,100],p=corner_patch)
//               )
//           )
//   ];
//   faces = [
//       for (axrot=[[0,0,0],[0,90,0],[0,0,90]], zang=[0,180])
//           bezier_vnf(
//               splinesteps=1,
//               rot(a=axrot,
//                   p=zrot(zang,move([-100,0,0], face_patch))
//               )
//           )
//   ];
//   vnf_polyhedron(concat(edges,corners,faces));
function bezier_vnf(patches=[], splinesteps=16, style="default") =
    assert(is_num(splinesteps) || is_vector(splinesteps,2))
    assert(all_positive(splinesteps))
    let(splinesteps = force_list(splinesteps,2))
    is_bezier_patch(patches)? _bezier_rectangle(patches, splinesteps=splinesteps,style=style)
  : assert(is_list(patches),"Invalid patch list")
    vnf_join(
      [
        for (patch=patches)
          is_bezier_patch(patch)? _bezier_rectangle(patch, splinesteps=splinesteps,style=style)
        : assert(false,"Invalid patch list")
      ]
    );
          


// Function: bezier_vnf_degenerate_patch()
// Usage:
//   vnf = bezier_vnf_degenerate_patch(patch, [splinesteps], [reverse]);
//   vnf_edges = bezier_vnf_degenerate_patch(patch, [splinesteps], [reverse], return_edges=true);
// Description:
//   Returns a VNF for a degenerate rectangular bezier patch where some of the corners of the patch are
//   equal.  If the resulting patch has no faces then returns an empty VNF.  Note that due to the degeneracy,
//   the shape of the surface can be triangular even though the underlying patch is a rectangle.  
//   If you specify return_edges then the return is a list whose first element is the vnf and whose second
//   element lists the edges in the order [left, right, top, bottom], where each list is a list of the actual
//   point values, but possibly only a single point if that edge is degenerate.
//   The method checks for various types of degeneracy and uses a triangular or partly triangular array of sample points. 
//   See examples below for the types of degeneracy detected and how the patch is sampled for those cases.
//   Note that splinesteps is the same for both directions of the patch, so it cannot be an array. 
// Arguments:
//   patch = Patch to process
//   splinesteps = Number of segments to produce on each side.  Default: 16
//   reverse = reverse direction of faces.  Default: false
//   return_edges = if true return the points on the four edges: [left, right, top, bottom].  Default: false
// Example(3D,NoAxes): This quartic patch is degenerate at one corner, where a row of control points are equal.  Processing this degenerate patch normally produces excess triangles near the degenerate point. 
//   splinesteps=8;
//   patch=[
//         repeat([-12.5, 12.5, 15],5),
//          [[-6.25, 11.25, 15], [-6.25, 8.75, 15], [-6.25, 6.25, 15], [-8.75, 6.25, 15], [-11.25, 6.25, 15]],
//          [[0, 10, 15], [0, 5, 15], [0, 0, 15], [-5, 0, 15], [-10, 0, 15]],
//          [[0, 10, 8.75], [0, 5, 8.75], [0, 0, 8.75], [-5, 0, 8.75], [-10, 0, 8.75]],
//          [[0, 10, 2.5], [0, 5, 2.5], [0, 0, 2.5], [-5, 0, 2.5], [-10, 0, 2.5]]
//         ];
//   vnf_wireframe((bezier_vnf(patch, splinesteps)),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): With bezier_vnf_degenerate_patch the degenerate point does not have excess triangles.  The top half of the patch decreases the number of sampled points by 2 for each row.  
//   splinesteps=8;
//   patch=[
//          repeat([-12.5, 12.5, 15],5),
//          [[-6.25, 11.25, 15], [-6.25, 8.75, 15], [-6.25, 6.25, 15], [-8.75, 6.25, 15], [-11.25, 6.25, 15]],
//          [[0, 10, 15], [0, 5, 15], [0, 0, 15], [-5, 0, 15], [-10, 0, 15]],
//          [[0, 10, 8.75], [0, 5, 8.75], [0, 0, 8.75], [-5, 0, 8.75], [-10, 0, 8.75]],
//          [[0, 10, 2.5], [0, 5, 2.5], [0, 0, 2.5], [-5, 0, 2.5], [-10, 0, 2.5]]
//         ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): With splinesteps odd you get one "odd" row where the point count decreases by 1 instead of 2.  You may prefer even values for splinesteps to avoid this. 
//   splinesteps=7;
//   patch=[
//          repeat([-12.5, 12.5, 15],5),
//          [[-6.25, 11.25, 15], [-6.25, 8.75, 15], [-6.25, 6.25, 15], [-8.75, 6.25, 15], [-11.25, 6.25, 15]],
//          [[0, 10, 15], [0, 5, 15], [0, 0, 15], [-5, 0, 15], [-10, 0, 15]],
//          [[0, 10, 8.75], [0, 5, 8.75], [0, 0, 8.75], [-5, 0, 8.75], [-10, 0, 8.75]],
//          [[0, 10, 2.5], [0, 5, 2.5], [0, 0, 2.5], [-5, 0, 2.5], [-10, 0, 2.5]]
//         ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): A more extreme degeneracy occurs when the top half of a patch is degenerate to a line.  (For odd length patches the middle row must be degenerate to trigger this style.)  In this case the number of points in each row decreases by 1 for every row.  It doesn't matter of splinesteps is odd or even. 
//   splinesteps=8;
//   patch = [[[10, 0, 0], [10, -10.4, 0], [10, -20.8, 0], [1.876, -14.30, 0], [-6.24, -7.8, 0]],
//            [[5, 0, 0], [5, -5.2, 0], [5, -10.4, 0], [0.938, -7.15, 0], [-3.12, -3.9, 0]],
//            repeat([0,0,0],5),
//            repeat([0,0,5],5),
//            repeat([0,0,10],5)
//           ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoScales): Here is a degenerate cubic patch.
//   splinesteps=8;
//   patch = [ [ [-20,0,0],  [-10,0,0],[0,10,0],[0,20,0] ],
//             [ [-20,0,10], [-10,0,10],[0,10,10],[0,20,10]],
//             [ [-10,0,20], [-5,0,20], [0,5,20], [0,10,20]],
//              repeat([0,0,30],4)
//               ];
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
// Example(3D,NoScales): A more extreme degenerate cubic patch, where two rows are equal.
//   splinesteps=8;
//   patch = [ [ [-20,0,0], [-10,0,0],[0,10,0],[0,20,0] ],
//             [ [-20,0,10], [-10,0,10],[0,10,10],[0,20,10] ],
//              repeat([-10,10,20],4),
//              repeat([-10,10,30],4)          
//           ];
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
// Example(3D,NoScales): Quadratic patch degenerate at the right side:
//   splinesteps=8;
//   patch = [[[0, -10, 0],[10, -5, 0],[20, 0, 0]],
//            [[0, 0, 0],  [10, 0, 0], [20, 0, 0]],
//            [[0, 0, 10], [10, 0, 5], [20, 0, 0]]];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
// Example(3D,NoAxes): Cubic patch degenerate at both ends.  In this case the point count changes by 2 at every row.  
//   splinesteps=8;
//   patch = [
//            repeat([10,-10,0],4),
//            [ [-20,0,0], [-1,0,0],[0,10,0],[0,20,0] ],
//            [ [-20,0,10], [-10,0,10],[0,10,10],[0,20,10] ],
//            repeat([-10,10,20],4),
//           ];
//   vnf_wireframe(bezier_vnf_degenerate_patch(patch, splinesteps),width=0.1);
//   color("red")move_copies(flatten(patch)) sphere(r=0.3,$fn=9);
function bezier_vnf_degenerate_patch(patch, splinesteps=16, reverse=false, return_edges=false) =
    !return_edges ? bezier_vnf_degenerate_patch(patch, splinesteps, reverse, true)[0] :
    assert(is_bezier_patch(patch), "Input is not a Bezier patch")
    assert(is_int(splinesteps) && splinesteps>0, "splinesteps must be a positive integer")
    let(
        row_degen = [for(row=patch) all_equal(row)],
        col_degen = [for(col=transpose(patch)) all_equal(col)],
        top_degen = row_degen[0],
        bot_degen = last(row_degen),
        left_degen = col_degen[0],
        right_degen = last(col_degen),
        samplepts = lerpn(0,1,splinesteps+1)
    )
    all(row_degen) && all(col_degen) ?  // fully degenerate case
        [EMPTY_VNF, repeat([patch[0][0]],4)] :
    all(row_degen) ?                         // degenerate to a line (top to bottom)
        let(pts = bezier_points(column(patch,0), samplepts))
        [EMPTY_VNF, [pts,pts,[pts[0]],[last(pts)]]] :
    all(col_degen) ?                         // degenerate to a line (left to right)
        let(pts = bezier_points(patch[0], samplepts))
        [EMPTY_VNF, [[pts[0]], [last(pts)], pts, pts]] :
    !top_degen && !bot_degen && !left_degen && !right_degen ?       // non-degenerate case
       let(pts = bezier_patch_points(patch, samplepts, samplepts))
       [
        vnf_vertex_array(pts, reverse=!reverse),
        [column(pts,0), column(pts,len(pts)-1), pts[0], last(pts)]
       ] :
    top_degen && bot_degen ?
       let(
            rowcount = [
                        each list([3:2:splinesteps]),
                        if (splinesteps%2==0) splinesteps+1,
                        each reverse(list([3:2:splinesteps]))
                       ],
            bpatch = [for(i=[0:1:len(patch[0])-1]) bezier_points(column(patch,i), samplepts)],
            pts = [
                  [bpatch[0][0]],
                  for(j=[0:splinesteps-2]) bezier_points(column(bpatch,j+1), lerpn(0,1,rowcount[j])),
                  [last(bpatch[0])]
                  ],
            vnf = vnf_tri_array(pts, reverse=!reverse)
         ) [
            vnf,
            [
             column(pts,0),
             [for(row=pts) last(row)],
             pts[0],
             last(pts),
            ]
          ]  :    
    bot_degen ?                                           // only bottom is degenerate
       let(
           result = bezier_vnf_degenerate_patch(reverse(patch), splinesteps=splinesteps, reverse=!reverse, return_edges=true)
       )
       [
          result[0],
          [reverse(result[1][0]), reverse(result[1][1]), (result[1][3]), (result[1][2])]
       ] :
    top_degen ?                                          // only top is degenerate
       let(
           full_degen = len(patch)>=4 && all(select(row_degen,1,ceil(len(patch)/2-1))),
           rowmax = full_degen ? count(splinesteps+1) :
                                 [for(j=[0:splinesteps]) j<=splinesteps/2 ? 2*j : splinesteps],
           bpatch = [for(i=[0:1:len(patch[0])-1]) bezier_points(column(patch,i), samplepts)],
           pts = [
                  [bpatch[0][0]],
                  for(j=[1:splinesteps]) bezier_points(column(bpatch,j), lerpn(0,1,rowmax[j]+1))
                 ],
           vnf = vnf_tri_array(pts, reverse=!reverse)
        ) [
            vnf,
            [
             column(pts,0),
             [for(row=pts) last(row)],
             pts[0],
             last(pts),
            ]
          ] :
      // must have left or right degeneracy, so transpose and recurse
      let(
          result = bezier_vnf_degenerate_patch(transpose(patch), splinesteps=splinesteps, reverse=!reverse, return_edges=true)
      )
      [result[0],
       select(result[1],[2,3,0,1])
      ];




// Section: Debugging Beziers


// Module: debug_bezier()
// Usage:
//   debug_bezier(bez, [size], [N=]);
// Topics: Bezier Paths, Debugging
// See Also: bezpath_curve()
// Description:
//   Renders 2D or 3D bezier paths and their associated control points.
//   Useful for debugging bezier paths.
// Arguments:
//   bez = the array of points in the bezier.
//   size = diameter of the lines drawn.
//   ---
//   N = Mark the first and every Nth vertex after in a different color and shape.
// Example(2D):
//   bez = [
//       [-10,   0],  [-15,  -5],
//       [ -5, -10],  [  0, -10],  [ 5, -10],
//       [ 14,  -5],  [ 15,   0],  [16,   5],
//       [  5,  10],  [  0,  10]
//   ];
//   debug_bezier(bez, N=3, width=0.5);
module debug_bezier(bezpath, width=1, N=3) { 
    assert(is_path(bezpath));
    assert(is_int(N));
    assert(len(bezpath)%N == 1, str("A degree ",N," bezier path shound have a multiple of ",N," points in it, plus 1."));
    $fn=8;
    stroke(bezpath_curve(bezpath, N=N), width=width, color="cyan");
    color("green")
      if (N!=3) 
           stroke(bezpath, width=width);
      else 
           for(i=[1:3:len(bezpath)]) stroke(select(bezpath,max(0,i-2), min(len(bezpath)-1,i)), width=width);
    twodim = len(bezpath[0])==2;
    color("red") move_copies(bezpath)
      if ($idx % N !=0)
          if (twodim){
            rect([width/2, width*3]);
            rect([width*3, width/2]);
          } else {
           zcyl(d=width/2, h=width*3);
           xcyl(d=width/2, h=width*3);
           ycyl(d=width/2, h=width*3);
        }
    color("blue") move_copies(bezpath)
      if ($idx % N ==0)
        if (twodim) circle(d=width*2.25); else sphere(d=width*2.25);
    if (twodim) color("red") move_copies(bezpath)
      if ($idx % N !=0) circle(d=width/2);
}


// Module: debug_bezier_patches()
// Usage:
//   debug_bezier_patches(patches, [size=], [splinesteps=], [showcps=], [showdots=], [showpatch=], [convexity=], [style=]);
// Topics: Bezier Patches, Debugging
// See Also: bezier_patch_points(), bezier_patch_flat(), bezier_vnf()
// Description:
//   Shows the surface, and optionally, control points of a list of bezier patches.
// Arguments:
//   patches = A list of rectangular bezier patches.
//   ---
//   splinesteps = Number of segments to divide each bezier curve into. Default: 16
//   showcps = If true, show the controlpoints as well as the surface.  Default: true.
//   showdots = If true, shows the calculated surface vertices.  Default: false.
//   showpatch = If true, shows the surface faces.  Default: true.
//   size = Size to show control points and lines.
//   style = The style of subdividing the quads into faces.  Valid options are "default", "alt", and "quincunx".
//   convexity = Max number of times a line could intersect a wall of the shape.
// Example:
//   patch1 = [
//       [[15,15,0], [33,  0,  0], [ 67,  0,  0], [ 85, 15,0]],
//       [[ 0,33,0], [33, 33, 50], [ 67, 33, 50], [100, 33,0]],
//       [[ 0,67,0], [33, 67, 50], [ 67, 67, 50], [100, 67,0]],
//       [[15,85,0], [33,100,  0], [ 67,100,  0], [ 85, 85,0]],
//   ];
//   patch2 = [
//       [[15,85,0], [33,100,  0], [ 67,100,  0], [ 85, 85,0]],
//       [[ 0,67,0], [33, 67,-50], [ 67, 67,-50], [100, 67,0]],
//       [[ 0,33,0], [33, 33,-50], [ 67, 33,-50], [100, 33,0]],
//       [[15,15,0], [33,  0,  0], [ 67,  0,  0], [ 85, 15,0]],
//   ];
//   debug_bezier_patches(patches=[patch1, patch2], splinesteps=8, showcps=true);
module debug_bezier_patches(patches=[], size, splinesteps=16, showcps=true, showdots=false, showpatch=true, convexity=10, style="default")
{
    assert(is_undef(size)||is_num(size));
    assert(is_int(splinesteps) && splinesteps>0);
    assert(is_list(patches) && all([for (patch=patches) is_bezier_patch(patch)]));
    assert(is_bool(showcps));
    assert(is_bool(showdots));
    assert(is_bool(showpatch));
    assert(is_int(convexity) && convexity>0);
    for (patch = patches) {
        size = is_num(size)? size :
               let( bounds = pointlist_bounds(flatten(patch)) )
               max(bounds[1]-bounds[0])*0.01;
        if (showcps) {
            move_copies(flatten(patch)) color("red") sphere(d=size*2);
            color("cyan") 
                for (i=[0:1:len(patch)-1], j=[0:1:len(patch[i])-1]) {
                        if (i<len(patch)-1) extrude_from_to(patch[i][j], patch[i+1][j]) circle(d=size);
                        if (j<len(patch[i])-1) extrude_from_to(patch[i][j], patch[i][j+1]) circle(d=size);
                }        
        }
        if (showpatch || showdots){
            vnf = bezier_vnf(patch, splinesteps=splinesteps, style=style);
            if (showpatch) vnf_polyhedron(vnf, convexity=convexity);
            if (showdots) color("blue") move_copies(vnf[0]) sphere(d=size);
        }
    }
}


// vim: expandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
