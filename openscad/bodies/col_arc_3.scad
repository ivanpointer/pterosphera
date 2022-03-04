include <../switches/mx.scad>
include <../BOSL2/std.scad>
use <../lib/utils.scad>

finger_col_offset = mx_socket_total_D; // An additional offset between each finger's columns

// The margin beyond the backmost edge of the columns to build the top part of the case
case_top_margin = 3;
case_wall_thickness = 4;
case_bezel = 3;
case_back_taper = [8,4]; // the x,z drop of the taper on the back.
case_bottom_plate_thickness = 3;

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module curvedSwitchColumn(colSpec,adjacentColSpec,colNo,caseBottom,debug = false) {
    // Colors for debugging
    colors = ["red","blue","green","purple", "cyan", "white"];

    // Define the column
    col = newColumn(colSpec);
    switches = getColSwitches(col);
    swLen = len(switches);

    // Work out the next column, if we need to weld them together
    toWeld = getColSpecFingerPos(colSpec)[1] == 1 && len(adjacentColSpec) > 0;
    adjCol = toWeld ? newColumn(adjacentColSpec) : [];
    adjSwitches = toWeld ? getColSwitches(adjCol) : [];
    adjLen = len(adjSwitches);
    weldLen = toWeld ? swLen > adjLen ? swLen - 1 : adjLen - 1 : swLen;

    // Iterate over each switch in the column
    union() for(si=[0:weldLen]) {
        // Colors!
        clr=colors[si%len(colors)];

        // Render the switch
        if(si < swLen) {
            switch = switches[si];
            color(clr)
                hull()
                polyhedron(
                    points = concat_mx([getSwitchFacePoints(switch,P_FCE_FRONT), getSwitchFacePoints(switch,P_FCE_BACK)]),
                    faces = [ [0,1,2,3], [4,5,6,7] ]
                );
        }

        // Weld the switch
        if(toWeld) {
            switch = switches[si < swLen ? si : swLen - 1];
            adjSwitch = adjSwitches[si < adjLen ? si : adjLen - 1];
            weldPoly = switchWeldPoly(
                getSwitchFacePoints(switch,P_FCE_RIGHT),
                getSwitchFacePoints(adjSwitch,P_FCE_LEFT));
            color(clr) hull() polyhedron(
                points = weldPoly[0],
                faces = weldPoly[1]
            );
        }
    }

    // Render the top portion of the case
    colBack(col,adjCol,caseBottom,debug);
}

module colBack(col,adjCol,caseBottom,debug) {
    union() {
        // Top Bezel
        colTopBezel(col,adjCol,debug);

        // Back Edge
        colTopEdge(col,adjCol,debug);

        // Back Wall
        colBackWall(col,adjCol,caseBottom,debug);
    }
}

// Render the top bezel of the dish
module colTopBezel(col,adjCol,debug=false) {
    // Top Bezel
    //- Points
    bzPoints = topBezelPoints(col);
    * if(getColSpecNo(colSpec) == 0) plotPoints(bzPoints);

    //- Render the bezel poly
    hull() polyhedron(
        points = bzPoints,
        faces = [
            [1,5,7,3],[4,0,2,6]
        ]
    );

    // Weld the bezels together
    if(len(adjCol) > 0) {
        // Work out the points
        adjBzPoints = topBezelPoints(adjCol);
        * plotPoints(bzPoints);
        * plotPoints(adjBzPoints,clr="cyan",offsets=[0,0,2]);
        bzWeldPoints = [
            bzPoints[1],bzPoints[3],bzPoints[5],bzPoints[7],
            adjBzPoints[0],adjBzPoints[2],adjBzPoints[4],adjBzPoints[6],
            [bzPoints[3].x, adjBzPoints[2].y, bzPoints[3].z],
            [adjBzPoints[2].x, adjBzPoints[2].y - fingerMargin, adjBzPoints[2].z],
            [adjBzPoints[6].x, adjBzPoints[6].y - fingerMargin, adjBzPoints[6].z],
        ];
        *plotPoints(bzWeldPoints);

        // Render the weld poly
        hull() polyhedron(
            points = bzWeldPoints,
            faces = [
                [0,1,2,3],[1,3,8],
                [4,5,6,7],[5,7,9,10]
            ]
        );
    }
}

// Render the top column edge
module colTopEdge(col,adjCol,debug=false) {
    bzPoints = topBezelPoints(col);
    bzEdgePoints = [ bzPoints[4],bzPoints[5],bzPoints[6],bzPoints[7] ];
    edgeFrontPoints = offsetPoints( bzEdgePoints, [case_back_taper[0], 0, -case_back_taper[1]] );
    edgePoints = concat_mx([
        bzEdgePoints,edgeFrontPoints
    ]);
    // 4,5,6,7

