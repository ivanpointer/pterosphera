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
		},
	}
}

func main() {
	// Build the model
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
		log.Fatalf("error: %v", err)
	}

	// Render the model into an STL
	if err := render.RenderSTL(m, renderSettings); err != nil {
		log.Fatalf("error: %v", err)
	}
}

func renderTrackballSocket() (sdf.SDF3, error) {
	return pterosphera.TrackballSocket.Render(obj.TrackballSocketRender{
		RenderTrackball: false,

		Settings: renderSettings,
	})
}
