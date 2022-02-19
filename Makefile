 # Ensure we have fswatch
 ifeq (, $(shell which fswatch))
	brew install fswatch
 endif

build:
	go build -o bin/pterosphera

run: build
	./bin/pterosphera

watch:
	fswatch -0 **/*.go | xargs -0 -n 1 -I {} make run