    * plotPoints(edgePoints);
    hull() polyhedron(
        points = edgePoints,
        faces = [
            [0,1,2,3],[4,5,6,7]
        ]
    );

    // Weld Points
    if(len(adjCol) > 0) {
        adjBzPoints = topBezelPoints(adjCol);
        adjBzEdgePoints = [ adjBzPoints[4],adjBzPoints[5],adjBzPoints[6],adjBzPoints[7] ];
        adjEdgeFrontPoints = offsetPoints( adjBzEdgePoints, [case_back_taper[0], 0, -case_back_taper[1]] );
        adjEdgePoints = concat_mx([adjBzEdgePoints,adjEdgeFrontPoints]);
        *plotPoints(adjEdgePoints,clr="blue",offsets=[0,0,1]);
        *plotPoints(edgePoints,clr="yellow",offsets=[0,0,2]);
        weldPoints = [
            edgePoints[1],adjEdgePoints[0],adjEdgePoints[2],
            [adjEdgePoints[2].x, adjEdgePoints[2].y - fingerMargin, adjEdgePoints[2].z],
            edgePoints[5], edgePoints[7],adjEdgePoints[4],adjEdgePoints[6]
        ];
        *plotPoints(weldPoints,clr="green")
        // weldPoly = switchWeldPoly([
        //     edgePoints[1], edgePoints[5], edgePoints[3], edgePoints[7]
        // ],[
        //     adjEdgePoints[0], adjEdgePoints[4], adjEdgePoints[2], adjEdgePoints[6]
        // ]);
        *plotPoints(weldPoly[0],offsets=[0,0,3]);
        hull() polyhedron(
             points = weldPoints,
             faces = [
                 [0,1,2,3],[4,5,6,7]
             ]
        );
    }

}

// Build the back wall for the case
module colBackWall(col,adjCol,caseBottom,debug=false) {
    // Work out the edge points
    bzPoints = topBezelPoints(col);
    bzEdgePoints = [ bzPoints[4],bzPoints[5],bzPoints[6],bzPoints[7] ];
    edgeFrontPoints = offsetPoints( bzEdgePoints, [case_back_taper[0], 0, -case_back_taper[1]] );
    edgePoints = concat_mx([
        bzEdgePoints,edgeFrontPoints
    ]);

    // Build the back wall points from the edge, to the case bottom
    wallPoints = [
        edgePoints[4],edgePoints[5],edgePoints[6],edgePoints[7],
        [edgePoints[4].x, edgePoints[4].y, caseBottom],
        [edgePoints[5].x, edgePoints[5].y, caseBottom],
        [edgePoints[6].x, edgePoints[6].y, caseBottom],
        [edgePoints[7].x, edgePoints[7].y, caseBottom]
    ];
    * plotPoints(wallPoints);

    // Render out the back wall
    hull() polyhedron(
        points = wallPoints,
        faces = [
            [0,1,2,3],[4,5,6,7]
        ]
    );

