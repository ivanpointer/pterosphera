package main

import (
	"github.com/ivanpointer/pterosphera/demo"
	"github.com/ivanpointer/pterosphera/stl"
	"log"
)

var (
	// renderSettings identifies the settings to use in rendering the STL
	renderSettings stl.RenderSettings
)

func init() {
	// Set up our render settings
	renderSettings = stl.RenderSettings{
		DestSTL:   "bin/stl/pterophera.stl",
		MeshCells: 150,

		Material: stl.MaterialPLA,
	}
}

func main() {
	// Run a round-cap demo
	s, err := demo.RoundCap(18, 6, 1.5)
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	// Render the STL
	if err := stl.RenderSTL(s, renderSettings); err != nil {
		log.Fatalf("error: %v", err)
	}
}
