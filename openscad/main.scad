include <switches/mx.scad>
use <trackball/trackball_socket.scad>
include <bodies/col_arc_3.scad>
include <bodies/thumb_clusters.scad>
include <BOSL2/std.scad>
include <lib/utils.scad>

// Model definition - the higher the more faces/smooth
$fn = 360 / 20; // degrees per face

// Show/hide debug queues
debug = true;

// Which row (from the top) is considered the home row
home_row = 3;

// The right hand spec
rightHand = newHandSpec(
    P_HAND_RIGHT, [
        // X offset, radius, columns, rows, name
        newFingerSpec(49.8, 48.2, 2, 4, "Index"),
        newFingerSpec(53.2, 55.0, 1, 5, "Middle"),
        newFingerSpec(51.0, 51.5, 1, 5, "Ring"),
        newFingerSpec(38.1, 41.5, 2, 4, "Pinky")
    ]
);

function reverseVector(v) = _reverseVector(v,len(v));
function _reverseVector(v,m) = [
    for(i=[0:m-1]) v[m-i-1]
];

function newHandSpec(hand,fingers) = [ hand, fingers ];
function getHandSide(handSpec) = handSpec[0];
function getHandFingers(handSpec) = handSpec[1];

function newFingerSpec(xOffset, radius, columnCount, switchCount, name) = [ xOffset, radius, columnCount, switchCount, name ];
function getFingerXOffset(fingerSpec) = fingerSpec[0];
function getFingerRadius(fingerSpec) = fingerSpec[1];
function getFingerColCount(fingerSpec) = fingerSpec[2];
function getFingerSwitchCount(fingerSpec) = fingerSpec[3];
function getFingerName(fingerSpec) = fingerSpec[4];

fingerMargin = 1.5;
dishRot = 17; // The tilt of the dish in degrees (tenting).
thumbRot = 33; // The tilt of the thumb cluster in degrees (counter to the dish tenting);

// MAIN
module main() { 
    // Render the whole thing
    thumbClusterAlignCol = 4;
    keyboardHalf(rightHand,mx_socket_perim_W,thumbClusterAlignCol,debug);

    //trackball_socket();
} main();

// Render the given half of the keyboard
module keyboardHalf(handSpec,colWidth,thumbClusterAlignCol,debug=false) {
    // Flip the right hand fingers
    hs = getHandSide(handSpec) == P_HAND_LEFT ? handSpec : reverseHand(handSpec);

    // Work out the dish spec
    dishSpec = newDishSpec(hs, colWidth, fingerMargin, mx_socket_perim_H, home_row);
    
    // Work out the deepest point for calculating the bottom of the case
    colSpecs = getDishSpecColumns(dishSpec);
    allCols = genCols(colSpecs,dishRot);
    allPoints = concat_mx([
        for(c=allCols)
            for(s=getColSwitches(c))
                getSwitchPoints(s)
    ]);
    *plotPoints(allPoints);
    bp = boundingPair(allPoints);
    dp = bp[0];
    caseBottom = (-dp.z + mx_switch_min_clearance + case_bottom_plate_thickness) * -1;

    // Render the dish
    colCount = len(colSpecs);
    for(ci=[0:colCount-1]) {
        // frontWall = ci < thumbClusterAlignCol - 1;
        frontWall = 1 == 1;
        curvedSwitchColumn(colSpecs[ci], (ci < colCount - 1 ? colSpecs[ci+1] : []), ci, colCount, caseBottom, dishRot, frontWall, debug);
    }

    tcac = allCols[thumbClusterAlignCol];
    tcacs = getColSwitches(tcac);
    tcas = tcacs[len(tcacs)-1];
    tcasp = getSwitchPoints(tcas);
    thumbClusterAnchor = tcasp[6];
    thumbClusterZOffset = mx_switch_min_clearance + 8;

    *plotPoints(tcasp);

    // Render the thumb cluster
    thumbJointRadius = 73.8;
    thumbTipRadius = 14.3;
    * thumbCluster(
        thumbJointRadius  // thumb joint radius
        ,thumbTipRadius // thumb tip radius
        ,5   // outer Z offset
        ,thumbRot    // rotation of the thumb cluster
        ,thumbClusterAnchor // the anchor for the thumb cluster rotation
        ,1.5  // min margin between the inner and outer rows
        ,caseBottom // the bottom of the case
        ,ofst = [ //thumbClusterAnchor // [-thumbJointRadius,yOffset,caseBottom]
            0,
            thumbClusterAnchor.y + case_bezel,
            thumbClusterAnchor.z + thumbClusterZOffset
        ]
    );
}

