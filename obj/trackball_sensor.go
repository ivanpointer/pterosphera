package obj

import (
	"github.com/deadsy/sdfx/sdf"
	"github.com/ivanpointer/pterosphera/render"
)

// TrackballSensorMount holds the parameters for the trackball sensor mount.
type TrackballSensorMount struct {
	// ScrewDist defines the distance between the screw holes (center).
	ScrewDist float64

	// ScrewRTop is the top radius of the screw hole.
	ScrewRTop float64

	// ScrewRBottom is the bottom radius of the screw hole.
	ScrewRBottom float64

	// ScrewMargin defines the width of the walls around the screw holes.
	ScrewMargin float64

	// ScrewDepth defines the depth of the holes for the screw holes.
	ScrewDepth float64

	// BaseH defines the height of the sensor mount base.
	BaseH float64

	// BaseD defines the depth of the sensor mount base.
	BaseD float64

	// SensorClearance defines how much area to cut away for the card being mounted to the plate.
	SensorClearance float64

	// LensHoleR is the radius of the hole for the sensor lens.
	LensHoleR float64
}

// TrackballSensorMountRender holds the render options for the trackball sensor mount.
type TrackballSensorMountRender struct {
	// Settings are the general render settings.
	Settings render.RenderSettings

	// ForCut signals that the sensor mount is being rendered as a die for cutting out of another model.
	ForCut bool
}

// Render renders the trackball sensor mount.
func (m TrackballSensorMount) Render(r TrackballSensorMountRender) (sdf.SDF3, error) {
	// Render the base of the mount
	b, err := m.renderSensorMount(r)
	if err != nil {
		return nil, err
	}

	if !r.ForCut {
		// Set up the screw holes
		sh, err := m.renderScrewHoles(r)
		if err != nil {
			return nil, err
		}

		// Set up the lens hole
		lh, err := m.renderLensHole(r)
		if err != nil {
			return nil, err
		}

		// Join the holes, and cut from the base
		h := sdf.Union3D(sh, lh)
		sm := sdf.Difference3D(b, h)

		// Send it
		return sm, nil
	} else {
		// Render the hole for the sensor lens
		sh, err := m.renderLensHole(r)
		if err != nil {
			return nil, err
		}

		// Merge the sensor hole onto the base
		b = sdf.Union3D(b, sh)

		// Send the die
		return b, nil
	}
}

func (m TrackballSensorMount) renderScrewHoles(r TrackballSensorMountRender) (sdf.SDF3, error) {
	s1, err := m.renderScrewHole(r)
	if err != nil {
		return nil, err
	}
	s1 = sdf.Transform3D(s1, sdf.Translate3d(sdf.V3{X: m.ScrewDist / -2}))

	s2, err := m.renderScrewHole(r)
	if err != nil {
		return nil, err
	}
	s2 = sdf.Transform3D(s2, sdf.Translate3d(sdf.V3{X: m.ScrewDist / 2}))

	return sdf.Union3D(s1, s2), nil
}

func (m TrackballSensorMount) renderScrewHole(r TrackballSensorMountRender) (sdf.SDF3, error) {
	return sdf.Cone3D(m.ScrewDepth+r.Settings.WeldShift, m.ScrewRBottom, m.ScrewRTop, 0)
}

func (m TrackballSensorMount) renderLensHole(r TrackballSensorMountRender) (sdf.SDF3, error) {
	// Render the hole
	height := m.BaseD * 4
	return sdf.Cylinder3D(height, m.LensHoleR, 0)
}

func (m TrackballSensorMount) renderSensorMount(r TrackballSensorMountRender) (sdf.SDF3, error) {
	// Build the base
	depth := m.BaseD
	if r.ForCut {
		depth = m.BaseD + m.SensorClearance
	}
	b, err := sdf.Box3D(sdf.V3{X: m.sensorMountWidth(r), Y: m.BaseH, Z: depth}, 0)
	if err != nil {
		return nil, err
	}

	// Move the base down to zero
	b = sdf.Transform3D(b, sdf.Translate3d(sdf.V3{Z: depth / -2}))

	// Screw walls
	sw, err := m.renderScrewWalls(r)
	if err != nil {
		return nil, err
	}

	// Join the base and the screw walls
	b = sdf.Union3D(b, sw)

	// Return the base
	return b, nil
}

func (m TrackballSensorMount) renderScrewWalls(r TrackballSensorMountRender) (sdf.SDF3, error) {
	// Render each screw wall
	w1, err := m.renderScrewWall()
	if err != nil {
		return nil, err
	}
	w1 = sdf.Transform3D(w1, sdf.Translate3d(sdf.V3{X: m.ScrewDist / -2}))

	w2, err := m.renderScrewWall()
	if err != nil {
		return nil, err
	}
	w2 = sdf.Transform3D(w2, sdf.Translate3d(sdf.V3{X: m.ScrewDist / 2}))

	// Join the two together
	return sdf.Union3D(w1, w2), nil
}

func (m TrackballSensorMount) renderScrewWall() (sdf.SDF3, error) {
	h := m.screwHoleWallHeight()
	sw, err := sdf.Cylinder3D(h, m.ScrewRTop+m.ScrewMargin, m.ScrewMargin)
	if err != nil {
		return nil, err
	}

	sw = sdf.Transform3D(sw, sdf.Translate3d(sdf.V3{Z: (h - m.BaseD) / 2}))

	return sw, nil
}

func (m TrackballSensorMount) screwHoleWallHeight() float64 {
	return m.ScrewDepth + m.ScrewMargin
}

func (m TrackballSensorMount) sensorMountWidth(r TrackballSensorMountRender) float64 {
	screwDia := (m.ScrewRTop + m.ScrewMargin) * 2
	w := m.ScrewDist + (screwDia * 2)
	if r.ForCut {
		w = w - r.Settings.WeldShift
	}
	return w
}
