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

	// BTUCount is the number of BTUs to cut holes for.
	BTUCount int

	// BTUOffsetZ sets the vertical offset for the ring of BTU holes.
	BTUOffsetZ float64

	// The BTU settings for individual BTUs.
	BTU BTU
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

	// Cut out the holes for the BTUs
	socket, err = s.cutBTUHoles(socket, r)
	if err != nil {
		return nil, err
	}

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

// cutBTUHoles cuts holes for the BTUs into the socket.
func (s TrackballSocket) cutBTUHoles(b sdf.SDF3, r TrackballSocketRender) (sdf.SDF3, error) {
	// Render the pegs for the holes for the BTUs
	const pegHeight = 20
	btuPegs, err := s.RenderBTUPegs(pegHeight, r)
	if err != nil {
		return nil, err
	}

	// Cut the holes for the BTUs in the socket
	socket := sdf.Difference3D(b, btuPegs)

	// Return the updated socket
	return socket, nil
}

// RenderBTUs renders the BTUs for the socket (instead of the holes).
func (s TrackballSocket) RenderBTUs(r TrackballSocketRender) (sdf.SDF3, error) {
	return s.rotBTUs(func() (sdf.SDF3, error) {
		return s.BTU.Render(BTURender{
			Settings: r.Settings,
		})
	}, r)
}

func (s TrackballSocket) RenderBTUPegs(h float64, r TrackballSocketRender) (sdf.SDF3, error) {
	return s.rotBTUs(func() (sdf.SDF3, error) {
		return s.BTU.RenderPeg(h, BTURender{
			Settings: r.Settings,
		})
	}, r)
}

// rotBTUs generates BTUs (or their holes), rotating around the trackball and pointing to its center.
func (s TrackballSocket) rotBTUs(genBTU func() (sdf.SDF3, error), r TrackballSocketRender) (sdf.SDF3, error) {
	// Work out the radius of our sphere at the given height (from the bottom)
	radius := radiusAtDistFromCenter(s.TrackballR, s.TrackballR-s.BTUOffsetZ)
	ms := make([]sdf.SDF3, s.BTUCount)

	// Render each BTU
	ai := float64(360) / float64(s.BTUCount)
	for i := 0; i < s.BTUCount; i++ {
		// Work out the maths for the rotations
		deg := ai * float64(i)

		// Render the BTU
		btu, err := genBTU()
		if err != nil {
			return nil, err
		}

		// Work out the elevation to point the BTUs at the center of the trackball
		centerElev := s.TrackballR - s.BTUOffsetZ
		yRad := math.Atan2(radius, centerElev)
		yDeg := radToDeg(yRad)
		yRad = degToRad(yDeg)

		// Rotational magics all around the ball
		btu = sdf.Transform3D(btu, sdf.Translate3d(sdf.V3{Z: s.BTU.TotalH / -2}))
		btu = sdf.Transform3D(btu, sdf.RotateY(yRad))
		btu = sdf.Transform3D(btu, sdf.Translate3d(sdf.V3{X: radius * -1}))
		btu = sdf.Transform3D(btu, sdf.RotateZ(degToRad(deg)))

		// Add the BTU to our collection
		ms[i] = btu
	}

	// Merge all our BTUs together
	m := sdf.Union3D(ms...)

	// Move the ring of BTUs down to cradle the trackball
	m = sdf.Transform3D(m, sdf.Translate3d(sdf.V3{Z: (s.TrackballR * -1) + s.BTUOffsetZ}))

	// Send the rendered BTUs
	return m, nil
}

func degToRad(deg float64) float64 {
	return deg * (math.Pi / 180)
}

func radToDeg(rad float64) float64 {
	return rad / (math.Pi / 180)
}

// radiusAtDistFromCenter calculates the radius of a cross-section of a sphere at the given distance from the center.
func radiusAtDistFromCenter(radius float64, distance float64) float64 {
	return math.Sqrt(math.Pow(radius, 2) - math.Pow(distance, 2))
}

// socketOuterRadius calculates the outer radius for the socket, and other components (like the top plate).
func (s TrackballSocket) socketOuterRadius() float64 {
	return s.TrackballR + s.WallThickness + s.SocketClearance
}

//#endregion Socket
