package obj

import (
	"github.com/deadsy/sdfx/sdf"
	"github.com/ivanpointer/pterosphera/render"
)

// MXSwitchSocket defines the socket for a MX switch.
type MXSwitchSocket struct {
	// SocketWH defines the width and height of the "hole" part of a MX switch socket.
	SocketWH float64

	// SideTabW defines the width of the cutouts for the tabs for opening a MX switch.
	SideTabW float64

	// SideTabsDist defines the distance from the edge that the opening tabs begin.
	SideTabsDist float64

	// SocketDepth defines the total depth of the socket - important as the leads on the bottom of the switch need to connect with the hot-swap socket.
	SocketDepth float64

	// TopPlateDepth defines the depth of the top plate for the switch.
	TopPlateDepth float64

	// ClipHoleW defines the width of the hole for the clip of the MX switch.
	ClipHoleW float64

	// ClipHoleH defines the height of the hole for the clip of the MX switch.
	ClipHoleH float64

	// ClipHoleD defines the depth of the hole for the clip of the MX switch.
	ClipHoleD float64
}

// MXSwitchSocketRender defines the render settings for a MX switch socket
type MXSwitchSocketRender struct {
	Settings render.RenderSettings
}

// Render renders the MX switch socket.
func (s MXSwitchSocket) Render(r MXSwitchSocketRender) (sdf.SDF3, error) {
	return s.renderSocketHole(r)
}

func (s MXSwitchSocket) renderSocketHole(r MXSwitchSocketRender) (sdf.SDF3, error) {
	// Render the socket hole
	socketD := s.SocketDepth - s.TopPlateDepth
	socketW := s.SocketWH + (s.SideTabsDist * 2)
	socket, err := sdf.Box3D(sdf.V3{X: s.SocketWH, Y: socketW, Z: socketD}, 0)
	if err != nil {
		return nil, err
	}

	// Render the plate hole
	plateH := s.TopPlateDepth + r.Settings.WeldShift
	plate, err := sdf.Box3D(sdf.V3{X: s.SocketWH, Y: s.SocketWH, Z: plateH}, 0)
	if err != nil {
		return nil, err
	}
	plateZ := (socketD / 2) + (s.TopPlateDepth / 2)
	plate = sdf.Transform3D(plate, sdf.Translate3d(sdf.V3{Z: plateZ}))

	// Add the cutout for the switch clips
	clipHole, err := sdf.Box3D(sdf.V3{X: s.SocketWH + s.ClipHoleD, Y: s.ClipHoleW, Z: s.ClipHoleH}, 0)
	if err != nil {
		return nil, err
	}
	clipHole = sdf.Transform3D(clipHole, sdf.Translate3d(sdf.V3{Z: (socketD / 2) - (s.ClipHoleH / 2)}))
	plate = sdf.Union3D(plate, clipHole)

	// Cut out the tab holes for opening the switch
	tabW := (s.SocketWH - (s.SideTabsDist * 2) - s.SideTabW) / 2
	tabH1, err := sdf.Box3D(sdf.V3{X: tabW, Y: socketW, Z: plateH}, 0)
	if err != nil {
		return nil, err
	}
	tabOffsetX := ((s.SocketWH / 2) - 1) - (tabW / 2)
	tabH1 = sdf.Transform3D(tabH1, sdf.Translate3d(sdf.V3{X: tabOffsetX, Z: plateZ}))
	plate = sdf.Union3D(plate, tabH1)

	tabH2, err := sdf.Box3D(sdf.V3{X: tabW, Y: socketW, Z: plateH}, 0)
	tabH2 = sdf.Transform3D(tabH2, sdf.Translate3d(sdf.V3{X: tabOffsetX * -1, Z: plateZ}))
	plate = sdf.Union3D(plate, tabH2)

	socket = sdf.Union3D(socket, plate)

	// Send it!
	return socket, nil
}