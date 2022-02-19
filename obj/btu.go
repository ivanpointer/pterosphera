package obj

import (
	"github.com/deadsy/sdfx/sdf"
	"github.com/ivanpointer/pterosphera/render"
)

// BTU Defines the dimensions of a single BTU (Ball Transfer Unit)
type BTU struct {
	// BaseR is the radius of the base of the BTU.
	BaseR float64

	// BaseH is the height of the base (stem) of the BTU.
	BaseH float64

	// HeadR is the radius of the head of the BTU.
	HeadR float64

	// HeadH is the height of the head of the BTU.
	HeadH float64

	// BallR is the radius of the ball within the BTU.
	BallR float64

	// TotalH is the total height of the BTU (used to calculate where to put the ball).
	TotalH float64
}

// BTURender defines the render parameters for rendering a BTU.
type BTURender struct {

	// Settings are the general render settings for this project.
	Settings render.RenderSettings
}

// Render renders a single BTU
func (b *BTU) Render(r BTURender) (sdf.SDF3, error) {
	// Render the base
	base, err := sdf.Cylinder3D(b.BaseH, b.BaseR, 0)
	if err != nil {
		return nil, err
	}

	// Render the head
	head, err := sdf.Cylinder3D(b.HeadH, b.HeadR, 0)
	if err != nil {
		return nil, err
	}
	head = sdf.Transform3D(head, sdf.Translate3d(sdf.V3{X: 0, Y: 0, Z: ((b.BaseH + b.HeadH) / 2) - r.Settings.WeldShift}))

	// Render the ball
	ball, err := sdf.Sphere3D(b.BallR)
	if err != nil {
		return nil, err
	}
	ballZ := b.TotalH - (((b.BaseH + b.HeadH) / 2) + b.BallR)
	ball = sdf.Transform3D(ball, sdf.Translate3d(sdf.V3{X: 0, Y: 0, Z: ballZ}))

	// Weld all the pieces together
	btu := sdf.Union3D(base, head)
	btu = sdf.Union3D(btu, ball)

	// Return what we built
	return btu, nil
}

// RenderPeg renders a peg version of a BTU (used for cutting holes), using a total peg height.
// Note: the peg base will always be the same length, the given height (h) determines the height of the head portion of the BTU.
func (b *BTU) RenderPeg(h float64, r BTURender) (sdf.SDF3, error) {
	// Render the base
	base, err := sdf.Cylinder3D(b.BaseH, b.BaseR+r.Settings.WeldShift, 0)
	if err != nil {
		return nil, err
	}

	// Render the head, to the length given
	headH := h - b.BaseH + r.Settings.WeldShift
	head, err := sdf.Cylinder3D(headH, b.HeadR+r.Settings.WeldShift, 0)
	if err != nil {
		return nil, err
	}
	head = sdf.Transform3D(head, sdf.Translate3d(sdf.V3{X: 0, Y: 0, Z: ((b.BaseH + headH) / 2) - r.Settings.WeldShift}))

	// Weld the head and base together
	peg := sdf.Union3D(base, head)

	// Done
	return peg, nil
}
