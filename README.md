# pterosphera

## Strategy
I'm having trouble choosing between OpenSCAD and Go for this.  OpenSCAD produces "crisper" models that are a lot smaller on disk, but is a weaker language.  The particular library I've picked in golang leverages a stronger language, but produces "mushy" models that are huge.

I'm pausing on my work on the Go strategy, and revisiting how I'm generating the curve of switches to see if I can get a solution there...

## Building
`make run`

## Watching
For quick iterations on Mac, install `fswatch` (via homebrew), then:

```make watch```

This will rebuild every time a Go file changes.  Open finder in gallery mode to the STL to watch it change as you make your edits.