function getAllRadiuses(dishSpec) = [
    for(c=getDishSpecColumns(dishSpec))
        getPlateUnderRadius(getColSpecRadiuses(c))
];
function deepestRadius(radiuses) = _deepestRadius(radiuses,len(radiuses));
function _deepestRadius(radiuses,n,i=0) = i < n - 1 ? radiuses[i] > _deepestRadius(radiuses,n,i+1) ? radiuses[i] : _deepestRadius(radiuses,n,i+1) : radiuses[i];

function deepestPoint(pts) = _deepestPoint(pts,len(pts));
function _deepestPoint(pts,n,i=0) = i < n - 1 ? pts[i][2] < (_deepestPoint(pts,n,i+1))[2] ? pts[i] : _deepestPoint(pts,n,i+1) : pts[i];

function genCols(colSpecs,dishRot) = [
    for(c=colSpecs) newColumn(c,dishRot)
];

function reverseHand(handSpec) = [
    getHandSide(handSpec),
    reverseVector(getHandFingers(handSpec))
];

function newDishSpec(handSpec, colWidth, fingerMargin, switchHeight, homeRow) = _newDishSpec(handSpec, getHandColCount(handSpec), colWidth, fingerMargin, switchHeight, homeRow);
function _newDishSpec(handSpec, colCount, colWidth, fingerMargin, switchHeight, homeRow) = [
    [ for(f=newDishSpecFingers(handSpec, colCount, colWidth, fingerMargin, switchHeight, homeRow)) f ]
];
function newDishSpecFingers(handSpec, colCount, colWidth, fingerMargin, switchHeight, homeRow) = [
    for(fi=[0:len(getHandFingers(handSpec))-1])
        for(c = newColSpecsForFinger(
            getHandFingers(handSpec)[fi],
            fi,
            getColNo(getHandFingers(handSpec),fi),
            colCount,
            getHandSide(handSpec),
            colWidth,
            fingerMargin,
            switchHeight,
            homeRow)) c
];
function newColSpecsForFinger(fingerSpec, fingerIndex, colStart, colCount, dishHand, colWidth, fingerMargin, switchHeight, homeRow) = [
    for(i=[0:getFingerColCount(fingerSpec)-1])
        newColSpec(
            i,
            getFingerPos(fingerSpec,i),
            getColPos(colCount,colStart + i),
            dishHand,
            colWidth,
            getColOffset(fingerSpec,colStart + i,colWidth,fingerIndex,fingerMargin),
            getFingerRadius(fingerSpec),
            getFingerSwitchCount(fingerSpec),
            switchHeight,
            homeRow
        )
];

function getDishSpecColumns(dishSpec) = dishSpec[0];

function getFingerPos(fingerSpec,fingerIndex) = [fingerIndex == 0 ? 1 : 0, fingerIndex == getFingerColCount(fingerSpec) - 1 ? 1 : 0];
function getColPos(colCount,colIndex) = [colIndex == 0 ? 1 : 0, colIndex - 1 == colCount ? 1 : 0];
function getColOffset(fingerSpec, colIndex, colWidth, fingerIndex, fingerMargin) =
    [getFingerXOffset(fingerSpec), getColYOffset(colIndex, colWidth, fingerIndex, fingerMargin), 0];
function getColYOffset(colIndex, colWidth, fingerIndex, fingerMargin) = ((colIndex * colWidth) + (fingerIndex * fingerMargin));

// Generate the arguments expected by the column arc methods, with the proper offsets
function switch_col_args(h,o) = [
    for(fi=[0:len(h)-1])
        for(c=[0:h[fi][2]-1])
    [ h[fi][3], o, h[fi][1], h[fi][0], y_offset(h,fi,c), c + 1, h[fi][2] ]
];

// Work out the proper offset for the given column
function y_offset(h,fi,c) = ((col_no(h,fi) + c) * -mx_socket_perim_W) - ((fi > 0 ? finger_col_offset : 0) * fi);

function getColNo(fingers,currentFinger,i=0) = i < currentFinger ? getFingerColCount(fingers[i]) + getColNo(fingers,currentFinger,i+1) : 0;

function getHandColCount(handSpec) = _getHandColCount(getHandFingers(handSpec));
function _getHandColCount(fingers,fingerIndex=0) = fingerIndex < len(fingers) ? getFingerColCount(fingers[fingerIndex]) + _getHandColCount(fingers,fingerIndex+1) : 0;