    // Weld the columns together
    if(len(adjCol) > 0) {
        // Work out the adjacent edge points
        adjBzPoints = topBezelPoints(adjCol);
        adjBzEdgePoints = [ adjBzPoints[4],adjBzPoints[5],adjBzPoints[6],adjBzPoints[7] ];
        adjEdgeFrontPoints = offsetPoints( adjBzEdgePoints, [case_back_taper[0], 0, -case_back_taper[1]] );
        adjEdgePoints = concat_mx([
            adjBzEdgePoints,adjEdgeFrontPoints
        ]);
        adjWallPoints = [
            adjEdgePoints[4],adjEdgePoints[5],adjEdgePoints[6],adjEdgePoints[7],
            [adjEdgePoints[4].x, adjEdgePoints[4].y, caseBottom],
            [adjEdgePoints[5].x, adjEdgePoints[5].y, caseBottom],
            [adjEdgePoints[6].x, adjEdgePoints[6].y, caseBottom],
            [adjEdgePoints[7].x, adjEdgePoints[7].y, caseBottom]
        ];
        *plotPoints(adjWallPoints,clr="red",offsets=[0,0,-50]);
        *plotPoints(wallPoints,clr="yellow",offsets=[0,0,-53]);

        weldPoints = [
            wallPoints[5],wallPoints[7],adjWallPoints[4],adjWallPoints[6],
            wallPoints[1],wallPoints[3],adjWallPoints[0],adjWallPoints[2],
            [adjWallPoints[4].x, adjWallPoints[4].y - fingerMargin, adjWallPoints[4].z],
            //[wallPoints[1].x, wallPoints[1].y + fingerMargin, wallPoints[1].z],
            //[adjWallPoints[0].x, adjWallPoints[0].y - fingerMargin, adjWallPoints[0].z],
            //[adjWallPoints[2].x, adjWallPoints[2].y - fingerMargin, adjWallPoints[2].z],
            [wallPoints[5].x, wallPoints[5].y + fingerMargin, wallPoints[5].z]
        ];

        // // Wall points for the adjacent col
        // weldPoints = [
        //     // col: 5,7, and down to bottom, and bottom + finger
        //     // adj: 4,6, and down to bottom, and top - finger
        //     adjEdgePoints[4],adjEdgePoints[6],[adjEdgePoints[4].x, adjEdgePoints[4].y, caseBottom],[adjEdgePoints[6].x, adjEdgePoints[6].y, caseBottom],
        //     edgePoints[5],edgePoints[7],[edgePoints[5].x, edgePoints[5].y, caseBottom],[edgePoints[7].x, edgePoints[7].y, caseBottom],
        //     [edgePoints[5].x, edgePoints[5].y - fingerMargin, caseBottom],[edgePoints[7].x, edgePoints[7].y - fingerMargin, caseBottom]
        // ];

        // Render the weld
        hull() polyhedron(
            points = weldPoints,
            faces = [
                [0,1,3,2], [4,5,7,6], [2,3,8], [0,1,9]
            ]
        );

        *plotPoints(weldPoints);
    }
}

function offsetPoints(points,ofst) = [
    for(p=points)
        [p.x + ofst.x, p.y + ofst.y, p.z + ofst.z]
];

function topBezelPoints(col) = _topBezelPoints(getSwitchFacePoints(getColSwitches(col)[0], P_FCE_FRONT));
function _topBezelPoints(topPoints) = concat_mx([
    topPoints,
    [
        for(p=topPoints)
            [p.x + case_bezel, p.y, p.z]
    ]
]);

function switchWeldPoly(switchPts,adjSwitchPts) = [
    concat_mx([switchPts, adjSwitchPts, [
        [switchPts[2].x, switchPts[2].y + fingerMargin, switchPts[2].z], [switchPts[3].x, switchPts[3].y + fingerMargin, switchPts[3].z],
        [adjSwitchPts[2].x, adjSwitchPts[2].y - fingerMargin, adjSwitchPts[2].z], [adjSwitchPts[3].x, adjSwitchPts[3].y - fingerMargin, adjSwitchPts[3].z]
    ]]),
    [
        [0,1,2,3], [4,5,6,7], [2,3,8,9], [6,7,10,11]
    ]
];

P_FCE_LEFT = 0;
P_FCE_RIGHT = 1;
P_FCE_FRONT = 2;
P_FCE_BACK = 3;
P_FCE_UNDER = 4;
P_FCE_TOP = 5;

function getSwitchFacePoints(switch, faceNo) = _getSwitchFacePoints(getSwitchPoints(switch), getSwitchFaces(switch)[faceNo]);
function _getSwitchFacePoints(points, face) = [ points[face[0]], points[face[1]], points[face[2]], points[face[3]] ];

P_HAND_LEFT = 0;
P_HAND_RIGHT = 1;

// newColSpec builds a new column spec vector
function newColSpec(colNo, fingerPos, dishPos, dishHand, colWidth, colOffset, fingerRadius, switchCount, switchHeight, homeRow) = [
    colNo,
    fingerPos, // is this the first or last column for the figer? [0/1 is first, 0/1 is last]
    dishPos, // is this the first or last column in the dish? [0/1 is first, 0/1 is last] 
    dishHand, // left or right - determines orientation
    colWidth, // the width of the column (assumed to be the same for each column)
    colOffset, // [x,y,z] offsets
    newSwitchRadiuses(fingerRadius),
    newColAngles(newSwitchRadiuses(fingerRadius), switchHeight, homeRow),
    switchCount,
    switchHeight,
    homeRow
];
function getColSpecNo(colSpec) = colSpec[0];
function getColSpecFingerPos(colSpec) = colSpec[1];
function getColSpecDishPos(colSpec) = colSpec[2];
function getColSpecDishHand(colSpec) = colSpec[3];
function getColSpecColWidth(colSpec) = colSpec[4];
function getColSpecColOffset(colSpec) = colSpec[5];
function getColSpecRadiuses(colSpec) = colSpec[6];
function getColSpecAngles(colSpec) = colSpec[7];
function getColSpecSwitchCount(colSpec) = colSpec[8];
function getColSpecSwitchHeight(colSpec) = colSpec[9];
function getColSpecHomeRow(colSpec) = colSpec[10];

