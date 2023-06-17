all: dist-linux dist-windows

dist-linux:
	CGO_ENABLED=0 GOOS=linux go build -o dist/linux/gorts
	cp -r web dist/linux/web

dist-windows:
	CGO_ENABLED=0 GOOS=windows \
		go build -o dist/windows/gorts.exe -ldflags -H=windowsgui
	cp -r web dist/windows/web

# gorts.ico was produced from Haiku OS's midiplayer icon using imagemagick:
# convert -background transparent -density 300 \
#   -define 'icon:auto-resize=256,128,64,32,24,16' \
#   App_MidiPlayer.svg ~/pj/gorts/gorts.ico
gorts.syso: gorts.ico
	# needs `go install github.com/akavel/rsrc@latest`
	rsrc -ico gorts.ico -o gorts.syso

clean:
	rm -rf dist/*
