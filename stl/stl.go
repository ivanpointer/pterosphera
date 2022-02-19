package stl

//#region Settings

// PrintSettings hold settings for the stl, such as material.
type PrintSettings struct {
	// The material being printed with.
	Material Material
}

// Shrink returns the shrinkage for the current material.
func (s PrintSettings) Shrink() float64 {
	return s.Material.Shrinkage
}

//#endregion Settings

//#region Materials

// MaterialType identifies a stl material.
type MaterialType string

const (
	// MaterialTypeGeneric identifies a generic (default) stl material.
	MaterialTypeGeneric = "generic"

	// MaterialTypePLA identifies a PLA type stl material.
	MaterialTypePLA = "pla"

	// MaterialTypeABS identifies an ABS type stl material.
	MaterialTypeABS = "abs"
)

// Material holds the adjustments for stl in a specific material.
type Material struct {
	Type      MaterialType
	Shrinkage float64
}

var (
	// MaterialGeneric holds the general (default) adjustments for stl.
	MaterialGeneric = Material{
		Type:      MaterialTypeGeneric,
		Shrinkage: 1,
	}

	// MaterialPLA holds the adjustments for stl with a generic PLA.
	MaterialPLA = Material{
		Type:      MaterialTypePLA,
		Shrinkage: 1.0 / 0.999, // ~0.1%
	}

	// MaterialABS holds the adjustments for stl with a generic ABS.
	MaterialABS = Material{
		Type:      MaterialTypeABS,
		Shrinkage: 1.0 / 0.995, // ~0.5%
	}
)

//#endregion Materials
