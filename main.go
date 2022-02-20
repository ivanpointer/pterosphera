package main

import (
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
		MeshCells: 150,

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
			BTUOffsetZ: 6,
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
			},
		},
	}
}

func main() {
	if err := renderSensorMount(); err != nil {
		log.Fatalf("error: %v", err)
	}
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
	// Render the sensor mount
	m, err := pterosphera.TrackballSocket.SensorMount.Render(obj.TrackballSensorMountRender{
		Settings: renderSettings,
	})
	if err != nil {
		return err
	}

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
