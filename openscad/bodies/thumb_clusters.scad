include <../BOSL2/std.scad>
include <../switches/mx.scad>
include <../lib/utils.scad>

/*
    thumbradius
    angle
*/

module thumbCluster(
    thumbJointRadius,
    thumbTipRadius,
    outerZOffset,
    clusterRot,
    rowMarginMin,
    ofst = [0,0,0],
    colCount = 3
) {
    tr = thumbJointRadius - (mx_socket_perim_H / 2);
    otr = thumbTipRadius < mx_socket_perim_H ? mx_socket_perim_H : thumbTipRadius;
    currentMgn = otr - mx_socket_perim_H;
    mgn = rowMarginMin > currentMgn ? rowMarginMin : currentMgn;
    or = tr + otr + mgn;
    jointAngle = asin(mx_socket_perim_H / tr) * -1;
    angleOffset = jointAngle / -2;
    zOffset = mx_socket_total_D + ofst.z;

    clrs = ["red","blue","green","purple","cyan"];

    for(ci=[0:colCount-1]) {
        color(clrs[ci%len(clrs)]) {
            switchTopPts = [
                [ circPointX(jointAngle, angleOffset, tr, 0, ci) + ofst.x, circPointY(jointAngle, angleOffset, tr, 0, ci) + ofst.y, zOffset ]
                ,[ circPointX(jointAngle, angleOffset, tr, 0, ci+1) + ofst.x, circPointY(jointAngle, angleOffset, tr, 0, ci+1) + ofst.y, zOffset ]
                ,[ circPointX(jointAngle, angleOffset, tr + mx_socket_perim_H, 0, ci) + ofst.x, circPointY(jointAngle, angleOffset, tr + mx_socket_perim_H, 0, ci) + ofst.y, zOffset ]
                ,[ circPointX(jointAngle, angleOffset, tr + mx_socket_perim_H, 0, ci+1) + ofst.x, circPointY(jointAngle, angleOffset, tr + mx_socket_perim_H, 0, ci+1) + ofst.y, zOffset ]
                ,[ circPointX(jointAngle, angleOffset, or, 0, ci) + ofst.x, circPointY(jointAngle, angleOffset, or, 0, ci) + ofst.y, outerZOffset + zOffset ]
                ,[ circPointX(jointAngle, angleOffset, or, 0, ci+1) + ofst.x, circPointY(jointAngle, angleOffset, or, 0, ci+1) + ofst.y, outerZOffset + zOffset ]
                ,[ circPointX(jointAngle, angleOffset, or + mx_socket_perim_H, 0, ci) + ofst.x, circPointY(jointAngle, angleOffset, or + mx_socket_perim_H, 0, ci) + ofst.y, outerZOffset + zOffset ]
                ,[ circPointX(jointAngle, angleOffset, or + mx_socket_perim_H, 0, ci+1) + ofst.x, circPointY(jointAngle, angleOffset, or + mx_socket_perim_H, 0, ci+1) + ofst.y, outerZOffset + zOffset ]
            ];

            fsp = concat_mx([
                switchTopPts,
                offsetPoints(switchTopPts, [0, 0, -mx_socket_total_D])
            ]);

            /*
            
function circPointX(angle, angleOffset, radius, xOffset, edgeNo) =
    (cos((angle * -edgeNo) - angleOffset) * radius) + xOffset;
function circPointZ(angle, angleOffset, radius, zOffset, edgeNo) =
    (sin((angle * -edgeNo) - angleOffset) * radius) + zOffset;
function circPointY(angle, angleOffset, radius, yOffset, edgeNo) =
    (sin((angle * -edgeNo) - angleOffset) * radius) + yOffset;
            */

            sp = xrot(-clusterRot, fsp);
            // sp = fsp;
            // echo(clusterRot, sp);

            // Lower Level
            hull() polyhedron(
                points = [
                    sp[0],sp[1],sp[9],sp[8],
                    sp[2],sp[3],sp[11],sp[10]
                ],
                faces = [
                    [0,1,2,3],[4,5,6,7]
                ]
            );

            // Weld to upper level
            hull() polyhedron(
                points = [
                    sp[2],sp[3],sp[4],sp[5],sp[10],sp[11],sp[12],sp[13]
                ],
                faces = [
                    [0,1,5,4],[0,1,7,6],[0,1,3,2]
                ]
            );

            // Upper Level
            hull() polyhedron(
                points = [
                    sp[4],sp[5],sp[13],sp[12],
                    sp[6],sp[7],sp[15],sp[14]
                ],
                faces = [
                    [0,1,2,3],[4,5,6,7]
                ]
            );

            *plotPoints(sp);
            *plotPoints(upperWeldPoints);
        }
    }

    // a = asin((mx_socket_perim_W + am_screw_hole_top_R + am_screw_hole_thck) / thumbRadius);
    // for(i=[0:2]) zrot(i*-a, cp=[-thumbRadius-(mx_socket_perim_H / 2),0,0]) up(i*rotEle) zrot(90) mx_socket(nocut=true,center=true);

    // outerRad = thumbRadius + mx_socket_perim_H + rowMargin;
    // translate([mx_socket_perim_H + rowMargin, 0, outerZOffset]) for(i=[0:2]) zrot(i*-a, cp=[-outerRad-(mx_socket_perim_H / 2),0,0]) up(i*rotEle) zrot(90) mx_socket(nocut=true,center=true);

}