function newColumn(colSpec) = [
    // Build the switches for the column
    colSpec,
    newColumnSwitches(colSpec)
];
function getColSpec(col) = col[0];
function getColSwitches(col) = col[1];

function newSwitchRadiuses(fingerRadius) = [
    fingerRadius,                                               // finger radius
    fingerRadius + mx_switch_full_height - mx_socket_total_D,   // plate top-face radius
    fingerRadius + mx_switch_full_height                        // plate under-face radius
];
function getFingerRadius(switchRadiuses) = switchRadiuses[0];
function getPlateTopRadius(switchRadiuses) = switchRadiuses[1];
function getPlateUnderRadius(switchRadiuses) = switchRadiuses[2];

function newColAngles(switchRadiuses, switchHeight, homeRow) = [
    asin(switchHeight / getFingerRadius(switchRadiuses)), // angle
    90 - ((homeRow - 0.5) * asin(switchHeight / getFingerRadius(switchRadiuses))) // angle offset
];
function getColAngle(colAngles) = colAngles[0];
function getColAngleOffset(colAngles) = colAngles[1];

function newColumnSwitches(colSpec) = [
    for(i=[0:getColSpecSwitchCount(colSpec)-1])
        newColumnSwitch(colSpec, i)
];

function newColumnSwitch(colSpec, switchNo) = [
    colSpec,
    switchNo,
    [ switchNo == 0 ? 1 : 0, switchNo == getColSpecSwitchCount(colSpec) - 1 ? 1 : 0 ], // Switch is first/is last

    newSwitchPoints(getColSpecAngles(colSpec), getColSpecColOffset(colSpec), getColSpecColWidth(colSpec), getColSpecRadiuses(colSpec), switchNo),
    [ // faces
        [0,2,4,6], // left
        [1,3,5,7], // right
        [0,1,4,5], // front
        [2,3,6,7], // back
        [4,5,6,7], // under
        [0,1,2,3]  // top
    ]
];
function getSwitchPoints(switch) = switch[3];
function getSwitchFaces(switch) = switch[4];

// newSwitchPoints creates a new vector of points for a single switch
function newSwitchPoints(angles, offsets, width, radiuses, switchNo) = [
    // x = left/right, y = front/back, z = top/under
    circPoint(angles, offsets.x, _offsetsLeftY(offsets, width), offsets.z, getPlateTopRadius(radiuses), switchNo), // left, front, top
    circPoint(angles, offsets.x, _offsetsRightY(offsets, width), offsets.z, getPlateTopRadius(radiuses), switchNo), // right, front, top
    circPoint(angles, offsets.x, _offsetsLeftY(offsets, width), offsets.z, getPlateTopRadius(radiuses), switchNo + 1), // left, back, top
    circPoint(angles, offsets.x, _offsetsRightY(offsets, width), offsets.z, getPlateTopRadius(radiuses), switchNo + 1), // right, back, top

    circPoint(angles, offsets.x, _offsetsLeftY(offsets, width), offsets.z, getPlateUnderRadius(radiuses), switchNo), // left, front, under
    circPoint(angles, offsets.x, _offsetsRightY(offsets, width), offsets.z, getPlateUnderRadius(radiuses), switchNo), // right, front, under
    circPoint(angles, offsets.x, _offsetsLeftY(offsets, width), offsets.z, getPlateUnderRadius(radiuses), switchNo + 1), // left, back, under
    circPoint(angles, offsets.x, _offsetsRightY(offsets, width), offsets.z, getPlateUnderRadius(radiuses), switchNo + 1) // right, back, under
];
function _offsetsLeftY(offsets, width) = offsets.y;
function _offsetsRightY(offsets, width) = offsets.y + width;

function circPoint(angles, xOffset, y, zOffset, radius, edgeNo) = [
    circPointX(getColAngle(angles), getColAngleOffset(angles), radius, xOffset, edgeNo),
    y,
    circPointZ(getColAngle(angles), getColAngleOffset(angles), radius, zOffset, edgeNo)
];

function circPointX(angle, angleOffset, radius, xOffset, edgeNo) =
    (cos((angle * -edgeNo) - angleOffset) * radius) + xOffset;
function circPointZ(angle, angleOffset, radius, zOffset, edgeNo) =
    (sin((angle * -edgeNo) - angleOffset) * radius) + zOffset;
