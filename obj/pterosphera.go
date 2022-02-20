package obj

// PterospheraParams carries the parameters used to control the generation of the Pterosphera models.
type PterospheraParams struct {
	// TrackballSocket holds the parameters for the trackball and its socket.
	TrackballSocket TrackballSocket

	// Switches defines the dimensions of the switch sockets.
	Switches MXSwitchSocket
}
