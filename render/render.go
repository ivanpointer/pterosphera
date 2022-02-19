package render

import (
	"github.com/deadsy/sdfx/render"
	"github.com/deadsy/sdfx/sdf"
	"os"
	"path/filepath"
)

//#region Rendering

// RenderSTL renders the given sdf.SDF3 model into a STL using the given RenderSettings.
func RenderSTL(s sdf.SDF3, rs RenderSettings) error {
	// Prepare the dest
	if err := os.MkdirAll(filepath.Dir(rs.DestSTL), os.ModePerm); err != nil {
		return err
	}

	// Render the SDF
	render.RenderSTL(sdf.ScaleUniform3D(s, rs.Shrink()), rs.MeshCells, rs.DestSTL)
	return nil
}

//#endregion Rendering

//#region Settings

// RenderSettings carries the settings for rendering the built model.
type RenderSettings struct {
	// DestSTL identifies the file that the STL is generated to.
	DestSTL string

	// MeshCells identifies the number of cells on the longest axis.
	MeshCells int

	// Material identifies the material being printed in, making adjustments to the rendered STL.
	Material Material

	// WeldShift slightly shifts object for cut holes and unions to make the STL more uniform.
	WeldShift float64
}

// Shrink returns the shrinkage for the current material.
func (s RenderSettings) Shrink() float64 {
	return s.Material.Shrinkage
}

//#endregion Settings

//#region Materials

// MaterialType identifies a render material.
type MaterialType string

const (
	// MaterialTypeGeneric identifies a generic (default) render material.
	MaterialTypeGeneric = "generic"

	// MaterialTypePLA identifies a PLA type render material.
	MaterialTypePLA = "pla"

	// MaterialTypeABS identifies an ABS type render material.
	MaterialTypeABS = "abs"
)

// Material holds the adjustments for render in a specific material.
type Material struct {
	Type      MaterialType
	Shrinkage float64
}

var (
	// MaterialGeneric holds the general (default) adjustments for render.
	MaterialGeneric = Material{
		Type:      MaterialTypeGeneric,
		Shrinkage: 1,
	}

	// MaterialPLA holds the adjustments for render with a generic PLA.
	MaterialPLA = Material{
		Type:      MaterialTypePLA,
		Shrinkage: 1.0 / 0.999, // ~0.1%
	}

	// MaterialABS holds the adjustments for render with a generic ABS.
	MaterialABS = Material{
		Type:      MaterialTypeABS,
		Shrinkage: 1.0 / 0.995, // ~0.5%
	}
)

//#endregion Materials
