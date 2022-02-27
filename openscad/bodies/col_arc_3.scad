include <../switches/mx.scad>
include <../BOSL2/std.scad>
use <../lib/utils.scad>

finger_col_offset = mx_socket_total_D; // An additional offset between each finger's columns

// The margin beyond the backmost edge of the columns to build the top part of the case
case_top_margin = 3;
case_wall_thickness = 4;

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module curvedSwitchColumn(colSpec,adjacentColSpec,debug = false) {
    // Colors for debugging
    clr = ["red","blue","green","purple", "cyan", "white"];

    // Define the column
    col = newColumn(colSpec);
    switches = getColSwitches(col);
    swLen = len(switches);

    // Work out the next column, if we need to weld them together
    toWeld = getFingerPos(colSpec)[1] == 1 && len(adjacentColSpec) > 0;
    adjCol = toWeld ? newColumn(adjacentColSpec) : [];
    adjSwitches = toWeld ? getColSwitches(adjCol) : [];
    adjLen = len(adjSwitches);
    weldLen = toWeld ? swLen > adjLen ? swLen - 1 : adjLen - 1 : swLen;

    // Iterate over each switch in the column
    for(si=[0:weldLen]) {
        // Render the switch
        if(si < swLen) {
            switch = switches[si];
            color(clr[si%len(clr)])
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
            faces = [ [0,1,2,3], [4,5,6,7] ];
            color("slateGray") hull() polyhedron(
                points = concat_mx([
                    getSwitchFacePoints(switch,P_FCE_RIGHT),
                    getSwitchFacePoints(adjSwitch,P_FCE_LEFT)
                ]),
                faces = faces
            );
        }
    }
}

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

/*
  [ // dish
    [ // columns - origin is assumed as 0,0,0
        col no,
        first/last col on finger: -1 first, 0 neither, 1 last,
        first/last col on dish: -1 first, 0 neither, 1 last,
        orientation (hand): 0 left, 1 right,
        width,
        offset: [x, y, z],
        radius: [top, under],

        switches: [ // switches - left/right, front/back, top/under
          colNo
          switchNo
          switchPos: -1 first, 0 neither, 1 last
          radius [finger, top, under]
          angle [x, y, z],
          offset [x, y, z],
          points: [[l, f, t], [r, f, t], [l, b, t], [r, b, t], [l, f, u], [r, f, u], [l, b, u], [r, b, u]],
          faces: [left, right, front, back, top, under]

        ],
    ]
  ]
*/

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
/*
    switches: [ // switches - left/right, front/back, top/under
        colNo
        fingerPos
        dishPos
        dishHand
        colWidth
        colOffset
        radiuses
        angles

        switchNo
        switchPos: -1 first, 0 neither, 1 last

        angle [x, y, z],
        offset [x, y, z],
        points: [[l, f, t], [r, f, t], [l, b, t], [r, b, t], [l, f, u], [r, f, u], [l, b, u], [r, b, u]],
        faces: [left, right, front, back, top, under]
    ],
*/

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
