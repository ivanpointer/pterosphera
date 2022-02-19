package obj

import (
	"github.com/deadsy/sdfx/sdf"
	"github.com/ivanpointer/pterosphera/render"
	"math"
)

// TrackballSocket holds the dimensions of the various components of the trackball socket.
type TrackballSocket struct {
	// TrackballRadius defines the size of the trackball
	TrackballR float64

	// WallThickness defines the thickness of the main walls of the socket.
	WallThickness float64

	// SocketClearance specifies how much clearance there should be between the trackball and its socket.
	SocketClearance float64

	// TopPlateHeight specifies the height of the top plate.
	TopPlateHeight float64

	// TopPlateClearance specifies the clearance between the top plate and the trackball, at the topmost point.
	TopPlateClearance float64
}

// TrackballSocketRender holds the options for rendering the trackball socket.
type TrackballSocketRender struct {
	// RenderTrackball whether to render the trackball itself, or not.
	RenderTrackball bool

	// Settings holds the render settings for the trackball.
	Settings render.RenderSettings
}

// RenderTrackball render the trackball.
func (s TrackballSocket) RenderTrackball() (sdf.SDF3, error) {
	return sdf.Sphere3D(s.TrackballR)
}

// Render renders the trackball socket.
func (s TrackballSocket) Render(r TrackballSocketRender) (sdf.SDF3, error) {
	// Build the socket
	socket, err := s.renderSocket()
	if err != nil {
		return nil, err
	}

	// Add the top plate
	topPlate, err := s.renderTopPlate(r)
	if err != nil {
		return nil, err
	}
	socket = sdf.Union3D(socket, topPlate)

	// Add the trackball
	if r.RenderTrackball {
		tb, err := s.RenderTrackball()
		if err != nil {
			return nil, err
		}
		socket = sdf.Union3D(socket, tb)
	}

	// Return the built socket
	return socket, nil
}

//#region Socket

// renderSocket renders the socket for the trackball.
func (s TrackballSocket) renderSocket() (sdf.SDF3, error) {
	// Build the outer socket
	radius := s.socketOuterRadius()
	outer, err := sdf.Sphere3D(radius)
	if err != nil {
		return nil, err
	}

	// Build a box to use to cut off the top half of the socket
	dia := radius * 2
	x, y, z := dia, dia, radius
	b, err := sdf.Box3D(sdf.V3{X: x, Y: y, Z: z}, 0)
	if err != nil {
		return nil, err
	}
	topHalfCut := sdf.Transform3D(b, sdf.Translate3d(sdf.V3{X: 0, Y: 0, Z: radius / 2}))

	// Cut the top half of the socket off
	socket := sdf.Difference3D(outer, topHalfCut)

	// Scoop out the inside of the socket
	innerCut, err := sdf.Sphere3D(radius - s.WallThickness)
	socket = sdf.Difference3D(socket, innerCut)

	// Return the build socket
	return socket, nil
}

// renderTopPlate renders the top plate for the socket - the piece that holds the trackball into the socket.
func (s TrackballSocket) renderTopPlate(r TrackballSocketRender) (sdf.SDF3, error) {
	// The outer cylinder for the top plate
	outerRadius := s.socketOuterRadius()
	topPlate, err := sdf.Cylinder3D(s.TopPlateHeight, outerRadius, 0)
	if err != nil {
		return nil, err
	}

	// Cut out the center of the top plate
	topRadius := math.Sqrt(math.Pow(s.TrackballR, 2)-math.Pow(s.TopPlateHeight, 2)) + s.TopPlateClearance
	bottomRadius := s.TrackballR + s.SocketClearance
	coneHole, err := sdf.Cone3D(s.TopPlateHeight, bottomRadius, topRadius, 0)
	if err != nil {
		return nil, err
	}
	topPlate = sdf.Difference3D(topPlate, coneHole)

	// Shift the top plate up
	topPlate = sdf.Transform3D(topPlate, sdf.Translate3d(sdf.V3{X: 0, Y: 0, Z: (s.TopPlateHeight / 2) - r.Settings.WeldShift}))

	// Return the top plate
	return topPlate, nil
}

// socketOuterRadius calculates the outer radius for the socket, and other components (like the top plate).
func (s TrackballSocket) socketOuterRadius() float64 {
	return s.TrackballR + s.WallThickness + s.SocketClearance
}

//#endregion Socket
