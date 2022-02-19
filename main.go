package main

import (
	"github.com/deadsy/sdfx/render"
	"github.com/deadsy/sdfx/sdf"
	"github.com/ivanpointer/pterosphera/demo"
	"github.com/ivanpointer/pterosphera/stl"
	"log"
	"os"
	"path/filepath"
)

var (
	printSettings  stl.PrintSettings
	renderSettings RenderSettings
)

func init() {
	// Set up our stl settings
	printSettings = stl.PrintSettings{
		Material: stl.MaterialPLA,
	}

	// Set up our render settings
	renderSettings = RenderSettings{
		DestSTL:   "bin/stl/pterophera.stl",
		MeshCells: 150,
	}
}

func main() {
	// Run a round-cap demo
	s, err := demo.RoundCap(18, 6, 1.5)
	if err != nil {
		log.Fatalf("error: %s", err)
	}

	// Render the STL
	renderSTL(s)
}

func renderSTL(s sdf.SDF3) {
	// Prepare the dest
	if err := os.MkdirAll(filepath.Dir(renderSettings.DestSTL), os.ModePerm); err != nil {
		panic(err)
	}

	// Render the SDF
	render.RenderSTL(sdf.ScaleUniform3D(s, printSettings.Shrink()), renderSettings.MeshCells, renderSettings.DestSTL)
}

// RenderSettings carries the settings for rendering the built model.
type RenderSettings struct {
	// DestSTL identifies the file that the STL is generated to.
	DestSTL string

	// MeshCells identifies the number of cells on the longest axis.
	MeshCells int
}
