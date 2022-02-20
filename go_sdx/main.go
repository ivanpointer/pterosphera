package main

import (
	"github.com/deadsy/sdfx/sdf"
	"github.com/ivanpointer/pterosphera/obj"
	"github.com/ivanpointer/pterosphera/render"
	"log"
)

const (
	// TrackballDiameter is the diameter of the trackball.
	TrackballDiameter float64 = 34
)

var (
	// pterosphera holds the parameters for generating the pterosphera models.
	pterosphera obj.PterospheraParams

	// renderSettings identifies the settings to use in rendering the STL
	renderSettings render.RenderSettings
)

func init() {
	// Set up our render settings
	renderSettings = render.RenderSettings{
		DestSTL:   "bin/stl/pterophera.stl",
		MeshCells: 300,

		Material: render.MaterialPLA,

		WeldShift: 5 / 100,
	}

	// Set up the Pterosphera parameters
	pterosphera = obj.PterospheraParams{
		TrackballSocket: obj.TrackballSocket{
			TrackballR:      TrackballDiameter / 2,
			WallThickness:   3.5,
			SocketClearance: 2,

			TopPlateHeight:    5,
			TopPlateClearance: 0.6,

			BTUCount:   3,
			BTUOffsetZ: 7.1,
			BTU: obj.BTU{
				BaseR: 12.7 / 2,
				BaseH: 6.8,

				HeadR: 14.5 / 2,
				HeadH: 1,

				BallR:  8.4 / 2,
				TotalH: 10.4,
			},

			SensorMount: obj.TrackballSensorMount{
				ScrewDist:    24,
				ScrewRTop:    3.1 / 2,
				ScrewRBottom: 2.8 / 2,
				ScrewMargin:  1.1,
				ScrewDepth:   3.7,

				BaseH: 21,
				BaseD: 1.5,

				SensorClearance: 10,
				LensHoleR:       4.5,
			},
			SensorDistFromBall: 1.6,
			SensorAngleY:       -11,
		},

		Switches: obj.MXSwitchSocket{
			SocketWH:     13.9,
			SideTabW:     5.8,
			SideTabsDist: 1,

			SocketDepth:   5,
			TopPlateDepth: 1.4,

			ClipHoleW: 5,
			ClipHoleH: 2.5,
			ClipHoleD: 1.2,
		},
	}
}

func main() {
	if err := renderSwitchSocket(); err != nil {
		log.Fatalf("error: %v", err)
	}
}

func renderSwitchSocket() error {

	m, err := pterosphera.Switches.Render(obj.MXSwitchSocketRender{
		Settings: renderSettings,
	})
	if err != nil {
		return err
	}

	c, err := sdf.Box3D(sdf.V3{100, 100, 2}, 0)
	if err != nil {
		return err
	}
	c = sdf.Transform3D(c, sdf.Translate3d(sdf.V3{Z: 1}))
	m = sdf.Union3D(m, c)

	return render.RenderSTL(m, renderSettings)
}

func renderTrackballSocket() error {
	// Render the socket
	m, err := pterosphera.TrackballSocket.Render(obj.TrackballSocketRender{
		RenderTrackball: false,

		Settings: renderSettings,
	})
	if err != nil {
		return err
	}

	// Render the model into an STL
	return render.RenderSTL(m, renderSettings)
}

func renderSensorMount() error {
	/*// Render a flat plain for center
	c, _ := sdf.Box3D(sdf.V3{X: 80, Y: 80, Z: 1}, 0)
	c = sdf.Transform3D(c, sdf.Translate3d(sdf.V3{Z: 0.7}))*/

	// Render the sensor mount
	m, err := pterosphera.TrackballSocket.SensorMount.Render(obj.TrackballSensorMountRender{
		Settings: renderSettings,
	})
	if err != nil {
		return err
	}

	// Merge the plane to the mount
	//m = sdf.Union3D(m, c)

	// Convert to STL
	return render.RenderSTL(m, renderSettings)
}

func renderBTU() error {
	// Build the BTU
	btu := obj.BTU{
		BaseR: 12.7 / 2,
		BaseH: 6.8,

		HeadR: 14.5 / 2,
		HeadH: 1,

		BallR:  8.4 / 2,
		TotalH: 10.4,
	}
	m, err := btu.Render(obj.BTURender{
		Settings: renderSettings,
	})
	if err != nil {
		return err
	}

	// Render the model into an STL
	return render.RenderSTL(m, renderSettings)
}
