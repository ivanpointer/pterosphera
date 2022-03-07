include <../BOSL2/std.scad>
include <../switches/mx.scad>
include <../lib/utils.scad>

module thumbCluster(
    thumbJointRadius,
    thumbTipRadius,
    outerZOffset,
    clusterRot,
    clusterAnchor,
    rowMarginMin,
    ofst = [0,0,0],
    colCount = 3
) {
    tr = thumbJointRadius; // - (mx_socket_perim_H / 2);
    trt = tr + mx_socket_perim_H;
    otr = thumbTipRadius < mx_socket_perim_H ? mx_socket_perim_H : thumbTipRadius;
    currentMgn = otr - mx_socket_perim_H;
    mgn = rowMarginMin > currentMgn ? rowMarginMin : currentMgn;
    or = tr + otr + mgn;
    ort = or + mx_socket_perim_H;
    jointAngle = asin(mx_socket_perim_H / tr) * -1;
    angleOffset = 0; //jointAngle / -2;
    zOffset = mx_socket_total_D + ofst.z;
    xOffset = -ort + ofst.x + clusterAnchor.x;

    borderAngle = asin(case_bezel / ort) * -1; // set the angle so that the width on the back corner of the bezel is what we want, narrowing it at the front
    borderLeftAngle = ((jointAngle * colCount) + borderAngle) * -1;

    bp = [
        // Right Edge
        [circPointX(-borderAngle, angleOffset, tr - case_bezel, xOffset, 1), circPointY(-borderAngle, angleOffset, tr - case_bezel, ofst.y, 1), zOffset]
        ,[circPointX(-borderAngle, angleOffset, trt, xOffset, 1), circPointY(-borderAngle, angleOffset, trt, ofst.y, 1), zOffset]
        ,[circPointX(-borderAngle, angleOffset, or, xOffset, 1), circPointY(-borderAngle, angleOffset, or, ofst.y, 1), outerZOffset + zOffset]
        ,[circPointX(-borderAngle, angleOffset, ort + case_bezel, xOffset, 1), circPointY(-borderAngle, angleOffset, ort + case_bezel, ofst.y, 1), outerZOffset + zOffset]

        // Left Edge
        ,[circPointX(-borderLeftAngle, angleOffset, tr - case_bezel, xOffset, 1), circPointY(-borderLeftAngle, angleOffset, tr - case_bezel, ofst.y, 1), zOffset]
        ,[circPointX(-borderLeftAngle, angleOffset, trt, xOffset, 1), circPointY(-borderLeftAngle, angleOffset, trt, ofst.y, 1), zOffset]
        ,[circPointX(-borderLeftAngle, angleOffset, or, xOffset, 1), circPointY(-borderLeftAngle, angleOffset, or, ofst.y, 1), outerZOffset + zOffset]
        ,[circPointX(-borderLeftAngle, angleOffset, ort + case_bezel, xOffset, 1), circPointY(-borderLeftAngle, angleOffset, ort + case_bezel, ofst.y, 1), outerZOffset + zOffset]
    ];

    rotAnchor = [circPointX(-borderAngle, angleOffset, ort + case_bezel, xOffset, 1), circPointY(-borderAngle, angleOffset, ort + case_bezel, ofst.y, 1), outerZOffset + zOffset];
    borderPoints = xrot(-clusterRot, bp, cp = rotAnchor);
    *plotPoints(borderPoints);

    clrs = ["red","blue","green","purple","cyan"];

    for(ci=[0:colCount-1]) {
        // Work out the points for the main switch pads
        switchTopPts = [
            [ circPointX(jointAngle, angleOffset, tr, 0, ci) + xOffset, circPointY(jointAngle, angleOffset, tr, 0, ci) + ofst.y, zOffset ]
            ,[ circPointX(jointAngle, angleOffset, tr, 0, ci+1) + xOffset, circPointY(jointAngle, angleOffset, tr, 0, ci+1) + ofst.y, zOffset ]
            ,[ circPointX(jointAngle, angleOffset, trt, 0, ci) + xOffset, circPointY(jointAngle, angleOffset, trt, 0, ci) + ofst.y, zOffset ]
            ,[ circPointX(jointAngle, angleOffset, trt, 0, ci+1) + xOffset, circPointY(jointAngle, angleOffset, trt, 0, ci+1) + ofst.y, zOffset ]
            ,[ circPointX(jointAngle, angleOffset, or, 0, ci) + xOffset, circPointY(jointAngle, angleOffset, or, 0, ci) + ofst.y, outerZOffset + zOffset ]
            ,[ circPointX(jointAngle, angleOffset, or, 0, ci+1) + xOffset, circPointY(jointAngle, angleOffset, or, 0, ci+1) + ofst.y, outerZOffset + zOffset ]
            ,[ circPointX(jointAngle, angleOffset, ort, 0, ci) + xOffset, circPointY(jointAngle, angleOffset, ort, 0, ci) + ofst.y, outerZOffset + zOffset ]
            ,[ circPointX(jointAngle, angleOffset, ort, 0, ci+1) + xOffset, circPointY(jointAngle, angleOffset, ort, 0, ci+1) + ofst.y, outerZOffset + zOffset ]
        ];
        fsp = concat_mx([
            switchTopPts,
            offsetPoints(switchTopPts, [0, 0, -mx_socket_total_D])
        ]);
        sp = xrot(-clusterRot, fsp, cp = rotAnchor);

        // Work out the points for the bezel around the cluster
        bezelPoints = [
            // Right Bezel
            [(cos(((jointAngle * -ci) + borderAngle) - angleOffset) * (tr - case_bezel)) + xOffset, (sin(((jointAngle * -ci) + borderAngle) - angleOffset) * (tr - case_bezel)) + ofst.y, zOffset]
            ,[(cos(((jointAngle * -ci) + borderAngle) - angleOffset) * trt) + xOffset, (sin(((jointAngle * -ci) + borderAngle) - angleOffset) * trt) + ofst.y, zOffset]
            ,[(cos(((jointAngle * -ci) + borderAngle) - angleOffset) * or) + xOffset, (sin(((jointAngle * -ci) + borderAngle) - angleOffset) * or) + ofst.y, zOffset + outerZOffset]
            ,[(cos(((jointAngle * -ci) + borderAngle) - angleOffset) * (ort + case_bezel)) + xOffset, (sin(((jointAngle * -ci) + borderAngle) - angleOffset) * (ort + case_bezel)) + ofst.y, zOffset + outerZOffset]
            
            // Left Bezel
            ,[(cos(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * (tr - case_bezel)) + xOffset, (sin(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * (tr - case_bezel)) + ofst.y, zOffset]
            ,[(cos(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * trt) + xOffset, (sin(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * trt) + ofst.y, zOffset]
            ,[(cos(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * or) + xOffset, (sin(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * or) + ofst.y, zOffset + outerZOffset]
            ,[(cos(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * (ort + case_bezel)) + xOffset, (sin(((jointAngle * -(ci+1)) - borderAngle) - angleOffset) * (ort + case_bezel)) + ofst.y, zOffset + outerZOffset]

            // Straight up the center for inner bezels
            //-Right
            ,[(cos((jointAngle * -ci) - angleOffset) * (tr - case_bezel)) + xOffset, (sin((jointAngle * -ci) - angleOffset) * (tr - case_bezel)) + ofst.y, zOffset]
            ,[(cos((jointAngle * -ci) - angleOffset) * trt) + xOffset, (sin((jointAngle * -ci) - angleOffset) * trt) + ofst.y, zOffset]
            ,[(cos((jointAngle * -ci) - angleOffset) * or) + xOffset, (sin((jointAngle * -ci) - angleOffset) * or) + ofst.y, zOffset + outerZOffset]
            ,[(cos((jointAngle * -ci) - angleOffset) * (ort + case_bezel)) + xOffset, (sin((jointAngle * -ci) - angleOffset) * (ort + case_bezel)) + ofst.y, zOffset + outerZOffset]

            //-Left
            ,[(cos((jointAngle * -(ci+1)) - angleOffset) * (tr - case_bezel)) + xOffset, (sin((jointAngle * -(ci+1)) - angleOffset) * (tr - case_bezel)) + ofst.y, zOffset]
            ,[(cos((jointAngle * -(ci+1)) - angleOffset) * trt) + xOffset, (sin((jointAngle * -(ci+1)) - angleOffset) * trt) + ofst.y, zOffset]
            ,[(cos((jointAngle * -(ci+1)) - angleOffset) * or) + xOffset, (sin((jointAngle * -(ci+1)) - angleOffset) * or) + ofst.y, zOffset + outerZOffset]
            ,[(cos((jointAngle * -(ci+1)) - angleOffset) * (ort + case_bezel)) + xOffset, (sin((jointAngle * -(ci+1)) - angleOffset) * (ort + case_bezel)) + ofst.y, zOffset + outerZOffset]
        ];
        fbp = concat_mx([
            bezelPoints,
            offsetPoints(bezelPoints, [0, 0, -mx_socket_total_D])
        ]);
        bp = xrot(-clusterRot, fbp, cp = rotAnchor);

        // Render the bits
        color(clrs[ci%len(clrs)]) {
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

            
        }

        // Bezel around the thumb cluster column
        color("yellow") {
            //- Front Bezel
            bfpr = ci == 0
                ? [bp[0],bp[16]] : [bp[8],bp[24]];
            bfpl = ci == colCount - 1
                ? [bp[20],bp[4]] : [bp[28],bp[12]];
            fbp = concat_mx([bfpr,bfpl,[sp[0],sp[8],sp[1],sp[9]]]);

            hull() polyhedron( // Front Bezel
                points = fbp,
                faces = [
                    [0,1,2,3],[4,5,6,7]
                ]
            );

            //- Back Bezel
            bbpr = ci == 0
                ? [bp[3],bp[19]] : [bp[11],bp[27]];
            bbpl = ci == colCount - 1
                ? [bp[23],bp[7]] : [bp[31],bp[15]];
            bbp = concat_mx([bbpr,bbpl,[sp[6],sp[14],sp[15],sp[7]]]);
            
            hull() polyhedron( // Back Bezel
                points = bbp,
                faces = [
                    [0,1,2,3],[4,5,6,7]
                ]
            );

            //- Right side if this is the first
            if(ci == 0) {
                hull() polyhedron( 
                    points = [
                        bp[0],bp[1],bp[17],bp[16]
                        ,sp[0],sp[2],sp[10],sp[8]
                    ],
                    faces = [
                        [0,1,2,3],[4,5,6,7]
                    ]
                );
                hull() polyhedron(
                    points = [
                        bp[1],bp[2],bp[18],bp[17]
                        ,sp[2],sp[4],sp[12],sp[10]
                    ],
                    faces = [
                        [0,1,2,3],[4,5,6,7]
                    ]
                );
                hull() polyhedron(
                    points = [
                        bp[2],bp[3],bp[19],bp[18]
                        ,sp[4],sp[6],sp[14],sp[12]
                    ],
                    faces = [
                        [0,1,2,3],[4,5,6,7]
                    ]
                );
            }

            // Left bezel if this is the last column of switches
            if(ci == colCount - 1) {
                hull() polyhedron( 
                    points = [
                        bp[5],bp[4],bp[20],bp[21]
                        ,sp[3],sp[1],sp[9],sp[11]
                    ],
                    faces = [
                        [0,1,2,3],[4,5,6,7]
                    ]
                );
                hull() polyhedron(
                    points = [
                        bp[5],bp[6],bp[22],bp[21]
                        ,sp[3],sp[5],sp[13],sp[11]
                    ],
                    faces = [
                        [0,1,2,3],[4,5,6,7]
                    ]
                );
                hull() polyhedron(
                    points = [
                        bp[6],bp[7],bp[23],bp[22]
                        ,sp[5],sp[7],sp[15],sp[13]
                    ],
                    faces = [
                        [0,1,2,3],[4,5,6,7]
                    ]
                );
            }
        }

        *if(ci == 0) plotPoints(sp,clr="red");
        *if(ci == 0) plotPoints(bp,clr="blue");
        *plotPoints(upperWeldPoints);
    }
}
